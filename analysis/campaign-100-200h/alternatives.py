import json,time
from campaign import run,P
rows=[]
for div,fee in [(2400,1),(3600,1),(7200,1),(3600,.5),(7200,.5),(2400,2)]:
 r=run({'aqua_div':div,'visitor_max':2.5,'infra':True,'fee_scale':fee},n=128)
 rows.append(r);(P/'alternatives.json').write_text(json.dumps(rows,indent=2))
 print(div,fee,r['end_hours'],r['median_upgrade_gap_hours'],flush=True)
