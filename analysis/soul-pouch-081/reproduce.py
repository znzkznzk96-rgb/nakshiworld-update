import argparse,pathlib,subprocess,sys,os
p=argparse.ArgumentParser();p.add_argument('--godot',required=True);p.add_argument('--project',type=pathlib.Path,required=True);p.add_argument('--out',type=pathlib.Path,required=True);a=p.parse_args();a.out=a.out.resolve();a.out.mkdir(parents=True,exist_ok=True);a.project=a.project.resolve()
for script,output in [('pouch_fish_sample','fish.csv'),('pouch_growth_sample','growth.json')]:
 with (a.out/(script+'.log')).open('w') as f:subprocess.run([a.godot,'--headless','--path',str(a.project),'--script','tests/analysis/'+script+'.gd','--',str(a.out/output)],stdout=f,stderr=subprocess.STDOUT,check=True,timeout=180,env=dict(os.environ,XDG_DATA_HOME=str(a.out/('data-'+script))))
for mode in ['grid','sensitivity']:subprocess.run([sys.executable,str(pathlib.Path(__file__).with_name('simulate.py')),'--data',str(a.out),'--mode',mode],check=True,timeout=600)
