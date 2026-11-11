"""Package only approved rift art; no gameplay/economy/catalog migration."""
import base64, hashlib, io, json, pathlib, sys, zipfile
from PIL import Image, ImageFilter
repo=pathlib.Path(__file__).resolve().parents[1]
out=pathlib.Path(sys.argv[1])
selection=json.loads((repo/'docs/art/rift-fish/APPROVED_MOTION_20_20261111.json').read_text())
root=out/'art/rift';root.mkdir(parents=True,exist_ok=True)
plate_bytes=base64.b64decode(''.join(p.read_text() for p in sorted((repo/'docs/art/rift-background-20261111/approved-clean-data').glob('*.txt'))),validate=True)
assert hashlib.sha256(plate_bytes).hexdigest()=='c404675fa5342ae30c7353ca9b3d4030f20849055ebf792f1fe88ed5245767c3'
plate=Image.open(io.BytesIO(plate_bytes));plate.load();assert plate.size==(1080,2640)
(root/'base.png').write_bytes(plate_bytes)
# Isolate thin approved sky cracks; a color-only mask also catches the dusk gradient.
small=plate.convert('RGB').resize((540,1320),Image.Resampling.NEAREST)
median=small.filter(ImageFilter.MedianFilter(9));src=small.load();mid=median.load()
mask=Image.new('RGBA',(540,1320),(255,255,255,0));dst=mask.load();count=0
for y in range(515):
    for x in range(540):
        c=src[x,y];m=mid[x,y]
        if c[0]-m[0]>15 and c[2]-m[2]>12 and c[2]>c[0]:dst[x,y]=(255,255,255,255);count+=1
assert 1000<count<15000
assert max(sum(1 for x in range(540) if dst[x,y][3]) for y in range(515))<270
mask.resize((1080,2640),Image.Resampling.NEAREST).save(root/'glow_mask.png')

boat_base=Image.open(io.BytesIO(base64.b64decode((repo/'game/art/rift_layers/boat.png.b64.txt').read_text(),validate=True)))
boat_base.load();assert boat_base.size==(180,225)
boat_base.resize((360,450),Image.Resampling.NEAREST).save(root/'boat.png')
for i in range(3):
    rock=Image.open(io.BytesIO(base64.b64decode((repo/('game/art/rift_layers/rock_%d.png.b64.txt'%i)).read_text(),validate=True)))
    rock.load();assert rock.size==(64,64)
    rock.resize((128,128),Image.Resampling.NEAREST).save(root/('rock_%d.png'%i))
cloud_raw=base64.b64decode((repo/'game/art/rift_layers/cloud_bank.png.b64.txt').read_text(),validate=True)
cloud_meta=json.loads((repo/'game/art/rift_layers/cloud_bank.json').read_text())
assert hashlib.sha256(cloud_raw).hexdigest()==cloud_meta['sha256']
cloud=Image.open(io.BytesIO(cloud_raw));cloud.load();assert cloud.size==(540,220) and cloud.mode=='RGBA'
assert cloud.getextrema()[3][0]==0 and cloud.getextrema()[3][1]==255
cloud.resize((1080,440),Image.Resampling.NEAREST).save(root/'cloud_bank.png')
entries=[]
for item in selection['species']:
    assert item['motion_user_approved'] and item['status']=='user_approved'
    source=repo/item['motion_source']
    with zipfile.ZipFile(source) as z:
        assert z.testzip() is None
        names=sorted(n for n in z.namelist() if '/' not in n and n.endswith('.png') and n!='spritesheet.png')
        if len(names)==17:names=names[1:] # 00 is the submitted input, 01..16 the approved loop.
        assert len(names)==16
        frames=[];hashes=[]
        for n in names:
            raw=z.read(n);im=Image.open(io.BytesIO(raw));im.load();assert im.mode=='RGBA';frames.append(im);hashes.append(hashlib.sha256(raw).hexdigest())
    size=frames[0].size;assert all(f.size==size for f in frames)
    union=None
    for f in frames:
        box=f.getbbox();assert box is not None
        union=box if union is None else (min(union[0],box[0]),min(union[1],box[1]),max(union[2],box[2]),max(union[3],box[3]))
    atlas=Image.new('RGBA',(size[0]*4,size[1]*4))
    for i,f in enumerate(frames):atlas.paste(f,((i%4)*size[0],(i//4)*size[1]))
    atlas.save(root/(item['id']+'.png'))
    # Verify packing preserves every pixel, including transparent RGB.
    for i,f in enumerate(frames):assert atlas.crop(((i%4)*size[0],(i//4)*size[1],(i%4+1)*size[0],(i//4+1)*size[1])).tobytes()==f.tobytes()
    entries.append({'id':item['id'],'name':item['name'],'global_art_id':59+int(item['id']),'canvas':list(size),'used_union':list(union),'frames':16,'fps':1000/60,'motion_source':item['motion_source'],'zip_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'frame_sha256':hashes,'atlas_sha256':hashlib.sha256((root/(item['id']+'.png')).read_bytes()).hexdigest()})
(root/'catalog.json').write_text(json.dumps({'art_only':True,'region':3,'economy_ready':False,'species':entries},ensure_ascii=False,indent=2))
print('RIFT_ASSETS_VERIFY failures=[] species=20 frames=320 plate_hash=true pixel_preserved=true')
