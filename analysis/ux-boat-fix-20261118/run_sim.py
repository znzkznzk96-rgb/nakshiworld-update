import os,subprocess,concurrent.futures,json,pathlib,time
p=pathlib.Path('/tmp/helpchange/analysis/ux-boat-fix-20261118')
def run(job):
 mode,seed=job;env=os.environ.copy();env['XDG_DATA_HOME']=f'/tmp/boat-sim-{mode}-{seed}';out=p/f'{mode}-{seed}.jsonl';start=time.time()
 with (p/f'{mode}-{seed}.log').open('w') as log:
  r=subprocess.run(['/tmp/nwg/Godot_v4.4.1-stable_linux.x86_64','--headless','--path','/tmp/boatbase' if mode=='before' else '/tmp/burtrun','--script','tests/boat_balance_sim.gd','--',str(seed),str(out),'3','smart'],env=env,stdout=log,stderr=subprocess.STDOUT,timeout=600)
 return dict(mode=mode,seed=seed,code=r.returncode,seconds=round(time.time()-start,2))
rs=[]
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as ex:
 for r in ex.map(run,[(mode,seed) for seed in [17,31,59,83,107] for mode in ['before','after']]):
  rs.append(r);print(r,flush=True);(p/'SIM_RUNS.json').write_text(json.dumps(rs,indent=2))
