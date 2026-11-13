"""Create a deliberate full-verification request after focused checks.
Commit the generated request on work/*; it starts verification, never publication.
"""
import argparse,datetime,json,pathlib,re

def request(source,reason):
 if not re.fullmatch(r'[0-9a-f]{40}',source):raise ValueError('source must be the inspected work head SHA')
 if not reason.strip():raise ValueError('verification reason is required')
 return {'schema':1,'source_before_request':source,'reason':reason.strip(),'requested_at':datetime.datetime.now(datetime.timezone.utc).isoformat()}
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--source',required=True);p.add_argument('--reason',required=True);p.add_argument('--output',default=str(pathlib.Path(__file__).with_name('verification-request.json')));a=p.parse_args()
 out=pathlib.Path(a.output);out.write_text(json.dumps(request(a.source,a.reason),ensure_ascii=False,indent=2)+'\n');print(out)
