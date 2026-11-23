import json,base64,os,time,io,urllib.request,urllib.error
from PIL import Image
K=open(os.path.expanduser('~/.pixellab_key')).read().strip()
H={'Authorization':'Bearer '+K,'Content-Type':'application/json'}
def call(u,d=None):
    try: return json.load(urllib.request.urlopen(urllib.request.Request(u,data=d,headers=H),timeout=180))
    except urllib.error.HTTPError as e: print('HTTP',e.code,e.read()[:600].decode()); raise SystemExit(1)
g='/home/claude/nakshiworld-update/game/art/shop_repair/'
a=Image.open(g+'panel.png').convert('RGBA');b=Image.open(g+'button.png').convert('RGBA')
c=Image.new('RGBA',(256,a.height+b.height),(0,0,0,0));c.paste(a,(0,0));c.paste(b,(0,a.height));c.save('slot/ref_ui.png')
b64=base64.b64encode(open('slot/ref_ui.png','rb').read()).decode()
desc=("Exactly ONE pixel art fishing-game arcade slot machine cabinet, front view straight-on, built from the same UI kit as the reference image: warm brown wooden cabinet with thick wooden frame, gold brass corner ornaments and rivets, deep teal inset panels, cream parchment plaque. "
"Parts: row of five small gold lamps on top, one very large square reel window in the middle filled with one uninterrupted flat dark teal interior (no reels, no symbols), a brass lever with a ball handle on the right side, small cream plaque and coin slot at the bottom. "
"Crisp hand placed square pixel clusters, 3 shades per material, thick dark brown-black stepped outline, cozy detailed 16-bit fishing RPG style matching the reference. "
"Fully inside canvas with 1px transparent margin. No red cabinet, no text, no letters, no numbers, no blur, no gradients, no noise, no dithering, no drop shadow, no extra UI elements.")
req={"description":desc,"image_size":{"width":256,"height":288},"no_background":True,"seed":2026112603,
"color_palette":"warm wood brown, gold brass, deep teal, cream, dark brown outline","target_palette":{"max_colors":24},
"concept_image":{"image":{"type":"base64","base64":b64,"format":"png"},"size":{"width":256,"height":a.height+b.height}}}
b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
r=call('https://api.pixellab.ai/v2/generate-ui-v2',json.dumps(req).encode());jid=r['background_job_id']
json.dump({'job':jid,'req':{k:v for k,v in req.items() if k!='concept_image'},'before':b0},open('slot/ui8.job.json','w'),ensure_ascii=False)
print('job',jid,flush=True)
for _ in range(40):
    time.sleep(5);s=call('https://api.pixellab.ai/v2/background-jobs/%s'%jid)
    if s.get('status') in('completed','failed'):break
print(s.get('status'))
j=s.get('last_response') or s
img=j.get('image') or (j.get('images') or [None])[0]
open('slot/ui8.png','wb').write(base64.b64decode(img['base64'] if isinstance(img,dict) else img))
print(b0,'->',call('https://api.pixellab.ai/v2/balance')['subscription']['generations'])
