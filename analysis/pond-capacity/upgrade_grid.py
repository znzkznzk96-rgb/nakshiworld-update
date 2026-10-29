"""Upgrade sensitivity, fixed starting capacity40 / recovery30h. No game edits."""
import pathlib,statistics,json
OUT=pathlib.Path(__file__).parent
scope={'__file__':str(OUT/'compare40.py')};exec((OUT/'compare40.py').read_text().split('rows=[]')[0],scope);run=scope['run']
rows=[]
for cap_step in [10,15,20,30]:
 for regen_step in [5,10,15]:
  for level in [1,3,5]:
   for pace in [20,30,45]:
    cap=40+cap_step*level;regen=30+regen_step*level
    a=[run(cap,pace,s,regen,True) for s in range(200)]
    times=[v['first_empty'] for v in a if v['first_empty'] is not None]
    rows.append(dict(cap_step=cap_step,regen_step=regen_step,level=level,pace=pace,cap=cap,regen=regen,empty_by120=len(times)/len(a),first_empty=round(statistics.mean(times),1) if times else None,casts60=round(statistics.mean(v['casts60'] for v in a),1),stock30=round(statistics.mean(v['stock30'] for v in a),1),refill_min=round(cap/regen*60,1)))
ind=[]
for cap,regen in [(40,30),(50,30),(55,30),(60,30),(70,30),(40,35),(40,40),(40,45)]:
 a=[run(cap,30,s,regen,True) for s in range(1000)]
 ind.append(dict(cap=cap,regen=regen,first_empty=round(statistics.mean(v['first_empty'] for v in a),1),casts60=round(statistics.mean(v['casts60'] for v in a),1),refill_min=round(cap/regen*60,1)))
(OUT/'upgrade_results.json').write_text(json.dumps({'runs':len(rows)*200+len(ind)*1000,'grid':rows,'single_upgrade':ind,'assumptions':'Same stock-only model, fixed gear/pace, no purchases during run. 120m horizon. Missing depletion means censored beyond120, not infinite.'},indent=2)+'\n')
print('INDIVIDUAL',json.dumps(ind))
print('CANDIDATES',json.dumps([r for r in rows if (r['cap_step'],r['regen_step']) in [(10,5),(20,5),(20,10),(30,15)] and r['pace']==30]))
print('SPEED',json.dumps([r for r in rows if r['cap_step']==20 and r['regen_step']==10 and r['level']==5]))
