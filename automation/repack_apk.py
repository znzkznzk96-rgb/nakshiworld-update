import hashlib,struct,zipfile,pathlib
import argparse
parser=argparse.ArgumentParser(description='Repack a verified Godot PCK into the original Android shell; output unsigned. Signing key stays external.')
parser.add_argument('--baseline',required=True)
parser.add_argument('--original-apk',required=True)
parser.add_argument('--output',required=True)
parser.add_argument('--icon',required=True)
parser.add_argument('--code',type=int,required=True)
parser.add_argument('--name',required=True)
parser.add_argument('--old-name',default='0.60')
args=parser.parse_args()
SOURCE_ROOT=pathlib.Path(__file__).resolve().parent
ROOT=pathlib.Path(args.output).resolve()
ROOT.mkdir(parents=True,exist_ok=True)
raw=pathlib.Path(args.baseline).read_bytes()
assert raw[:4]==b'GDPC'
assert len(args.name)==len(args.old_name), 'Binary XML in-place version name must retain length'
import subprocess
icon=pathlib.Path(args.icon).resolve()
assert icon.is_file()
base=struct.unpack_from('<Q',raw,24)[0];n=struct.unpack_from('<I',raw,96)[0];p=100;files={}
for _ in range(n):
 l=struct.unpack_from('<I',raw,p)[0];p+=4;name=raw[p:p+l].rstrip(b'\0').decode().removeprefix('res://');p+=l
 off,size=struct.unpack_from('<QQ',raw,p);p+=16;md=raw[p:p+16];p+=16;flags=struct.unpack_from('<I',raw,p)[0];p+=4
 assert flags==0
 data=raw[base+off:base+off+size];assert hashlib.md5(data).digest()==md
 files[name]=data
# Build a desktop-test PCK with exactly the same resources as the Android assets.
entries=[];offset=0
for name,data in sorted(files.items()):
 name=('res://'+name).encode()+b'\0';name+=b'\0'*((-len(name))%4)
 entries.append(struct.pack('<I',len(name))+name+struct.pack('<QQ',offset,len(data))+hashlib.md5(data).digest()+struct.pack('<I',0))
 offset+=len(data);offset+=(16-offset%16)%16
index=b''.join(entries);filebase=(100+len(index)+15)//16*16
header=struct.pack('<6IQ',0x43504447,2,4,4,1,0,filebase)+bytes(64)+struct.pack('<I',len(files))
with (ROOT/'verified.pck').open('wb') as out:
 out.write(header+index);out.write(bytes(filebase-out.tell()))
 for _,data in sorted(files.items()):out.write(data);out.write(bytes((-out.tell())%16))
# Replace all original game assets with the verified 0.57 pack and new bootstrap.
original=pathlib.Path(args.original_apk)
with zipfile.ZipFile(original) as src,zipfile.ZipFile(ROOT/'unsigned.apk','w',zipfile.ZIP_DEFLATED) as dst:
 for info in src.infolist():
  if info.filename.startswith(('assets/','META-INF/')):continue
  data=src.read(info.filename)
  if info.filename=='AndroidManifest.xml':
   b=bytearray(data);p=8;ss=[]
   def length(q,utf):
    if utf:
     n=b[q];q+=1
     if n&128:n=((n&127)<<8)|b[q];q+=1
    else:
     n=struct.unpack_from('<H',b,q)[0];q+=2
     if n&32768:n=((n&32767)<<16)|struct.unpack_from('<H',b,q)[0];q+=2
    return n,q
   while p<len(b):
    t,h,size=struct.unpack_from('<HHI',b,p)
    if t==1:
     count,styles,flags,start,_=struct.unpack_from('<5I',b,p+8);utf=bool(flags&256)
     for i in range(count):
      q=p+start+struct.unpack_from('<I',b,p+h+i*4)[0];n,q=length(q,utf)
      if utf:n,q=length(q,True)
      s=bytes(b[q:q+n*(1 if utf else 2)]).decode('utf-8' if utf else 'utf-16le');ss.append(s)
      if s==args.old_name:b[q:q+n*(1 if utf else 2)]=args.name.encode('utf-8' if utf else 'utf-16le')
    if t==258:
     ns,name,ast,asz,cnt=struct.unpack_from('<IIHHH',b,p+16)
     if ss[name]=='manifest':
      for i in range(cnt):
       q=p+16+ast+i*asz;name=struct.unpack_from('<I',b,q+4)[0]
       if ss[name]=='versionCode':struct.pack_into('<I',b,q+16,args.code)
    p+=size
   data=bytes(b)
  if info.filename.startswith('res/mipmap') and info.filename.endswith('.png') and '/icon' in info.filename:
   width,height=struct.unpack_from('>II',data,16)
   target=ROOT/('icon-'+info.filename.replace('/','_'))
   if info.filename.endswith('/icon_foreground.png'):
    command=['convert','-size',f'{width}x{height}','xc:none',str(target)]
   elif info.filename.endswith('/icon_monochrome.png'):
    # Use dark ink from the approved art as Android's single-color themed mask.
    command=['convert',str(icon),'-filter','point','-resize',f'{int(width*.72)}x{int(height*.72)}','-colorspace','Gray','-threshold','22%','-negate','-alpha','copy','-fill','white','-colorize','100','-background','none','-gravity','center','-extent',f'{width}x{height}',str(target)]
   elif info.filename.endswith('/icon_background.png'):
    command=['convert',str(icon),'-filter','point','-resize',f'{int(width*.78)}x{int(height*.78)}','-background','#a28bed','-gravity','center','-extent',f'{width}x{height}',str(target)]
   else:
    command=['convert',str(icon),'-filter','point','-resize',f'{width}x{height}',str(target)]
   subprocess.run(command,check=True);data=target.read_bytes()
  dst.writestr(info,data)
 dst.writestr('assets/_cl_',src.read('assets/_cl_'))
 for name,data in sorted(files.items()):dst.writestr('assets/'+name,data)
print('Packed',len(files),'resources; version',args.name,'code',args.code)
