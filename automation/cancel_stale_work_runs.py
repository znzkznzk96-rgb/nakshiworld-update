"""Bounded cleanup of older push verifications on this same work branch only."""
import json, os, subprocess, urllib.parse

def stale(row, current):
    return (row['id'] < current['id'] and row['created_at'] < current['created_at']
            and row.get('event') == 'push' and row.get('head_branch') == current['head_branch']
            and current['head_branch'].startswith('work/')
            and row.get('head_repository', {}).get('id') == current.get('head_repository', {}).get('id')
            and row.get('status') == 'in_progress')

def api(path, method='GET'):
    result=subprocess.run(['gh','api','--method',method,path],text=True,capture_output=True,timeout=45)
    if result.returncode:
        raise RuntimeError('GitHub API failed for '+path+' (credentials suppressed)')
    return json.loads(result.stdout) if result.stdout.strip() else {}

def main():
    repo=os.environ['GITHUB_REPOSITORY'];run_id=int(os.environ['GITHUB_RUN_ID'])
    current=api(f'repos/{repo}/actions/runs/{run_id}')
    assert current['path']=='.github/workflows/verify-work.yml' and current['event']=='push'
    assert current['head_branch'].startswith('work/'), 'Never cancel production/release runs'
    rows=[]
    for page in range(1,4):
        route=f'repos/{repo}/actions/workflows/verify-work.yml/runs?'+urllib.parse.urlencode({'branch':current['head_branch'],'per_page':100,'page':page})
        batch=api(route)['workflow_runs'];rows.extend(batch)
        if len(batch)<100:break
    for row in rows:
        if not stale(row,current):continue
        fresh=api(f"repos/{repo}/actions/runs/{row['id']}")
        if not stale(fresh,current):continue
        action='force-cancel'
        try:api(f"repos/{repo}/actions/runs/{fresh['id']}/{action}",'POST')
        except RuntimeError:
            if api(f"repos/{repo}/actions/runs/{fresh['id']}")['status']!='completed':raise
        print('STALE_WORK_RUN_CANCEL_REQUESTED',fresh['id'],action)
    print('STALE_WORK_RUN_CLEANUP failures=[]')

if __name__=='__main__':main()
