import os,subprocess,concurrent.futures,json,pathlib
p=pathlib.Path('/tmp/helpchange/analysis/ux-boat-fix-20261118')
def run(n):
 env=os.environ.copy();env['XDG_DATA_HOME']='/tmp/uxfix-related/'+n
 with (p/('verify-'+n+'.log')).open('w') as f:r=subprocess.run(['/tmp/nwg/Godot_v4.4.1-stable_linux.x86_64','--headless','--path','/tmp/burtrun','--script','tests/'+n+'_verify.gd'],env=env,stdout=f,stderr=subprocess.STDOUT,timeout=90)
 s=(p/('verify-'+n+'.log')).read_text();return dict(name=n,code=r.returncode,errors=[l for l in s.splitlines() if 'ERROR:' in l or 'failures=[' in l and 'failures=[]' not in l])
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as e:r=list(e.map(run,['ux_boat','pond_empty','spot_unlock_audio','guide_ac','guide','ui_guide','village_reward_notice','facility_growth','close_controls','hall_forge119']))
(p/'RELATED.json').write_text(json.dumps(r,indent=2));print(r)
