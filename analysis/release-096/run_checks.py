import concurrent.futures,json,os,pathlib,subprocess
root=pathlib.Path.cwd();out=root/'repo/analysis/release-096';out.mkdir(exist_ok=True)
suites=[r['suite'] for r in json.loads((root/'repo/analysis/capture-robot-implementation/checks/results.json').read_text())]
suites.append('balance096')
def run(s):
 env=dict(os.environ,XDG_DATA_HOME=str(root/'qa-release096'/s));p=out/(s+'.log')
 with p.open('w') as f:
  try:rc=subprocess.run([str(root/'build_tools/Godot_v4.4.1-stable_linux.x86_64'),'--headless','--path',str(root/'game_project'),'--script',f'tests/{s}_verify.gd'],env=env,stdout=f,stderr=subprocess.STDOUT,timeout=120).returncode
  except subprocess.TimeoutExpired:rc=124
 txt=p.read_text();ok=rc==0 and 'SCRIPT ERROR:' not in txt
 return dict(suite=s,passed=ok,exit=rc)
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:rows=list(pool.map(run,suites))
(out/'results.json').write_text(json.dumps(rows,indent=2));print('PASS',sum(r['passed'] for r in rows),'TOTAL',len(rows));print([r for r in rows if not r['passed']])
