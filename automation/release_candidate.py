"""Build once after verification; publish exactly those bytes after approval."""
import argparse, hashlib, json, os, pathlib, subprocess, time, zipfile
ROOT = pathlib.Path(__file__).resolve().parents[1]
RIFT_SELECTION = 'docs/art/rift-fish/APPROVED_MOTION_20_20261111.json'
INPUTS = ['game', 'automation', '.github/workflows/verify-work.yml', '.github/workflows/release-patch.yml', RIFT_SELECTION, 'docs/art/rift-background-20261111/approved-clean-data']
# These approved archives are build inputs even though their audit trail lives in docs.
INPUTS += sorted({s['motion_source'] for s in json.loads((ROOT/RIFT_SELECTION).read_text())['species']})
TOOLS = {'godot':'4.4.1.stable', 'baseline':'v1.27', 'baseline_sha256':'2074023011ad400eae78ff3f3d94146b42c0ea4be96b3cb8ca86c06d69004377'}
def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT).decode().strip()
def fingerprint():
    subprocess.run(['git','diff','--quiet','HEAD','--',*INPUTS],cwd=ROOT,check=True)
    entries = subprocess.check_output(['git','ls-tree','-r','-z','HEAD','--',*INPUTS],cwd=ROOT)
    return hashlib.sha256(entries+json.dumps(TOOLS,sort_keys=True).encode()).hexdigest()
def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def save(path, value): path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n')
def metadata(out, source):
    names=['patch.pck','game-source.zip','version.json']
    return {'schema':1,'source_commit':source,'input_fingerprint':fingerprint(),'tools':TOOLS,'run_id':int(os.environ.get('GITHUB_RUN_ID','0')),'files':{n:{'size':(out/n).stat().st_size,'sha256':digest(out/n)} for n in names}}
def seal(project, out):
    start=time.monotonic();out.mkdir(parents=True,exist_ok=True)
    version=json.loads((ROOT/'automation/release.json').read_text());source=git('rev-parse','HEAD')
    patch=out/'patch.pck';assert patch.read_bytes()[:4]==b'GDPC' and patch.stat().st_size>1000000
    manifest=dict(version,source_commit=source,size=patch.stat().st_size,sha256=digest(patch));save(out/'version.json',manifest)
    with zipfile.ZipFile(out/'game-source.zip','w',zipfile.ZIP_DEFLATED) as z:
        for p in sorted(project.rglob('*')):
            rel=p.relative_to(project)
            if p.is_file() and '.godot' not in rel.parts and p.suffix!='.log':
                assert 'keystore' not in p.name.lower();z.write(p,pathlib.Path('game')/rel)
    with zipfile.ZipFile(out/'game-source.zip') as z:
        assert z.testzip() is None
        for p in (ROOT/'game').rglob('*'):
            if p.is_file() and '.godot' not in p.parts and p.suffix!='.log': assert z.read(p.relative_to(ROOT).as_posix())==p.read_bytes(),str(p)
    report=metadata(out,source);report['version']=version;report['seal_seconds']=round(time.monotonic()-start,3);report['verification_and_restore_seconds']=round(time.time()-float(os.environ.get('VERIFICATION_STARTED',time.time())),3);save(out/'candidate.json',report)
def validate(out, run=None):
    c=json.loads((out/'candidate.json').read_text());assert c['schema']==1
    assert c['input_fingerprint']==fingerprint(),'Source/settings/tools changed: prepare a new verified candidate'
    assert c['tools']==TOOLS
    expected=json.loads((ROOT/'automation/release.json').read_text());assert c['version']==expected
    if run is not None:
        assert run['status']=='completed' and run['conclusion']=='success'
        assert run['event']=='push' and run['head_branch'].startswith('work/')
        assert run['head_sha']==c['source_commit'] and run['id']==c['run_id']
        assert run['path']=='.github/workflows/verify-work.yml'
        assert run['repository']['full_name']==os.environ['GITHUB_REPOSITORY']
    for name, m in c['files'].items():
        assert name in ['patch.pck','game-source.zip','version.json']
        assert (out/name).stat().st_size==m['size'] and digest(out/name)==m['sha256'],name
    assert set(c['files'])=={'patch.pck','game-source.zip','version.json'}
    v=json.loads((out/'version.json').read_text());assert v['source_commit']==c['source_commit']
    assert v['code']==expected['code'] and v['name']==expected['name']
    assert v['sha256']==c['files']['patch.pck']['sha256'] and v['size']==c['files']['patch.pck']['size']
    assert (out/'patch.pck').read_bytes()[:4]==b'GDPC'
    with zipfile.ZipFile(out/'game-source.zip') as z: assert z.testzip() is None
    return c
