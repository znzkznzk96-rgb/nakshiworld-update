import json,time
from campaign_moderate import run,P
rows=[]
for fraction in [.75,.5]:
 for gear in [2,4,8]:
  r=run(dict(aqua_div=300/fraction,visitor_max=5.25,infra=True,fee_scale=4,gear_scale=gear),n=64)
  r['aquarium_fraction']=fraction;rows.append(r)
  (P/'moderate_investment.json').write_text(json.dumps(rows,indent=2))
  print(fraction,gear,r['end_hours'],r['median_upgrade_gap_hours'],flush=True)
