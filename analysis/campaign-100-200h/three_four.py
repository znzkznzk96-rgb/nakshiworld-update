import json
from campaign_moderate import run,P
rows=[]
for label,kw in [('standard',{}),('fast',{'pace':25}),('slow',{'pace':50}),('future_half',{'fish_scale':.5}),('future_double',{'fish_scale':2})]:
 r=run(dict(aqua_div=400,visitor_max=5.25,infra=False,fee_scale=3,gear_scale=4),n=256,seed=20261102,**kw)
 r['label']=label;rows.append(r);(P/'three_four.json').write_text(json.dumps(rows,indent=2))
 print(label,r['end_hours'],flush=True)
