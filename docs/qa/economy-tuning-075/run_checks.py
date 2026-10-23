import concurrent.futures,json,os,pathlib,re,subprocess,time
root=pathlib.Path.cwd();godot='/workspace/scratch/f8ca6c728a0f/aura_work/tool/Godot_v4.4.1-stable_linux.x86_64'
suites=re.search(r'for suite in (.*); do',(root/'repo/.github/workflows/verify-work.yml').read_text()).group(1).split()
def run(s):
 env=dict(os.environ,XDG_DATA_HOME=str(root/'balance-qa/user'/s));start=time.time();p=root/'balance-qa'/f'{s}.log'
 with p.open('w') as f:
  try:code=subprocess.run([godot,'--headless','--path',str(root/'simulation-source'),'--script',f'tests/{s}_verify.gd'],env=env,stdout=f,stderr=subprocess.STDOUT,timeout=90).returncode
  except subprocess.TimeoutExpired:code=124
 text=p.read_text();ok=code==0 and 'VERIFY failures=[]' in text and not re.search('SCRIPT ERROR:|Assertion failed|ERROR:',text)
 print(s,'PASS' if ok else 'FAIL',round(time.time()-start,1),flush=True)
 return dict(suite=s,passed=ok,exit_code=code,seconds=round(time.time()-start,2),log=f'{s}.log')
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:results=list(pool.map(run,suites))
(root/'balance-qa/results.json').write_text(json.dumps(results,indent=2)+'\n')
raise SystemExit(0 if all(x['passed'] for x in results) else 1)
