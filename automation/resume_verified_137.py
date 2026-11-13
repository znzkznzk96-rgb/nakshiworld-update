"""Reuse only the proven unchanged prefix of v1.37's interrupted verification.
Fail closed to a fresh full run on any source, tool, job, or failure mismatch.
"""
import json,os,pathlib,subprocess,re
ROOT=pathlib.Path(__file__).resolve().parents[1]
OLD='ed08215cc7ef4166f1cb7541e6c88dea5654152f'
RUN=43377848838
JOB=131728576871
REPO='znzkznzk96-rgb/nakshiworld-update'
def call(*args):return subprocess.check_output(args,cwd=ROOT).decode()
def api(path):return json.loads(call('gh','api',path))
def validate():
 assert os.environ['GITHUB_REPOSITORY']==REPO
 run=api(f'repos/{REPO}/actions/runs/{RUN}')
 assert run['head_sha']==OLD and run['head_branch']=='work/tile-release-107' and run['conclusion']=='failure'
 job=api(f'repos/{REPO}/actions/jobs/{JOB}')
 assert job['run_id']==RUN and job['conclusion']=='failure'
 steps=job['steps'];full=next(i for i,s in enumerate(steps) if s['name']=='Import and full regression checks')
 prefix=steps[3:full]
 assert prefix and all(s['conclusion']=='success' for s in prefix)
 assert steps[full]['conclusion']=='failure'
 call('git','fetch','--depth=1','origin',OLD)
 changed=call('git','diff','--name-only',OLD,'HEAD').splitlines()
 allowed={'game/tests/audio_save_verify.gd','automation/resume_verified_137.py','.github/workflows/verify-work.yml'}
 assert all(p in allowed or p.startswith('docs/') or p in ['WORK_STATE.json','CHANGELOG.md'] for p in changed),changed
 # Explicitly prove every runtime file and all previous build tools are identical.
 for p in changed:
  assert not p.startswith('game/') or p=='game/tests/audio_save_verify.gd'
  assert not p.startswith('automation/') or p=='automation/resume_verified_137.py'
 log=call('gh','api','--allow-escape-sequences',f'repos/{REPO}/actions/jobs/{JOB}/logs').replace('\r\n','\n')
 assert 'AUDIO_SAVE_VERIFY failures=["all sound resources imported"]' in log
 errors=re.findall(r'^\S+Z ERROR: (.+)$',log,re.M)
 errors=[e.strip() for e in errors]
 assert errors==['all sound resources imported'],errors
 assert 'SHOP_VERIFY failures=[]' in log
 evidence=ROOT/'evidence';evidence.mkdir(exist_ok=True)
 (evidence/'reused-prefix-job.log').write_text(log)
 report={'previous_run':RUN,'previous_job':JOB,'previous_source':OLD,'current_source':call('git','rev-parse','HEAD').strip(),'runtime_and_existing_tools_unchanged':True,'allowed_changed_files':changed,'reused_completed_steps':[s['name'] for s in prefix],'full_loop_resume_at':'audio_save','reason':'old test fixed total count at20; dedicated3new metal samples are valid; all earlier checks passed'}
 (evidence/'REUSED_PREFIX137.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
 with open(os.environ['GITHUB_ENV'],'a') as f:f.write('REUSE_137_PREFIX=true\n')
 print('REUSED_UNCHANGED137_PREFIX',len(prefix),'steps; remaining full checks begin at audio_save')
if __name__=='__main__':
 try:validate()
 except (AssertionError,KeyError,ValueError,subprocess.CalledProcessError) as exc:print('FRESH_FULL_VERIFICATION_REQUIRED',repr(exc))