def publish(out):
    start=time.monotonic();repo=os.environ['GITHUB_REPOSITORY']
    rows=json.loads(subprocess.check_output(['gh','api',f'repos/{repo}/actions/workflows/verify-work.yml/runs?status=success&per_page=20']))['workflow_runs']
    found=None;artifact_name='release-candidate-'+fingerprint()
    for run in rows:
        if run['event']!='push' or not run['head_branch'].startswith('work/'): continue
        artifacts=json.loads(subprocess.check_output(['gh','api',f"repos/{repo}/actions/runs/{run['id']}/artifacts"]))['artifacts']
        if not any(a['name']==artifact_name and not a['expired'] for a in artifacts): continue
        temp=out/str(run['id']);temp.mkdir(parents=True,exist_ok=True)
        d=subprocess.run(['gh','run','download',str(run['id']),'--name',artifact_name,'--dir',str(temp)],capture_output=True,text=True,timeout=120)
        if d.returncode: continue
        try: c=validate(temp,run)
        except (AssertionError,KeyError,ValueError,FileNotFoundError,zipfile.BadZipFile): continue
        found=(temp,c);break
    assert found,'No successful candidate with exact source/settings/tool fingerprint; verification/build must finish first'
    temp,c=found;tag='v'+c['version']['name']
    # Draft tag endpoints can return404. Resolve the existing release by ID.
    matches=[r for r in json.loads(subprocess.check_output(['gh','api',f'repos/{repo}/releases?per_page=100'])) if r['tag_name']==tag]
    assert len(matches)<=1,'Ambiguous release tag'
    notes=json.loads((ROOT/'automation/release-history.json').read_text())[0];assert notes['id']==c['version']['name']
    notes_path=out/'release-notes.md';notes_path.write_text('\n'.join('- '+s for s in notes['body'])+'\n')
    if matches:
        public=matches[0]
        assert public['target_commitish']==c['source_commit'],'Unrelated release source: inspect before continuing'
        if not public['draft']:
            for name,m in c['files'].items():
                asset=next(a for a in public['assets'] if a['name']==name)
                assert asset['size']==m['size'] and asset['digest']=='sha256:'+m['sha256']
            save(out/'PUBLISH_RESULT.json',{'tag':tag,'candidate_run':c['run_id'],'source_commit':c['source_commit'],'already_published':True,'rebuild':False});return
    else:
        subprocess.run(['gh','release','create',tag,'--target',c['source_commit'],'--draft','--title','낚시월드 '+tag,'--notes-file',str(notes_path)],check=True,timeout=60)
        matches=[r for r in json.loads(subprocess.check_output(['gh','api',f'repos/{repo}/releases?per_page=100'])) if r['tag_name']==tag]
        assert len(matches)==1,'Created draft not found'
        public=matches[0]
        assert public['draft'] and public['target_commitish']==c['source_commit'],'Unexpected created release'
    release_id=public['id']
    subprocess.run(['gh','release','upload',tag,*[str(temp/n) for n in c['files']],'--clobber'],check=True,timeout=180)
    # A failed upload leaves a draft. Repeating publish resumes upload without rebuilding.
    assets=json.loads(subprocess.check_output(['gh','api',f'repos/{repo}/releases/{release_id}']))['assets']
    for name,m in c['files'].items():
        a=next(a for a in assets if a['name']==name);assert a['size']==m['size'] and a['digest']=='sha256:'+m['sha256']
    subprocess.run(['gh','api','--method','PATCH',f'repos/{repo}/releases/{release_id}','--input','-'],input=json.dumps({'draft':False,'make_latest':'true'}).encode(),check=True,timeout=60,stdout=subprocess.DEVNULL)
    published=json.loads(subprocess.check_output(['gh','api',f'repos/{repo}/releases/{release_id}']))
    assert not published['draft'] and published['tag_name']==tag
    save(out/'PUBLISH_RESULT.json',{'tag':tag,'candidate_run':c['run_id'],'source_commit':c['source_commit'],'publish_seconds':round(time.monotonic()-start,3),'rebuild':False})
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['seal','publish']);p.add_argument('--project',type=pathlib.Path);p.add_argument('--out',type=pathlib.Path,required=True);a=p.parse_args()
    if a.action=='seal': seal(a.project,a.out)
    else: a.out.mkdir(parents=True,exist_ok=True);publish(a.out)
