import json,base64,os,time,urllib.request,urllib.error
K=open(os.path.expanduser('~/.pixellab_key')).read().strip()
H={'Authorization':'Bearer '+K,'Content-Type':'application/json'}
def call(u,d=None):
    try: return json.load(urllib.request.urlopen(urllib.request.Request(u,data=d,headers=H),timeout=180))
    except urllib.error.HTTPError as e: print('HTTP',e.code,e.read()[:600].decode()); raise SystemExit(1)
b64=base64.b64encode(open('slot/ui6.png','rb').read()).decode()
req={"description":"Exactly ONE pixel art fishing-game slot machine, front view, straight-on. Keep the reference design: red and gold cabinet, a very large square reel window about 144 by 144 pixels filled with plain flat dark navy blue (the window fills most of the cabinet front) (no reels, no symbols), red ball lever on the right, row of yellow lamps on top, brass plate at bottom. Render in the same rich style as the game UI: warm brass and gold metal with riveted trim, glossy highlights, 3-4 shades per color, thick dark brown-black stepped outline, crisp square pixel clusters, warm cozy fishing-game lighting. Fully inside canvas with 1px transparent margin.",
"image_size":{"width":240,"height":270},"no_background":True,"seed":2026112602,
"concept_image":{"image":{"type":"base64","base64":b64,"format":"png"},"size":{"width":192,"height":224}}}
b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
r=call('https://api.pixellab.ai/v2/generate-ui-v2',json.dumps(req).encode());print(list(r)[:6]);jid=r.get('background_job_id') or r.get('id');json.dump(r,open('slot/ui7.job.json','w'))
print('job',jid,flush=True)
for _ in range(60):
    time.sleep(5);s=call('https://api.pixellab.ai/v2/background-jobs/%s'%jid)
    if s.get('status') in('completed','failed'):break
print(s.get('status'))
j=s.get('last_response') or s
img=j.get('image') or (j.get('images') or [None])[0]
open('slot/ui7.png','wb').write(base64.b64decode(img['base64'] if isinstance(img,dict) else img))
b1=call('https://api.pixellab.ai/v2/balance')['subscription']['generations'];print(b0,'->',b1)
