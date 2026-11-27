# 컷신 시안 5개(cutN/proj)를 게임 game/art/intro/cutN 으로 옮긴다.
# 경로를 res://art/intro/cutN/ 아래로 바꾸고, wav는 ogg로 줄이며, 창 종료 대신 done 표시를 세운다.
import os, re, shutil, subprocess, pathlib
here = pathlib.Path(__file__).resolve().parent
game = here.parents[2] / 'game'
for n in range(1, 6):
    src = here / f'cut{n}' / 'proj'; dst = game / 'art' / 'intro' / f'cut{n}'
    if dst.exists(): shutil.rmtree(dst)
    (dst / 'img').mkdir(parents=True); (dst / 'snd').mkdir()
    for f in (src / 'img').iterdir():
        if f.suffix in ('.png', '.json'): shutil.copy(f, dst / 'img' / f.name)
    for f in (src / 'snd').iterdir():
        if f.suffix == '.ogg': shutil.copy(f, dst / 'snd' / f.name)
        elif f.suffix == '.wav':
            subprocess.run(['ffmpeg', '-y', '-v', 'error', '-i', str(f), '-c:a', 'libvorbis', '-q:a', '4', str(dst / 'snd' / (f.stem + '.ogg'))], check=True)
    for f in src.glob('*.gdshader'): shutil.copy(f, dst / f.name)
    code = (src / 'main.gd').read_text()
    pre = f'res://art/intro/cut{n}/'
    code = code.replace('res://img/', pre + 'img/').replace('res://snd/', pre + 'snd/')
    code = re.sub(r'res://([A-Za-z0-9_]+\.gdshader)', lambda m: pre + m.group(1), code)
    code = code.replace('.wav"', '.ogg"')
    code = code.replace('\tProjectSettings.load_resource_pack("/tmp/cand161/full.pck")\n', '')
    code = code.replace('\tRenderingServer.set_default_clear_color(Color.BLACK)\n', '')
    code = code.replace('get_tree().quit()', 'done = true')
    code = code.replace('if not path.ends_with(".ogg"): p.finished.connect(p.queue_free)', 'p.finished.connect(p.queue_free)')
    code = re.sub(r'^extends Node2D\n', 'extends Node2D\n# 게임용 사본: docs/design/intro-cutscene/install_into_game.py 가 만든다. 직접 고치지 말고 시안을 고친 뒤 다시 돌린다.\nvar done := false\n', code, count=1)
    assert 'get_tree().quit' not in code and 'res://img/' not in code and 'res://snd/' not in code
    (dst / 'main.gd').write_text(code)
    print(n, sum(1 for _ in dst.rglob('*')), 'files')
