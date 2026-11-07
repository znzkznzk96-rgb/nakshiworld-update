"""Isolated proof that publish cannot reuse stale/tampered/failed candidates."""
import importlib.util, json, os, pathlib, subprocess, tempfile, unittest
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
if __name__=='__main__':unittest.main()
