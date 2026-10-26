"""Reproduce the hard progression census with Godot 4.4.1 and pandas.
--project points at the restored game project, --out holds generated CSV/log evidence.
"""
import argparse,concurrent.futures,hashlib,json,os,pathlib,subprocess
import pandas as pd
p=argparse.ArgumentParser();p.add_argument('--project',type=pathlib.Path,required=True);p.add_argument('--out',type=pathlib.Path,required=True);p.add_argument('--godot',default='godot');p.add_argument('--summarize-only',action='store_true');a=p.parse_args();a.project=a.project.resolve();a.out=a.out.resolve();a.out.mkdir(parents=True,exist_ok=True)
cases=[]
for m in ['2.8','3.0','3.2','3.5','4.0']:
 for iv in [0,4,8]:cases.append((f'r3_{m}-iv{iv}',f'r3_{m}',iv,True,'hard_balance_scan',2125))
for s in ['hard','expert']:cases.append((f'{s}-iv4',s,4,False,'hard_balance_scan',248750))
for iv in [0,8]:cases.append((f'hard-iv{iv}','hard',iv,True,'hard_balance_scan',21250))
for m in ['3.2','3.5']:cases.append((f'mixed-r3_{m}',f'r3_{m}',4,True,'hard_mixed_iv_scan',50000))
cases.append(('runtime-hard-iv4','hard',4,False,'hard_runtime_scan',248750))
def run(case):
 tag,s,iv,balanced,script,_=case;cmd=[a.godot,'--headless','--path',str(a.project),'--script',f'tests/analysis/{script}.gd','--',str(a.out/(tag+'.csv')),s,'0','1','3375',str(iv)]
 if balanced:cmd.append('balanced')
 with (a.out/(tag+'.log')).open('w') as f:subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT,env=dict(os.environ,XDG_DATA_HOME=str(a.out/('data-'+tag))),check=True,timeout=900)
if not a.summarize_only:
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:list(pool.map(run,cases))
cat=json.loads((a.project/'addons/expedition/catalog.json').read_text());summary=[];manifest=[]
def balanced(t):return [cat['soldiers'][i]['role'] for i in [t//225,t//15%15,t%15]]==['defense','attack','support']
for tag,s,iv,_,script,expected in cases:
 path=a.out/(tag+'.csv');d=pd.read_csv(path);assert len(d)==expected,(tag,len(d),expected)
 assert not d.duplicated(['profile','team','round']+(['sample'] if 'sample' in d else [])).any()
 manifest.append(dict(file=path.name,rows=len(d),sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
 for scope,frame in [('enumerated',d),('defense_attack_support',d[d.team.map(balanced)])]:
  for (profile,r),g in frame.groupby(['profile','round'],sort=False):
   summary.append(dict(dataset=tag,scenario=s,iv='mixed_seeded' if script=='hard_mixed_iv_scan' else iv,scope=scope,profile=profile,round=int(r),cases=len(g),wins=int(g.win.sum()),success_percent=round(100*g.win.mean(),4),median_front_hp_percent=round(100*g.front_ratio.median(),4),median_team_hp_percent=round(100*g.hp_ratio.median(),4),median_ticks=float(g.ticks.median())))
assert (a.out/'runtime-hard-iv4.csv').read_bytes()==(a.out/'hard-iv4.csv').read_bytes(),'runtime integration differs from candidate'
source_hashes={f:hashlib.sha256((a.project/f).read_bytes()).hexdigest() for f in ['addons/expedition/model.gd','addons/expedition/catalog.json','tests/analysis/baseline080_model.gd','tests/analysis/candidate_model.gd','tests/analysis/hard_balance_scan.gd','tests/analysis/hard_mixed_iv_scan.gd','tests/analysis/hard_runtime_scan.gd','tests/expedition_hard_balance_verify.gd']}
pd.DataFrame(summary).to_csv(a.out/'summary.csv',index=False)
(a.out/'manifest.json').write_text(json.dumps(dict(engine='Godot 4.4.1',candidate_fights=671875,runtime_comparison_fights=248750,total_csv_rows=sum(x['rows'] for x in manifest),runtime_candidate_byte_identical=True,files=manifest,source_sha256=source_hashes),ensure_ascii=False,indent=2)+'\n')
print('SUMMARY',sum(x['rows'] for x in manifest),'rows; actual runtime matches candidate exactly')
