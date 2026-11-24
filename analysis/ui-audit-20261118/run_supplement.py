from pathlib import Path
import subprocess,os,json
out=Path('/tmp/helpchange/analysis/ui-audit-20261118');results=[];godot='/tmp/nwg/Godot_v4.4.1-stable_linux.x86_64'
for name in ['bundle_next_unlock_native','night_play_native','regional_night_native','tile107_native','valley_native']:
 env=os.environ.copy();env['DISPLAY']='127.0.0.1:198';env['XDG_DATA_HOME']='/tmp/audit-supp-'+name
 log=out/('supp-'+name+'.log')
 with log.open('w') as f:
  try:r=subprocess.run([godot,'--audio-driver','Dummy','--rendering-method','gl_compatibility','--path','/tmp/burtrun','--script','tests/'+name+'_verify.gd','--',str(out/'screens'/name)],env=env,stdout=f,stderr=subprocess.STDOUT,timeout=120);code=r.returncode
  except subprocess.TimeoutExpired:code=124
 text=log.read_text();results.append({'name':name,'code':code,'errors':[x for x in text.splitlines() if 'ERROR:' in x or 'failures=[' in x and 'failures=[]' not in x]});(out/'SUPPLEMENT.json').write_text(json.dumps(results,indent=2));print(name,code,flush=True)
