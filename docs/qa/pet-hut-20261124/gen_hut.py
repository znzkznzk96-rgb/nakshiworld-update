import json,base64,os,time,urllib.request,urllib.error,sys
from PIL import Image
D='/home/claude/nakshiworld-update/docs/qa/pet-hut-20261124/'
K=open(os.path.expanduser('~/.pixellab_key')).read().strip()
H={'Authorization':'Bearer '+K,'Content-Type':'application/json'}
def call(u,d=None):
    try: return json.load(urllib.request.urlopen(urllib.request.Request(u,data=d,headers=H),timeout=180))
    except urllib.error.HTTPError as e: print('HTTP',e.code,e.read()[:600].decode()); raise SystemExit(1)
seed=int(sys.argv[1]); out=sys.argv[2]
a=Image.open(D+'ref_tackle.png').convert('RGB');b=Image.open(D+'ref_museum.png').convert('RGB')
c=Image.new('RGB',(a.width+b.width,max(a.height,b.height)),(255,255,255));c.paste(a,(0,0));c.paste(b,(a.width,0));c.save(D+'ref_combo.png')
b64=base64.b64encode(open(D+'ref_combo.png','rb').read()).decode()
desc=("Exactly ONE pixel art fishing village building, front view straight-on, same style as the reference buildings: green shingle gable roof with dark wood beams, cream plaster walls with brown timber framing, warm glowing lantern, small brick chimney. "
"A cozy pet hut: a large cream signboard under the roof with a brown paw print, a wooden door with a glowing window, a wicker basket full of white pearls beside the door, a few small white pearls decorating the roof ridge. "
"Crisp hand placed square pixel clusters, thick dark brown outline, 16-bit cozy fishing RPG style matching the reference. Fully inside canvas with 1px transparent margin. No text, no letters, no people, no ground, no water, no blur, no gradients, no dithering, no drop shadow.")
req={"description":desc,"image_size":{"width":140,"height":140},"no_background":True,"seed":seed,
"color_palette":"forest green, warm wood brown, cream, orange glow, white","target_palette":{"max_colors":28},
"concept_image":{"image":{"type":"base64","base64":b64,"format":"png"},"size":{"width":c.width,"height":c.height}}}
b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
r=call('https://api.pixellab.ai/v2/generate-ui-v2',json.dumps(req).encode());jid=r['background_job_id'];print('job',jid,flush=True)
for _ in range(40):
    time.sleep(5);s=call('https://api.pixellab.ai/v2/background-jobs/%s'%jid)
    if s.get('status') in('completed','failed'):break
print(s.get('status'))
j=s.get('last_response') or s
img=j.get('image') or (j.get('images') or [None])[0]
open(D+out,'wb').write(base64.b64decode(img['base64'] if isinstance(img,dict) else img))
print(b0,'->',call('https://api.pixellab.ai/v2/balance')['subscription']['generations'])
