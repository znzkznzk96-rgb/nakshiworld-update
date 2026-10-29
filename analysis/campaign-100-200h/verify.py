import json, pathlib, numpy as np
from campaign import run, P
checks=[]
for file in ['screen.json','sensitivity.json','alternatives.json','focused.json']:
 if not (P/file).exists():continue
 rows=json.loads((P/file).read_text())
 for r in rows:
  assert r['n']==r['end_hours']['observed']+r['censored']
  assert abs(r['within_100_200h']+r['below_100h']+r['above_200h_or_censored']-1)<1e-9
  for key in ['mean_manual_sale','mean_robot_sale','mean_aqua_income','mean_spending']:
   assert np.isfinite(r[key]) and r[key]>=0
  vals=[s['p50'] for s in r['region_hours'] if s['p50'] is not None]
  assert all(b>=a for a,b in zip(vals,vals[1:]))
  if r['config']['aqua_off']:assert r['mean_aqua_income']==0
  if r['config']['robot_off']:assert r['mean_robot_sale']==0
 checks.append(f'{file}: {len(rows)} scenario outputs internally consistent')
a=run({'aqua_off':True,'robot_off':True},n=4,days=2,seed=77)
b=run({'aqua_off':True,'robot_off':True},n=4,days=2,seed=77)
assert a==b
assert a['mean_aqua_income']==0 and a['mean_robot_sale']==0
checks.append('seed reproducibility and both income switches pass')
(P/'verification.json').write_text(json.dumps({'passed':checks,'scope':'Output invariants and analytical enhancement equations; not gameplay or full economy parity.'},indent=2))
print('\n'.join(checks))
