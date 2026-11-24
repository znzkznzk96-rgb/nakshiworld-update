from gen5 import *
REF=base64.b64encode(open('final2/otter/otter-final.png','rb').read()).decode()
T=". Chibi game pet sprite in exactly the same art style, palette, rendering and shading as the reference otter, 2-head-tall, right-facing 3/4 view, standing full body filling the frame, dark navy 1px outline, muted colors, no ground shadow, no glow."
J=[
("cd_duck",2026112501,"A small duck wearing a worn yellow rubber swim ring"),
("b_turtle",2026112502,"A small turtle carrying a taped cardboard box on its shell"),
("a_hedgehog",2026112503,"A hedgehog whose spines are strips of peeling yellow wallpaper, small green exit-sign badge on its chest"),
("s_hamster",2026112504,"A hamster-shaped creature made of damp brown carpet with stitched seams and one fluorescent tube stuck in its back"),
("ss_fox",2026112505,"A fox-shaped Backrooms entity made of torn yellow wallpaper over black shadow, tail of bent fluorescent tubes, green exit-sign eyes"),
("sss_wolf",2026112506,"A large wolf-shaped Backrooms entity of black shadow wearing a torn wallpaper cape and gold armor trim, crown of fluorescent tubes, pale glowing eyes"),
]
def gb(desc,seed,out):
    assert len(desc)<=500,len(desc)
    req={"description":desc,"image_size":{"width":96,"height":96},"style_image":{"type":"base64","base64":REF},"style_strength":60,"outline":"single color black outline","shading":"medium shading","detail":"medium detail","view":"side","no_background":True,"seed":seed}
    b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    r=call('https://api.pixellab.ai/v2/create-image-bitforge',json.dumps(req).encode()); json.dump(r,open(out+'.raw.json','w'))
    if 'background_job_id' in r and 'image' not in r:
        import time
        for _ in range(30):
            time.sleep(6); r=call('https://api.pixellab.ai/v2/background-jobs/'+r['background_job_id']) if 'background_job_id' in r else r; json.dump(r,open(out+'.raw.json','w'))
            if r.get('status')!='processing': break
    img=r.get('image') or r.get('last_response',{}).get('image')
    if not img: print('no image',str(r)[:300]); raise SystemExit(1)
    open(out+'.png','wb').write(base64.b64decode(img['base64']))
    b1=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    json.dump({"desc":desc,"seed":seed,"style":"otter-final","before":b0,"after":b1},open(out+'.rec.json','w'),ensure_ascii=False); print(out,b0,'->',b1,flush=True)
for n,seed,s in J:
    if os.path.exists(f'bk6/{n}.png'): continue
    gb(s+T,seed,f'bk6/{n}')
