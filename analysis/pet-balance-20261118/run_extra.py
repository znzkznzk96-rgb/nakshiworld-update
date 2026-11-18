import os,subprocess,concurrent.futures,json,pathlib,time
p=pathlib.Path(__file__).resolve().parent
modes=['auto_guard','aqua20_slots2']
seeds=[17,31,59,83,107,131,151,173,197,223]
def run(job):
 mode,seed=job;env=os.environ.copy();env['XDG_DATA_HOME']=f'/tmp/pet-study-{mode}-{seed}';start=time.time()
 with (p/f'{mode}-{seed}.log').open('w') as log:
  try:r=subprocess.run(['/tmp/pettools/Godot_v4.4.1-stable_linux.x86_64','--headless','--path','/tmp/petrun','--script','tests/pet_balance_sim.gd','--',str(seed),str(p/f'{mode}-{seed}.jsonl'),'3','smart',mode],env=env,stdout=log,stderr=subprocess.STDOUT,timeout=600);code=r.returncode
  except subprocess.TimeoutExpired:code=124
 return dict(mode=mode,seed=seed,code=code,seconds=round(time.time()-start,2))
rs=[]
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as ex:
 futures=[ex.submit(run,(mode,seed)) for seed in seeds for mode in modes]
 for f in concurrent.futures.as_completed(futures):
  r=f.result();rs.append(r);print(r,flush=True);(p/'RUNS_EXTRA.json').write_text(json.dumps(rs,indent=2))
