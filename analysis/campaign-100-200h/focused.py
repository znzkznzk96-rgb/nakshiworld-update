import json
from campaign import run,P
rows=[]
for div in [2400,3600]:
 for off in [0,4,8]:
  r=run({'aqua_div':div,'visitor_max':2.5,'infra':True},n=64,offline=off)
  rows.append(r);(P/'focused.json').write_text(json.dumps(rows,indent=2))
  print(div,off,r['end_hours'],flush=True)
