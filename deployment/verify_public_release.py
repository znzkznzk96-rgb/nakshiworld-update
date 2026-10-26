"""Verify all published assets against their manifest and this checked-out source."""
import hashlib, io, json, os, pathlib, urllib.request, zipfile
REPO = 'znzkznzk96-rgb/nakshiworld-update'
expected = json.loads(pathlib.Path('automation/release.json').read_text())
def get(url):
    req = urllib.request.Request(url, headers={'User-Agent':'nakshiworld-release-verification','Cache-Control':'no-cache'})
    with urllib.request.urlopen(req, timeout=120) as response:
        assert response.status == 200
        return response.read()
release = json.loads(get(f'https://api.github.com/repos/{REPO}/releases/tags/v{expected["name"]}'))
assets = {item['name']:item for item in release['assets']}
# Verify against the immutable release tag, not a later documentation/infra commit.
tag_commit = get(f'https://api.github.com/repos/{REPO}/commits/v{expected["name"]}')
source_commit = json.loads(tag_commit)['sha']
report = {'version':expected, 'source_commit':source_commit, 'assets':{}, 'phone_verified':False}
files = {}
for name in ['version.json','patch.pck','game-source.zip']:
    item = assets[name]
    data = get(item['browser_download_url'])
    digest = hashlib.sha256(data).hexdigest()
    assert len(data) == item['size'] and len(data) > 0, name
    assert item.get('digest') == 'sha256:'+digest, name
    report['assets'][name] = {'size':len(data),'sha256':digest,'url':item['browser_download_url']}
    files[name] = data
manifest = json.loads(files['version.json'])
assert manifest['name'] == expected['name'] and manifest['code'] == expected['code']
assert manifest['source_commit'] == source_commit
assert manifest['size'] == len(files['patch.pck'])
assert manifest['sha256'] == report['assets']['patch.pck']['sha256']
assert files['patch.pck'][:4] == b'GDPC'
checked = 0
with zipfile.ZipFile(io.BytesIO(files['game-source.zip'])) as archive:
    assert archive.testzip() is None
    for path in pathlib.Path('game').rglob('*'):
        if path.is_file() and '.godot' not in path.parts and path.suffix != '.log':
            assert archive.read(path.as_posix()) == path.read_bytes(), str(path)
            checked += 1
    assert archive.read('game/project.godot') and archive.read('game/root.tscn')
report['source_overlay_files_verified'] = checked
report['zip_crc_verified'] = True
report['public_assets_verified'] = True
pathlib.Path('PUBLIC_VERIFICATION.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print('PUBLIC_RELEASE_ASSETS_VERIFIED '+json.dumps(report,ensure_ascii=False),flush=True)
