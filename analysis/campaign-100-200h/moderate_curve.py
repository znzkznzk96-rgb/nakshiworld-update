import json
from campaign_moderate import run,P
rows=[]
for fraction in [.75,.5]:
 for curve in [[1,1,2,4,8,16],[1,1,3,6,12,24]]:
  r=run(dict(aqua_div=300/fraction,visitor_max=5.25,infra=True,fee_curve=curve),n=128)
  r['aquarium_fraction']=fraction;rows.append(r)
  (P/'moderate_curve.json').write_text(json.dumps(rows,indent=2))
  print(fraction,curve,r['end_hours'],r['median_upgrade_gap_hours'],flush=True)
