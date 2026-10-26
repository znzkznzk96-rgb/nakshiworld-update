"""Reproduce full deterministic engine census, then aggregate it (requires pandas).
python automation/expedition_balance_analysis.py --godot /path/to/godot --project /path/to/restored/game --out evidence/balance
Pass --summarize-only to aggregate an existing output directory.
"""
import argparse,concurrent.futures,hashlib,json,os,pathlib,subprocess
import pandas as pd
p=argparse.ArgumentParser();p.add_argument('--godot',default='godot');p.add_argument('--project',type=pathlib.Path,required=True);p.add_argument('--out',type=pathlib.Path,required=True);p.add_argument('--summarize-only',action='store_true');a=p.parse_args();a.project=a.project.resolve();a.out=a.out.resolve();a.out.mkdir(parents=True,exist_ok=True)
cases=[(s,4,False) for s in ['current','shield','pressure','pressure_hp','curve']]+[(s,iv,True) for s in ['current','pressure'] for iv in [0,8]]
def run(case):
 s,iv,balanced=case;tag=s+('-iv'+str(iv) if balanced else '')
 cmd=[a.godot,'--headless','--path',str(a.project),'--script','tests/analysis/balance_scan.gd','--',str(a.out/(tag+'.csv')),s,'0','1','3375',str(iv)]
 if balanced:cmd.append('balanced')
 with (a.out/(tag+'.log')).open('w') as f:subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT,check=True,timeout=900,env=dict(os.environ,XDG_DATA_HOME=str(a.out/('data-'+tag))))
if not a.summarize_only:
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:list(pool.map(run,cases))
 subprocess.run([a.godot,'--headless','--path',str(a.project),'--script','tests/analysis/balance_parity.gd','--',str(a.out/'parity.json')],check=True,timeout=180)
cat=json.loads((a.project/'addons/expedition/catalog.json').read_text());summary=[];manifest=[]
def balanced(t):return [cat['soldiers'][i]['role'] for i in [t//225,t//15%15,t%15]]==['defense','attack','support']
for s,iv,only_balanced in cases:
 tag=s+('-iv'+str(iv) if only_balanced else '');path=a.out/(tag+'.csv');d=pd.read_csv(path)
 expected=13750 if only_balanced else 241250
 assert len(d)==expected,(tag,len(d),expected)
 assert not d.duplicated(['profile','team','round']).any()
 manifest.append(dict(file=path.name,rows=len(d),bytes=path.stat().st_size,sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
 for scope,frame in [('enumerated',d),('defense_attack_support',d[d.team.map(balanced)])]:
  for (profile,r),g in frame.groupby(['profile','round'],sort=False):
   summary.append(dict(scenario=s,iv=iv,scope=scope,profile=profile,round=int(r),teams=len(g),wins=int(g.win.sum()),win_percent=round(g.win.mean()*100,2),median_front_hp_percent=round(g.front_ratio.median()*100,2),median_team_hp_percent=round(g.hp_ratio.median()*100,2),zero_damage_hit_percent=round(g.no_hp_hits.sum()/g.hits.sum()*100,2),median_ticks=float(g.ticks.median())))
source_hashes={f:hashlib.sha256((a.project/f).read_bytes()).hexdigest() for f in ['addons/expedition/model.gd','addons/expedition/catalog.json','tests/analysis/balance_scan.gd','tests/analysis/candidate_model.gd','tests/analysis/balance_parity.gd']}
(a.out/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
pd.DataFrame(summary).to_csv(a.out/'summary.csv',index=False)
(a.out/'manifest.json').write_text(json.dumps(dict(engine='Godot 4.4.1',baseline_commit='a74e060d8eda34ab6650c0d2d3d72d9e646b990d',fights=sum(x['rows'] for x in manifest),files=manifest,source_sha256=source_hashes),ensure_ascii=False,indent=2)+'\n')
print('SUMMARY',sum(x['rows'] for x in manifest),'fights')
