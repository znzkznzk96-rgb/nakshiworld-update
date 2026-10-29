import pathlib,statistics,json
OUT=pathlib.Path(__file__).parent
scope={'__file__':str(OUT/'compare40.py')};exec((OUT/'compare40.py').read_text().split('rows=[]')[0].replace('while t<7200:','while t<21600:'),scope)
rows=[]
for lv in range(6):
 cap=40+20*lv;regen=30+10*lv
 a=[scope['run'](cap,30,s,regen,True) for s in range(300)]
 times=[x['first_empty'] for x in a if x['first_empty'] is not None]
 rows.append(dict(level=lv,cap=cap,recovery_h=regen,depletion_mean=round(statistics.mean(times),1) if times else None,empty_by360=len(times)/len(a),refill_min=round(cap/regen*60,1)))
print(json.dumps(rows));(OUT/'recommended_steps.json').write_text(json.dumps(rows,indent=2)+'\n')
