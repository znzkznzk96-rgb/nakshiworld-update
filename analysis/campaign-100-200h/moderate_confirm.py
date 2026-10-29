import json
from campaign_moderate import run,P
rows=[]
cfg=dict(aqua_div=400,visitor_max=5.25,infra=True,fee_scale=8,gear_scale=8)
for label,kw in [('standard',{}),('fast',{'pace':25}),('slow',{'pace':50}),('future_price_half',{'fish_scale':.5}),('future_price_double',{'fish_scale':2})]:
 r=run(cfg,n=128,seed=20261031,**kw);r['label']=label;rows.append(r)
 (P/'moderate_confirm.json').write_text(json.dumps(rows,indent=2))
 print(label,r['end_hours'],r['median_upgrade_gap_hours'],flush=True)
