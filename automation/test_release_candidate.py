"""Isolated proof that publish cannot reuse stale/tampered/failed candidates."""
import importlib.util, json, os, pathlib, subprocess, tempfile, unittest
from unittest.mock import patch
spec=importlib.util.spec_from_file_location('candidate',pathlib.Path(__file__).with_name('release_candidate.py'));m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class CandidateTests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.root=pathlib.Path(self.tmp.name);self.old=m.ROOT;m.ROOT=self.root
  for p in ['game','automation','project','out']:(self.root/p).mkdir()
  (self.root/'game/main.gd').write_text('extends Node2D\n');(self.root/'project/main.gd').write_text('extends Node2D\n');(self.root/'project/project.godot').write_text('config_version=5\n')
  (self.root/'automation/release.json').write_text('{"code":110,"name":"1.10"}')
  self.git('init','-q');self.git('config','user.email','test@example.invalid');self.git('config','user.name','test');self.commit()
  self.out=self.root/'out';(self.out/'patch.pck').write_bytes(b'GDPC'+b'0'*1000000)
  m.seal(self.root/'project',self.out);self.meta=json.loads((self.out/'candidate.json').read_text())
 def tearDown(self):m.ROOT=self.old;self.tmp.cleanup()
 def git(self,*a):subprocess.run(['git',*a],cwd=self.root,check=True,capture_output=True)
 def commit(self):self.git('add','game','automation');self.git('commit','-qm','test')
 def test_identical_source_accepted(self):self.assertEqual(m.validate(self.out)['version']['code'],110)
 def test_changed_settings_rejected(self):
  (self.root/'automation/release.json').write_text('{"code":111,"name":"1.11"}');self.commit()
  with self.assertRaises(AssertionError):m.validate(self.out)
 def test_tampered_pack_rejected(self):
  (self.out/'patch.pck').write_bytes(b'GDPC'+b'1'*1000000)
  with self.assertRaises(AssertionError):m.validate(self.out)
 def test_dirty_source_rejected(self):
  (self.root/'game/main.gd').write_text('dirty')
  with self.assertRaises(subprocess.CalledProcessError):m.validate(self.out)
 def test_failed_or_fork_run_rejected(self):
  os.environ['GITHUB_REPOSITORY']='test/project'
  r=dict(status='completed',conclusion='failure',event='push',head_branch='work/test',head_sha=self.meta['source_commit'],id=self.meta['run_id'],path='.github/workflows/verify-work.yml',repository={'full_name':'test/project'})
  with self.assertRaises(AssertionError):m.validate(self.out,r)
  r['conclusion']='success';r['event']='pull_request'
  with self.assertRaises(AssertionError):m.validate(self.out,r)
 def test_unrelated_docs_do_not_invalidate(self):
  (self.root/'README.md').write_text('docs');self.git('add','README.md');self.git('commit','-qm','docs');m.validate(self.out)
 def test_draft_publication_uses_release_id_for_create_and_resume(self):
  os.environ['GITHUB_REPOSITORY']='test/project'
  (self.root/'automation/release-history.json').write_text(json.dumps([{'id':'1.10','body':['notes']}]))
  for existing in [False,True]:
   c=dict(self.meta,run_id=42)
   assets=[{'name':n,'size':v['size'],'digest':'sha256:'+v['sha256']} for n,v in c['files'].items()]
   release={'id':765,'tag_name':'v1.10','target_commitish':c['source_commit'],'draft':True,'assets':assets}
   state={'exists':existing};calls=[]
   def output(cmd,**kwargs):
    calls.append(cmd);endpoint=cmd[-1]
    if '/actions/workflows/' in endpoint:return json.dumps({'workflow_runs':[{'event':'push','head_branch':'work/test','id':42}]}).encode()
    if endpoint.endswith('/artifacts'):return json.dumps({'artifacts':[{'name':'release-candidate-proof','expired':False}]}).encode()
    if endpoint.endswith('/releases?per_page=100'):return json.dumps([release] if state['exists'] else []).encode()
    if endpoint.endswith('/releases/765'):return json.dumps(release).encode()
    raise AssertionError('Unexpected endpoint: '+endpoint)
   def execute(cmd,**kwargs):
    calls.append(cmd)
    if cmd[:3]==['gh','release','create']:state['exists']=True
    elif cmd[:4]==['gh','api','--method','PATCH']:
     self.assertEqual(cmd[4],'repos/test/project/releases/765')
     self.assertFalse(json.loads(kwargs['input'])['draft']);release['draft']=False
    return subprocess.CompletedProcess(cmd,0)
   with patch.object(m,'fingerprint',return_value='proof'),patch.object(m,'validate',return_value=c),patch.object(m.subprocess,'check_output',side_effect=output),patch.object(m.subprocess,'run',side_effect=execute):
    m.publish(self.out)
   self.assertFalse(release['draft'])
   self.assertFalse(any('/releases/tags/' in str(cmd) for cmd in calls))
   self.assertFalse(json.loads((self.out/'PUBLISH_RESULT.json').read_text())['rebuild'])
if __name__=='__main__':unittest.main()
