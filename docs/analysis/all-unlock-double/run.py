import json,statistics,math,csv
from pathlib import Path
from model import trial,summarize
out=Path(__file__).parent
cases={"original_six":dict(first_unlock=3300,target=52000),"tile_only_six":dict(first_unlock=3300,target=104000),"all_double_six":dict(first_unlock=6600,target=104000),"all_double_none":dict(first_unlock=6600,target=104000,aquarium=False),"all_double_twenty":dict(first_unlock=6600,target=104000,expand20=True),"all_double_split":dict(first_unlock=6600,target=104000,session_hours=1,interval_hours=12)}
result={}
with (out/'trials.csv').open('w',newline='') as f:
 writer=csv.writer(f);writer.writerow(['scenario','seed','day','active_h','elapsed_h','gold','sales','rewards','passive','bait_spent','upgrades_and_region'])
 for name,kw in cases.items():
  rows=[trial(20261024+i,**kw) for i in range(500)]
  for i,x in enumerate(rows):
   assert x['done']
   assert math.isclose(x['gold'],x['sales']+x['rewards']+x['passive']-x['bait_spent']-x['upgrades_and_region'],abs_tol=1e-5)
   assert math.isclose(x['passive'],x['online_income']+x['offline_income'],abs_tol=1e-5)
   assert x['active_h']<=x['day']*2+.1
   writer.writerow([name,20261024+i]+[x[k] for k in ['day','active_h','elapsed_h','gold','sales','rewards','passive','bait_spent','upgrades_and_region']])
  result[name]=dict(parameters=kw,**summarize(rows),individual_aquarium_share_median=statistics.median(x['passive']/(x['sales']+x['rewards']+x['passive']) for x in rows),valley_day_median=statistics.median(int(x['valley'][1]//24)+1 for x in rows))
  print(name,result[name]['day'],result[name]['active_h'],result[name]['individual_aquarium_share_median'],flush=True)
(out/'results.json').write_text(json.dumps(result,indent=2)+'\n')
print('PASS: 3000 completed; currency, income partition, session limits')
