import hashlib,importlib.util,json,math,pathlib
P=pathlib.Path(__file__).parent;R=P.parents[2]
s=importlib.util.spec_from_file_location('sim',P/'simulate.py');m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
checks=[]
def check(v,msg):
 assert v,msg
 checks.append(msg)
check(m.MAIN==[[1,3,8,9,14,17],[21,24,28,31,34,37]],'approved main bundles match source')
check(m.BASE[39]==16000 and m.BASE[17]==1000,'regional price anchors')
check(m.const(m.B,'BAIT_PRICES')[:3]==[1,6,8],'baseline bait prices unchanged')
for seed in range(10):
 x=m.trial(seed);check(math.isclose(x['gold'],x['sales']+x['rewards']+x['passive']-x['bait_spent']-x['upgrades_and_region'],abs_tol=1e-6),f'currency conservation seed {seed}')
check(m.trial(1)==m.trial(1),'seed repeatability')
res=json.loads((P/'results.json').read_text());check(len(res['cases'])==25,'25 scenario cohorts')
check(all(x['runs']==400 for x in res['cases'].values()),'400 runs per cohort')
for name,x in res['cases'].items():
 if x['completed']:
  check(x['active_h']['p10']<=x['active_h']['median']<=x['active_h']['p90'],f'quantiles {name}')
check(len(json.loads((P/'bait_expected.json').read_text()))==18,'18 price cohorts / 1.8m samples')
prov=json.loads((P/'PROVENANCE.json').read_text())
for p,h in prov['files'].items():check(hashlib.sha256((R/p).read_bytes()).hexdigest()==h,f'source hash {p}')
(P/'QA.json').write_text(json.dumps({'passed':len(checks),'checks':checks,'game_runtime_test':False,'reason':'Economic model only; production game and saves untouched','report':'MODEL.md','sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [P/'simulate.py',P/'results.json',P/'bait_expected.json',P/'MODEL.md']}},ensure_ascii=False,indent=2)+'\n')
print('MODEL QA PASS',len(checks))
