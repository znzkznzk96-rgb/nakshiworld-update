"""APK에 든 파일과 달라진 파일만 모은 업데이트 압축 파일(patch.pck)을 만든다.
APK에는 게임 파일이 낱개로 들어 있으므로, 폰은 이 파일을 그 위에 덮어 쓴다(Godot load_resource_pack replace_files=true).
기준(APK에 든 파일 목록과 md5)은 automation/apk_base.json 에 두고, APK를 새로 만들 때만 갱신한다."""
import hashlib, json, pathlib, struct

# 켜기 화면(root.gd)은 APK에서 먼저 실행되므로 업데이트로 바꿀 수 없다. 넣어 봐야 쓰이지 않는다.
SKIP = {'res://root.gd', 'res://root.gd.remap'}

def read_pck(raw):
    """GDPC v2 -> {경로: bytes}. md5가 맞지 않으면 실패한다."""
    assert raw[:4] == b'GDPC' and struct.unpack_from('<I', raw, 4)[0] == 2 and struct.unpack_from('<I', raw, 20)[0] == 0
    base = struct.unpack_from('<Q', raw, 24)[0]; n = struct.unpack_from('<I', raw, 96)[0]; q = 100; files = {}
    for _ in range(n):
        l = struct.unpack_from('<I', raw, q)[0]; q += 4
        name = raw[q:q+l].rstrip(b'\0').decode(); q += l
        off, size = struct.unpack_from('<QQ', raw, q); q += 16
        md = raw[q:q+16]; q += 16
        assert struct.unpack_from('<I', raw, q)[0] == 0; q += 4
        data = raw[base+off:base+off+size]
        assert len(data) == size and hashlib.md5(data).digest() == md, name
        files[name] = data
    return files

def write_pck(files):
    """repack_apk.py와 같은 GDPC v2(Godot 4.4.1) 형식으로 쓴다."""
    entries = []; offset = 0
    for name, data in sorted(files.items()):
        nb = name.encode() + b'\0'; nb += b'\0' * ((-len(nb)) % 4)
        entries.append(struct.pack('<I', len(nb)) + nb + struct.pack('<QQ', offset, len(data)) + hashlib.md5(data).digest() + struct.pack('<I', 0))
        offset += len(data); offset += (16 - offset % 16) % 16
    index = b''.join(entries); filebase = (100 + len(index) + 15) // 16 * 16
    out = bytearray(struct.pack('<6IQ', 0x43504447, 2, 4, 4, 1, 0, filebase) + bytes(64) + struct.pack('<I', len(files)) + index)
    out += bytes(filebase - len(out))
    for _, data in sorted(files.items()):
        out += data; out += bytes((-len(out)) % 16)
    return bytes(out)

def manifest_of(files):
    return {n: hashlib.md5(d).hexdigest() for n, d in sorted(files.items()) if n not in SKIP}

def build_delta(full_raw, base):
    """base = apk_base.json 내용. APK와 다른(또는 APK에 없는) 파일만 담은 pck 바이트를 돌려준다."""
    files = read_pck(full_raw); have = base['files']
    changed = {n: d for n, d in files.items() if n not in SKIP and have.get(n) != hashlib.md5(d).hexdigest()}
    return write_pck(changed), sorted(changed)

def save_base(path, code, full_raw):
    path = pathlib.Path(path)
    path.write_text(json.dumps({'code': code, 'files': manifest_of(read_pck(full_raw))}, indent=0, sort_keys=True) + '\n')
