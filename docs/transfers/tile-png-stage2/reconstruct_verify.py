"""Reconstruct only the approved PNG on an isolated work branch; never publish."""
import base64, hashlib, io, json, os, pathlib, subprocess, urllib.request
from PIL import Image

REPO = "znzkznzk96-rgb/nakshiworld-update"
BRANCH = "work/tile-png-stage2-20261107"
ROOT = pathlib.Path("docs/transfers/tile-png-stage2")
TARGET = pathlib.Path("game/art/bg/tile_sea_approved_20261107.png")
EXPECTED = "1c2ce9d432cf1aa38ed462d2570291fe63c316f50aecc851f0a5a532d84d1f4b"
assert os.environ["GITHUB_REF"] == "refs/heads/" + BRANCH
def git(*args):
    return subprocess.check_output(["git", *args], text=True).strip()
def validate(data):
    assert len(data) == 1716343, "PNG byte count mismatch"
    assert hashlib.sha256(data).hexdigest() == EXPECTED, "PNG SHA256 mismatch"
    with Image.open(io.BytesIO(data)) as im:
        assert im.size == (801, 1962), "PNG dimensions mismatch"
        im.verify()
    with Image.open(io.BytesIO(data)) as im:
        im.load()
    return {"bytes": len(data), "size": [801,1962], "sha256": EXPECTED, "decode_ok": True}
manifest = json.loads((ROOT / "manifest.json").read_text())
assert len(manifest["parts"]) == 39
encoded = []
for item in manifest["parts"]:
    part = (ROOT / item["path"]).read_bytes()
    assert len(part) == item["characters"]
    assert hashlib.sha256(part).hexdigest() == item["sha256"]
    encoded.append(part)
data = base64.b64decode(b"".join(encoded), validate=True)
checked = validate(data)
assert not TARGET.exists(), "New approved target must not already exist"
TARGET.parent.mkdir(parents=True, exist_ok=True)
TARGET.write_bytes(data)
git("config", "user.name", "github-actions[bot]")
git("config", "user.email", "41898282+github-actions[bot]@users.noreply.github.com")
git("add", str(TARGET))
git("commit", "-m", "chore: preserve verified approved tile PNG on staging branch [skip ci]")
asset_commit = git("rev-parse", "HEAD")
git("push", "origin", "HEAD:refs/heads/" + BRANCH)
token = os.environ["GH_TOKEN"]
def api(path):
    request = urllib.request.Request("https://api.github.com/repos/" + REPO + path,
        headers={"Authorization": "Bearer " + token, "Accept": "application/vnd.github+json"})
    with urllib.request.urlopen(request, timeout=45) as response:
        return json.load(response)
tree = api("/git/trees/" + asset_commit + "?recursive=1")
entry = next(x for x in tree["tree"] if x["path"] == str(TARGET))
blob = api("/git/blobs/" + entry["sha"])
downloaded = base64.b64decode(blob["content"])
remote_checked = validate(downloaded)
assert downloaded == data, "Remote re-download differs"
report = {"stage": "approved PNG transfer only", "source_commit": os.environ["GITHUB_SHA"],
    "asset_commit": asset_commit, "path": str(TARGET), "parts": 39,
    "reconstructed": checked, "remote_redownload": remote_checked,
    "remote_blob_sha": entry["sha"], "byte_identical": True, "deployed": False,
    "screen_applied": False, "full_game_tests_run": False}
(ROOT / "VERIFICATION.json").write_text(json.dumps(report, indent=2) + "\n")
(ROOT / "STATUS.json").write_text(json.dumps({"uploaded":39,"total":39,
    "png_reconstructed":True,"remote_verified":True,"deployed":False}, indent=2) + "\n")
git("add", str(ROOT / "VERIFICATION.json"), str(ROOT / "STATUS.json"))
git("commit", "-m", "docs: record approved PNG remote re-download verification [skip ci]")
git("push", "origin", "HEAD:refs/heads/" + BRANCH)
print("APPROVED_PNG_REMOTE_VERIFIED " + json.dumps(report))
