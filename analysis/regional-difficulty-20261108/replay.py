"""Run research only in a restored test project; main.gd and real saves stay untouched."""
import argparse,hashlib,json,os,pathlib,shutil,subprocess
p=argparse.ArgumentParser();p.add_argument('--project',type=pathlib.Path,required=True);p.add_argument('--godot',type=pathlib.Path,required=True);p.add_argument('--config',type=pathlib.Path,required=True);p.add_argument('--out',type=pathlib.Path,required=True);a=p.parse_args()
a.out.mkdir(parents=True,exist_ok=True)
source=(a.project/'main.gd').read_text();digest=hashlib.sha256(source.encode()).hexdigest()
expected=json.loads(pathlib.Path(__file__).with_name('VERIFICATION.json').read_text())['main_source_sha256']
assert digest==expected,'Restore the study source commit before replay; do not double-apply tuned production formulas'
patches=[('extends Node2D','extends Node2D\nvar simulation_bonus_factor:float=1.0\nvar simulation_loss_factor:float=1.0'),('S.skimUsed = true;S.dist += 8;','S.skimUsed = true;S.dist += 8*simulation_bonus_factor;'),('S.dist -= pull * 2 * dt','S.dist -= pull * 2 * dt * simulation_loss_factor')]
for old,new in patches:
 assert source.count(old)==1,old
 source=source.replace(old,new,1)
(a.project/'tests/difficulty_sim_main.gd').write_text(source)
shutil.copy2(pathlib.Path(__file__).with_name('difficulty_sweep.gd'),a.project/'tests/difficulty_sweep.gd')
meta={'source_sha256':digest,'sim_source_sha256':hashlib.sha256(source.encode()).hexdigest(),'config_sha256':hashlib.sha256(a.config.read_bytes()).hexdigest(),'godot':subprocess.check_output([str(a.godot),'--version'],text=True).strip(),'modifications':'two sandbox-only progress scalars; profile/AI overrides live in harness; no production balance edit'}
(a.out/'REPLAY_INPUTS.json').write_text(json.dumps(meta,indent=2)+'\n')
with (a.out/'engine.log').open('w') as log:
 subprocess.run([str(a.godot),'--headless','--path',str(a.project),'--script','tests/difficulty_sweep.gd','--',str(a.config.resolve()),str((a.out/'raw.jsonl').resolve())],check=True,timeout=600,stdout=log,stderr=subprocess.STDOUT,env=dict(os.environ,XDG_DATA_HOME=str((a.out/'isolated-data').resolve())))
text=(a.out/'engine.log').read_text();assert 'SIM_COMPLETE' in text and 'ERROR:' not in text,text
print('Simulation complete:',a.out)
