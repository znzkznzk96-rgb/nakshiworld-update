from pathlib import Path
import re,os,subprocess,concurrent.futures,json,time
repo=Path('/tmp/helpchange'); project=Path('/tmp/burtrun');out=repo/'analysis/ui-audit-20261118';out.mkdir(exist_ok=True)
godot='/tmp/nwg/Godot_v4.4.1-stable_linux.x86_64'
yml=(repo/'.github/workflows/verify-work.yml').read_text()
suites=set(re.findall(r'tests/([a-z0-9_]+)_verify\.gd',yml))
for line in yml.splitlines():
 if 'for suite in ' in line:suites.update(line.split('for suite in ')[1].split(';')[0].split())
suites={n for n in suites if (project/f'tests/{n}_verify.gd').exists() and not n.endswith('_native') and n not in {'incremental','incremental_network'}}
previews=set(re.findall(r'tests/([a-z0-9_]+preview)\.gd',yml))
results=[]
def run(name,kind):
 script=f'tests/{name}_verify.gd' if kind=='logic' else f'tests/{name}.gd'
 env=os.environ.copy();env['XDG_DATA_HOME']=f'/tmp/ui-audit-20261118/{kind}/{name}';env['DISPLAY']='127.0.0.1:196'
 cmd=[godot,'--path',str(project),'--script',script]
 if kind=='logic':cmd+=['--headless']
 else:cmd+=['--audio-driver','Dummy','--rendering-method','gl_compatibility','--',str(out/'screens'/name)]+(['540'] if name=='mail_gifts_preview' else [])
 (out/'screens'/name).mkdir(parents=True,exist_ok=True) if kind=='native' else None
 log=out/f'{kind}-{name}.log';t=time.monotonic()
 with log.open('w') as f:
  try:r=subprocess.run(cmd,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=120);code=r.returncode
  except subprocess.TimeoutExpired:code=124
 text=log.read_text();errors=[l for l in text.splitlines() if 'ERROR:' in l or 'failures=[' in l and 'failures=[]' not in l]
 return {'name':name,'kind':kind,'code':code,'errors':errors,'seconds':round(time.monotonic()-t,2),'log':log.name,'png':len(list((out/'screens'/name).glob('*.png'))) if kind=='native' else 0}
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
 for r in pool.map(lambda n:run(n,'logic'),sorted(suites)):
  results.append(r);(out/'RUNS.json').write_text(json.dumps(results,ensure_ascii=False,indent=2));print(r['kind'],r['name'],r['code'],len(r['errors']),flush=True)
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
 for r in pool.map(lambda n:run(n,'native'),sorted(previews)):
  results.append(r);(out/'RUNS.json').write_text(json.dumps(results,ensure_ascii=False,indent=2));print(r['kind'],r['name'],r['code'],len(r['errors']),r['png'],flush=True)
