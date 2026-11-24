"""문제가 생긴 공개본을 예전 버전의 patch.pck 그대로(바이트 동일) 새 높은 버전으로 다시 공개한다.
폰은 서버 버전 번호가 자기보다 높을 때만 받으므로, 되돌릴 때도 번호는 올린다."""
import hashlib, json, os, pathlib, subprocess, sys

def digest(path):
    return hashlib.sha256(pathlib.Path(path).read_bytes()).hexdigest()

def plan(old, latest):
    """old: 되돌아갈 버전의 version.json, latest: 현재 공개 중인 version.json -> 새 version.json"""
    assert old.get('delta') is True, '달라진 파일만 담은 형식(1.51 이후)으로 만든 버전으로만 되돌릴 수 있다. 옛 전체 pck는 새 앱의 업데이터를 덮어쓴다'
    assert old['sha256'] != latest['sha256'], '지금 공개 중인 버전과 내용이 이미 같다'
    new = dict(old)
    new['code'] = latest['code'] + 1
    new['name'] = '1.%02d' % (new['code'] - 100) if 100 < new['code'] < 200 else str(new['code'])
    new['rollback_of'] = old['name']
    return new

def run(cmd, **kw):
    return subprocess.run(cmd, check=True, **kw)

def main(target):
    repo = os.environ['GITHUB_REPOSITORY']
    work = pathlib.Path('rollback'); work.mkdir(exist_ok=True)
    old_dir, latest_dir = work / 'old', work / 'latest'
    run(['gh', 'release', 'download', 'v' + target, '-R', repo, '-D', str(old_dir), '--clobber'])
    run(['gh', 'release', 'download', '-R', repo, '-D', str(latest_dir), '-p', 'version.json', '--clobber'])
    old = json.loads((old_dir / 'version.json').read_text())
    latest = json.loads((latest_dir / 'version.json').read_text())
    assert digest(old_dir / 'patch.pck') == old['sha256'] and (old_dir / 'patch.pck').stat().st_size == old['size'], '보관된 patch.pck가 손상됨'
    new = plan(old, latest)
    out = work / 'out'; out.mkdir(exist_ok=True)
    (out / 'patch.pck').write_bytes((old_dir / 'patch.pck').read_bytes())
    (out / 'version.json').write_text(json.dumps(new, ensure_ascii=False, indent=1))
    if (old_dir / 'game-source.zip').exists():
        (out / 'game-source.zip').write_bytes((old_dir / 'game-source.zip').read_bytes())
    assert digest(out / 'patch.pck') == old['sha256']
    tag = 'v' + new['name']
    notes = out / 'notes.md'
    notes.write_text('- v%s 상태로 되돌림 (patch.pck 바이트 동일, sha256 %s)\n' % (target, old['sha256'][:12]))
    run(['gh', 'release', 'create', tag, '--target', old.get('source_commit', 'main'), '--draft', '--title', '낚시월드 %s (v%s로 되돌림)' % (tag, target), '--notes-file', str(notes)])
    run(['gh', 'release', 'upload', tag, *[str(p) for p in sorted(out.iterdir()) if p.name != 'notes.md'], '-R', repo, '--clobber'])
    rows = json.loads(subprocess.check_output(['gh', 'api', 'repos/%s/releases?per_page=100' % repo]))
    rel = next(r for r in rows if r['tag_name'] == tag)
    for a in rel['assets']:
        if a['name'] == 'patch.pck':
            assert a['digest'] == 'sha256:' + old['sha256'], '올라간 파일이 원본과 다름'
    run(['gh', 'api', '--method', 'PATCH', 'repos/%s/releases/%d' % (repo, rel['id']), '--input', '-'], input=json.dumps({'draft': False, 'make_latest': 'true'}).encode(), stdout=subprocess.DEVNULL)
    print('ROLLBACK_DONE', tag, 'from', target)

if __name__ == '__main__':
    main(sys.argv[1])
