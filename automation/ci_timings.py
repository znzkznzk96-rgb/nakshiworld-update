"""Record Actions step durations without touching game or release inputs."""
import argparse,datetime,json,os,pathlib,subprocess

def seconds(start,end):
 if not start or not end:return None
 a=datetime.datetime.fromisoformat(start.replace('Z','+00:00'))
 b=datetime.datetime.fromisoformat(end.replace('Z','+00:00'))
 value=(b-a).total_seconds()
 if value<0:raise ValueError('negative step duration')
 return round(value,3)

def summarize(payload,run_id):
 jobs=[]
 for job in payload['jobs']:
  rows=[]
  for step in job.get('steps',[]):
   rows.append({'name':step['name'],'status':step['status'],'conclusion':step.get('conclusion'),'seconds':seconds(step.get('started_at'),step.get('completed_at'))})
  jobs.append({'id':job['id'],'name':job['name'],'seconds':seconds(job.get('started_at'),job.get('completed_at')),'steps':rows})
 return {'schema':1,'run_id':run_id,'jobs':jobs,'note':'Running steps have null duration; queue time and incomplete timing step are not counted.'}

if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--jobs-json');p.add_argument('--output',default='evidence/ci-timings.json');a=p.parse_args()
 run_id=int(os.environ.get('GITHUB_RUN_ID','0'))
 if a.jobs_json:payload=json.loads(pathlib.Path(a.jobs_json).read_text())
 else:
  repo=os.environ['GITHUB_REPOSITORY']
  raw=subprocess.check_output(['gh','api','--paginate','--slurp',f'repos/{repo}/actions/runs/{run_id}/jobs?per_page=100'])
  pages=json.loads(raw);payload={'jobs':[j for page in pages for j in page['jobs']]}
 report=summarize(payload,run_id);out=pathlib.Path(a.output);out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
 rows=[(s['seconds'],j['name'],s['name']) for j in report['jobs'] for s in j['steps'] if s['seconds'] is not None]
 lines=['## Verification timings','', '| Job | Step | Seconds |','| --- | --- | ---: |']
 for duration,job,name in sorted(rows,reverse=True)[:12]:lines.append(f'| {job.replace("|","/")} | {name.replace("|","/")} | {duration:g} |')
 lines+=['','Incomplete steps have no duration; no speedup is claimed before measurement.']
 summary='\n'.join(lines)+'\n';out.with_suffix('.md').write_text(summary)
 if os.environ.get('GITHUB_STEP_SUMMARY'):
  with open(os.environ['GITHUB_STEP_SUMMARY'],'a') as stream:stream.write(summary)
 print('CI_TIMINGS_RECORDED',out)
