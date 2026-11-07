import json,math,hashlib,statistics,collections,csv,shutil
from pathlib import Path
root=Path('sim-difficulty');out=Path('repo/analysis/regional-difficulty-20261108');all_summaries=[];rounds=[];total=0
keys=['area','rod','enh','star','grade','lf','profile','variant','sp']
def quantile(a,p):
 if not a:return None
 a=sorted(a);v=(len(a)-1)*p;i=int(v);return round(a[i]+(a[min(i+1,len(a)-1)]-a[i])*(v-i),3)
def aggregate(rows):
 n=len(rows);k=sum(x['success'] for x in rows);p=k/n;z=1.96;d=1+z*z/n;center=(p+z*z/(2*n))/d;delta=z*math.sqrt(p*(1-p)/n+z*z/(4*n*n))/d
 success=[x['seconds'] for x in rows if x['success']]
 return {'n':n,'success':k,'success_pct':round(100*p,2),'wilson95_pct':[round(100*(center-delta),2),round(100*(center+delta),2)],'median_success_seconds':quantile(success,.5),'p90_success_seconds':quantile(success,.9),'p90_all_ended_seconds':quantile([x['seconds'] for x in rows],.9),'outcomes':dict(collections.Counter(x['outcome'] for x in rows))}
for p in sorted(root.glob('*.jsonl')):
 cfg=json.loads(p.with_suffix('.json').read_text());raw=p.read_bytes();assert raw.endswith(b'\n');rows=[json.loads(l) for l in raw.splitlines()]
 expected=len(cfg['configs'])*len(cfg['scenarios'])*cfg['trials'];log=p.with_suffix('.log').read_text();assert len(rows)==expected and f'SIM_COMPLETE trials={expected}' in log and 'ERROR:' not in log,p
 total+=len(rows);groups=collections.defaultdict(list)
 for row in rows:groups[(row['config'],json.dumps(row['scenario'],sort_keys=True))].append(row)
 for (name,scenario),v in groups.items():all_summaries.append(dict(round=p.stem,config=name,scenario=json.loads(scenario),dt=cfg['dt'],**aggregate(v)))
 rounds.append({'round':p.stem,'trials':len(rows),'raw_sha256':hashlib.sha256(raw).hexdigest(),'config_sha256':hashlib.sha256(p.with_suffix('.json').read_bytes()).hexdigest(),'log':log})
 shutil.copy2(p.with_suffix('.json'),out/'configs'/p.with_suffix('.json').name)
(out/'CELL_SUMMARIES.json').write_text(json.dumps(all_summaries,ensure_ascii=False,indent=2)+'\n')
with (out/'CELL_SUMMARIES.csv').open('w') as f:
 writer=csv.writer(f);writer.writerow(['round','config',*keys,'dt','n','success_pct','median_success_seconds','p90_success_seconds','timeouts'])
 for x in all_summaries:writer.writerow([x['round'],x['config'],*[x['scenario'].get(k,1 if k=='lf' else 0) for k in keys],x['dt'],x['n'],x['success_pct'],x['median_success_seconds'],x['p90_success_seconds'],x['outcomes'].get('timeout',0)])
def find(round,rod,enh,star=0,grade=0,profile=1):
 return next(x for x in all_summaries if x['round']==round and x['config']!='baseline' and all(x['scenario'][k]==v for k,v in dict(rod=rod,enh=enh,star=star,grade=grade,profile=profile).items()))
normal=[find('final-validation-0',0,0),find('final-validation-1',0,0),find('final-validation-1',1,0),find('final-validation-1',1,3),find('validation-2',0,0),find('validation-2',1,8),find('validation-2',2,0),find('validation-2',2,5),find('validation-2',2,10)]
owners=[find('final-validation-1',1,0,4,1),find('final-validation-1',1,3,4,1),find('final-validation-1',1,8,4,1),find('validation-2',2,0,4,1),find('validation-2',2,5,4,1),find('validation-2',2,10,4,1)]
sensitivity=[]
for x in all_summaries:
 if x['round']=='dt-0.05':
  y=next(y for y in all_summaries if y['round']=='dt-0.025' and y['scenario']==x['scenario'])
  sensitivity.append({'scenario':x['scenario'],'success_delta_pp':round(y['success_pct']-x['success_pct'],2),'median_delta_seconds':round(y['median_success_seconds']-x['median_success_seconds'],3),'dt005':x,'dt0025':y})
parameters=json.loads((root/'FINAL_PARAMETERS.json').read_text());parameters['validated_regions']=[0,1,2];parameters['validated_rod_tiers']=[0,1,2];parameters['future_rod_values_status']='provisional, not simulated in this study';(out/'RECOMMENDED_PARAMETERS.json').write_text(json.dumps(parameters,ensure_ascii=False,indent=2)+'\n')
report={'date_kst':'2026-11-08','status':'recommendation_only_not_applied','trials_total':total,'designs_including_baseline':len({c['id'] for p in root.glob('*.json') if p.with_suffix('.jsonl').exists() for c in json.loads(p.read_text())['configs']}),'main_source_sha256':hashlib.sha256(Path('runtime/main.gd').read_bytes()).hexdigest(),'production_commit':'f0c39c5ed752c826a703d53d7465fc58488ea24a','engine':'4.4.1.stable.official.49a5bc7b6','normal_holdout':normal,'owner_rare_holdout':owners,'time_step_sensitivity':sensitivity,'rounds':rounds,'controllers':[{'profile':0,'reaction_seconds':.45,'mistake_probability_per_observed_behavior':.13},{'profile':1,'reaction_seconds':.23,'mistake_probability_per_observed_behavior':.045},{'profile':2,'reaction_seconds':.10,'mistake_probability_per_observed_behavior':.005}],'limits':{'fight_seconds':120,'failure_types_counted':True,'durations_are_success_conditional':True,'actual_human_success_rates_measured':False,'release_deployed':False,'region2_final_vs_validated_Q':'effective parameters identical for region2; final candidate preserves reservoir and increases valley rank resistance only'},'raw_storage':'Scratch raw JSONL; SHA/config/seeds/harness/cell aggregates persisted for deterministic replay; raw bytes are not claimed remotely stored'}
(out/'VERIFICATION.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print('TOTAL',total,'CELLS',len(all_summaries));print('SENSITIVITY',[(x['success_delta_pp'],x['median_delta_seconds']) for x in sensitivity]);print('FILESIZE',(out/'CELL_SUMMARIES.csv').stat().st_size)
