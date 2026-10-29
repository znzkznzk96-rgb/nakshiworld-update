import json,time
from campaign_moderate import run,P
start=time.time();rows=[]
for visitor in [5.25,2.5]:
 for fraction in [1,.75,.5]:
  for fee in [1,4,8,16]:
   cfg=dict(aqua_div=300/fraction,visitor_max=visitor,infra=True,fee_scale=fee)
   r=run(cfg,n=64);r['aquarium_fraction']=fraction;rows.append(r)
   (P/'moderate.json').write_text(json.dumps(rows,indent=2))
   print(fraction,visitor,fee,round(r['end_hours']['p50']/2,2),round(r['median_upgrade_gap_hours'],2),flush=True)
print('DONE',time.time()-start,flush=True)
