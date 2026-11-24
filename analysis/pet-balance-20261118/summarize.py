from pathlib import Path
import json,statistics as st,zipfile
p=Path(__file__).resolve().parent
modes=['none','auto_s','auto_ss','auto_sss','aqua20','aqua50','slots','aqua50_slots','manual','stack','auto_guard','aqua20_slots2']
summary={};raw={}
for mode in modes:
 rows=[]
 for f in sorted(p.glob(mode+'-*.jsonl')):
  r=[json.loads(x) for x in f.read_text().splitlines()]
  if len(r)!=4 or 'final_online_h' not in r[-1]:continue
  rows.append(dict(seed=int(f.stem.rsplit('-',1)[-1]),valley_h=r[0]['total_h'],tile_h=r[1]['total_h'],rift_h=r[2]['total_h'],idle_h=r[-1]['idle_h'],pet_caught=r[2]['pet_caught'],robot_caught=r[2]['robot_caught'],aqua_hourly_rift=r[2]['aqua_hourly'],final_aqua_hourly=r[-1]['final_aqua_hourly'],gold_final=r[-1]['final_gold'],manual_caught=r[2]['caught'],manual_attempts=r[2]['attempts'],rift_cert_h=r[2]['cert_h'],rift_cash_wait_h=r[2]['total_h']-r[2]['cert_h'],rift_stage_idle_h=r[2]['stage_idle_h']))
 raw[mode]=rows
 if rows:
  summary[mode]={'n':len(rows)}
  for k in rows[0]:
   if k!='seed':summary[mode][k]={'median':st.median(x[k] for x in rows),'mean':st.mean(x[k] for x in rows),'min':min(x[k] for x in rows),'max':max(x[k] for x in rows)}
if 'none' in summary:
 for mode,s in summary.items():s['median_rift_reduction_percent']=(1-s['rift_h']['median']/summary['none']['rift_h']['median'])*100
import random
rng=random.Random(17)
base={x['seed']:x for x in raw['none']}
for mode,rows in raw.items():
 if not rows:continue
 deltas=[base[x['seed']]['rift_h']-x['rift_h'] for x in rows if x['seed'] in base]
 boots=sorted(st.mean(rng.choices(deltas,k=len(deltas))) for _ in range(5000))
 summary[mode]['paired']={'n':len(deltas),'mean_hours_saved':st.mean(deltas),'bootstrap95_mean_hours_saved':[boots[125],boots[4874]],'faster_runs':sum(d>0 for d in deltas),'slower_runs':sum(d<0 for d in deltas)}
result={'summary':summary,'samples':raw};(p/'RESULTS.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
for k,v in summary.items():print(k,v['n'],round(v['rift_h']['median'],2),round(v['median_rift_reduction_percent'],1),round(v['tile_h']['median'],2),round(v['idle_h']['median'],2))
