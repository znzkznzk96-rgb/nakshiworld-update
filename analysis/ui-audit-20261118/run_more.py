from pathlib import Path
import os,subprocess,json
p=Path('/tmp/helpchange/analysis/ui-audit-20261118');rs=[]
for n in ['guide_ac_preview','selected_ui_preview','pouch_inventory_preview','aquarium_b_preview','capture_robot_preview','combat_feedback_preview','robot097_preview']:
 o=p/'screens'/n;o.mkdir(exist_ok=True);env=os.environ.copy();env.update(DISPLAY='127.0.0.1:201',XDG_DATA_HOME='/tmp/ui-audit-20261118/more/'+n)
 r=subprocess.run(['/tmp/nwg/Godot_v4.4.1-stable_linux.x86_64','--path','/tmp/burtrun','--script','tests/'+n+'.gd','--audio-driver','Dummy','--rendering-method','gl_compatibility','--',str(o)],env=env,capture_output=True,text=True,timeout=180)
 s=r.stdout+r.stderr;(p/('more-'+n+'.log')).write_text(s);rs.append(dict(name=n,code=r.returncode,errors=[l for l in s.splitlines() if 'ERROR:' in l or 'failures=[' in l and 'failures=[]' not in l],png=len(list(o.glob('*.png')))));(p/'MORE.json').write_text(json.dumps(rs,indent=2));print(n,r.returncode,flush=True)
