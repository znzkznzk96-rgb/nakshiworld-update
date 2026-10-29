import json,time
from campaign_moderate import run,P
rows=[];start=time.time()
cases=[(f,g,35) for f in [1,2,3] for g in [1,2,3]]+[(s,s,p) for s in [2,3] for p in [25,50]]
for fee,gear,pace in cases:
 r=run(dict(aqua_div=400,visitor_max=5.25,infra=False,fee_scale=fee,gear_scale=gear),n=128,seed=20261101,pace=pace)
 rows.append(r);(P/'two_three.json').write_text(json.dumps(rows,indent=2))
 print(fee,gear,pace,round(r['end_hours']['p50']/2,2),round(r['region_hours'][1]['p50']/2,2),flush=True)
print('DONE',time.time()-start,flush=True)
