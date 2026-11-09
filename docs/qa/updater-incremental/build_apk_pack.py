from pathlib import Path
import struct,hashlib,json
src=Path('candidate118/patch.pck').read_bytes();base=struct.unpack_from('<Q',src,24)[0];p=100;files={}
for _ in range(struct.unpack_from('<I',src,96)[0]):
 l=struct.unpack_from('<I',src,p)[0];p+=4;n=src[p:p+l].rstrip(b'\0').decode().removeprefix('res://');p+=l;o,s=struct.unpack_from('<QQ',src,p);p+=16;md=src[p:p+16];p+=16;flag=struct.unpack_from('<I',src,p)[0];p+=4;assert flag==0;data=src[base+o:base+o+s];assert hashlib.md5(data).digest()==md;files[n]=data
original=dict(files)
files['apk_bootstrap118_fix.gd']=Path('updater-fix/root.gd').read_bytes()
files['incremental_update.gd']=Path('updater-fix/incremental_update.gd').read_bytes()
files['root.gd.remap']=b'[remap]\n\npath="res://apk_bootstrap118_fix.gd"\n'
entries=[];offset=0
for name,data in sorted(files.items()):
 n=('res://'+name).encode()+b'\0';n+=b'\0'*((-len(n))%4);entries.append(struct.pack('<I',len(n))+n+struct.pack('<QQ',offset,len(data))+hashlib.md5(data).digest()+struct.pack('<I',0));offset+=(len(data)+15)//16*16
index=b''.join(entries);filebase=(100+len(index)+15)//16*16
header=struct.pack('<6IQ',0x43504447,2,4,4,1,0,filebase)+bytes(64)+struct.pack('<I',len(files))
with Path('updater-fix/apk118.pck').open('wb') as f:
 f.write(header+index);f.write(bytes(filebase-f.tell()))
 for n,d in sorted(files.items()):f.write(d);f.write(bytes((-f.tell())%16))
report={'source_release':'v1.18','source_pck_sha256':hashlib.sha256(src).hexdigest(),'changed':list(k for k in files if k not in original or files[k]!=original[k]),'unchanged_resources':sum(files.get(k)==d for k,d in original.items()),'added':list(set(files)-set(original)),'deleted':list(set(original)-set(files))}
Path('updater-fix/APK_RESOURCE_DELTA.json').write_text(json.dumps(report,indent=2));print(report)
