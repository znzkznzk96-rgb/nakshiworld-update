"""Restore a pinned full-source archive, apply deletions, then overlay tracked game files."""
import json, pathlib, shutil, sys, zipfile
archive, output = map(pathlib.Path, sys.argv[1:])
repo = pathlib.Path(__file__).resolve().parents[1]
assert not output.exists(), "Restore destination must be new"
output.mkdir(parents=True)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    for member in z.infolist():
        rel = pathlib.PurePosixPath(member.filename)
        assert not rel.is_absolute() and ".." not in rel.parts
        assert rel.parts[0] == "game", member.filename
        if member.is_dir(): continue
        target = output.joinpath(*rel.parts[1:])
        target.parent.mkdir(parents=True, exist_ok=True)
        with z.open(member) as source, target.open("wb") as dest:
            shutil.copyfileobj(source, dest)
for name in json.loads((repo/"automation/deleted-game-files.json").read_text()):
    rel = pathlib.PurePosixPath(name)
    assert not rel.is_absolute() and rel.parts and ".." not in rel.parts
    target = output.joinpath(*rel.parts)
    assert target != output
    if target.is_dir(): shutil.rmtree(target)
    elif target.exists(): target.unlink()
for source in (repo/"game").rglob("*"):
    rel = source.relative_to(repo/"game")
    if source.is_file() and ".godot" not in rel.parts:
        target = output/rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
assert (output/"project.godot").is_file() and (output/"root.tscn").is_file()
import subprocess
subprocess.run([sys.executable,str(repo/"automation/prepare_expedition_assets.py"),str(output)],check=True)
print("FULL SOURCE RESTORE VERIFIED")
