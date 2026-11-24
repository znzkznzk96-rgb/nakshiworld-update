"""v1.44 방식 APK 제작: 원본 APK 껍데기 + 봉인 patch.pck 자원 + 승인 아이콘 24종, 기존 키로 서명.
사용: python3 migration/make_apk.py --pck patch.pck --code 145 --name 1.45 --shell nakshiworld_v0.11.apk --ks debug.keystore --out NAKSHIWORLD_1.45.apk --bt <build-tools 경로>
키·원본 APK는 ChatGPT 보관 ZIP(nakshiworld_handoff)에 있고 저장소에는 넣지 않는다. 빌드 도구: https://dl.google.com/android/repository/build-tools_r34-linux.zip"""
import json,hashlib,argparse,struct,zipfile,re,subprocess,pathlib,tempfile
a=argparse.ArgumentParser()
for k in ['pck','code','name','shell','ks','out','bt']:a.add_argument('--'+k,required=True)
A=a.parse_args();ROOT=pathlib.Path(__file__).resolve().parents[1]

def read_pck(p):
    raw=open(p,'rb').read();base=struct.unpack_from('<Q',raw,24)[0];n=struct.unpack_from('<I',raw,96)[0];q=100;files={}
    for _ in range(n):
        l=struct.unpack_from('<I',raw,q)[0];q+=4;name=raw[q:q+l].rstrip(b'\0').decode().removeprefix('res://');q+=l
        off,size=struct.unpack_from('<QQ',raw,q);q+=16;md=raw[q:q+16];q+=20
        d=raw[base+off:base+off+size];assert hashlib.md5(d).digest()==md;files[name]=d
    return files
files=read_pck(A.pck)
boot=(ROOT/'game/root.gd').read_text(encoding='utf-8')
boot=re.sub(r'const BUILD_CODE := \d+','const BUILD_CODE := '+A.code,boot);boot=re.sub(r'const BUILD_NAME := "[^"]+"','const BUILD_NAME := "%s"'%A.name,boot)
files['apk_bootstrap%s.gd'%A.code]=boot.encode()
files['root.gd.remap']=('[remap]\n\npath="res://apk_bootstrap%s.gd"\n'%A.code).encode()
tmp=pathlib.Path(tempfile.mkdtemp())
def manifest(data):
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
                if s=='0.11':b[q:q+n*(1 if utf else 2)]=A.name.encode('utf-8' if utf else 'utf-16le')
        if t==258:
            ns,name,ast,asz,cnt=struct.unpack_from('<IIHHH',b,p+16)
            if ss[name]=='manifest':
                for i in range(cnt):
                    q=p+16+ast+i*asz;nm=struct.unpack_from('<I',b,q+4)[0]
                    if ss[nm]=='versionCode':struct.pack_into('<I',b,q+16,int(A.code))
        p+=size
    return bytes(b)
src=zipfile.ZipFile(A.shell)
iz=zipfile.ZipFile(ROOT/'automation/approved-puffer-icons.zip');exp=json.loads(iz.read('SHA256.json'));assert len(exp)==24
icons={n:iz.read(n) for n in exp};assert all(hashlib.sha256(d).hexdigest()==exp[n] for n,d in icons.items())
assert {n for n in src.namelist() if n.startswith('res/mipmap') and n.endswith('.png')}==set(icons)
with zipfile.ZipFile(str(tmp/'unsigned.apk'),'w',zipfile.ZIP_DEFLATED) as dst:
    for info in src.infolist():
        if info.filename.startswith(('assets/','META-INF/')):continue
        d=icons.get(info.filename,src.read(info.filename))
        if info.filename=='AndroidManifest.xml':d=manifest(d)
        dst.writestr(info,d)
    dst.writestr('assets/_cl_',src.read('assets/_cl_'))
    for n,d in sorted(files.items()):dst.writestr('assets/'+n,d)

bt=pathlib.Path(A.bt)
subprocess.run([bt/'zipalign','-f','-p','4',tmp/'unsigned.apk',tmp/'aligned.apk'],check=True)
subprocess.run([bt/'apksigner','sign','--ks',A.ks,'--ks-pass','pass:android','--key-pass','pass:android','--ks-key-alias','androiddebugkey','--out',A.out,tmp/'aligned.apk'],check=True)
print(subprocess.run([bt/'apksigner','verify','--print-certs',A.out],capture_output=True,text=True).stdout)
print('기존 인증서 SHA-256은 5939b259…b763 이어야 한다')
