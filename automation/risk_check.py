"""두 커밋 사이에 전체 검증이 필요한 파일이 바뀌었는지 판정한다."""
import pathlib, subprocess, sys
ROOT = pathlib.Path(__file__).resolve().parents[1]
RISKY_FILES = [
    'game/root.gd', 'game/project.godot', 'game/export_presets.cfg',
    'game/addons/reservoir/save_store.gd', 'game/addons/reservoir/commerce.gd',
    'game/addons/reservoir/buyback.gd', 'game/addons/reservoir/facility_growth.gd',
    'game/addons/reservoir/record_gallery.gd', 'game/addons/reservoir/spot_unlock.gd',
    'automation/delta_pack.py', 'automation/release_candidate.py', 'automation/restore_source.py',
    'automation/prepare_release.py', 'automation/risk_check.py',
]
RISKY_PREFIXES = ['.github/workflows/', 'game/addons/reservoir/pet_hut/slot_', 'game/tests/updater', 'game/tests/save']
# 이 파일들은 저장/구매/결제 코드가 섞여 있어서, 그 줄이 바뀐 경우에만 위험으로 본다.
MIXED_FILES = ['game/main.gd', 'game/village.gd']
MIXED_PATTERN = r'user://|FileAccess|save_|_save|load_game|purchase|billing|결제'

def _git(*a):
    return subprocess.check_output(['git', *a], cwd=ROOT, stderr=subprocess.DEVNULL).decode()

def reasons(base, head):
    out = []
    for f in _git('diff', '--name-only', base, head).split():
        if f in RISKY_FILES or any(f.startswith(p) for p in RISKY_PREFIXES):
            out.append(f)
    for f in MIXED_FILES:
        if _git('diff', '-G' + MIXED_PATTERN, '--name-only', base, head, '--', f).strip():
            out.append(f + ' (저장/구매 관련 줄 변경)')
    return out

if __name__ == '__main__':
    r = reasons(sys.argv[1], sys.argv[2])
    print('\n'.join(r) if r else 'none')
    sys.exit(1 if r else 0)
