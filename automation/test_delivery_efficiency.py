import importlib.util,json,pathlib,re,unittest,yaml
ROOT=pathlib.Path(__file__).resolve().parents[1]
def module(name):
 spec=importlib.util.spec_from_file_location(name,ROOT/'automation'/f'{name}.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
class DeliveryTests(unittest.TestCase):
 def setUp(self):
  self.contract=json.loads((ROOT/'docs/qa/delivery-efficiency/verification-contract.json').read_text())
  self.new=yaml.load((ROOT/'.github/workflows/verify-work.yml').read_text(),Loader=yaml.BaseLoader)
 def test_development_pushes_never_start_full_ci(self):
  paths=self.new['on']['push']['paths']
  self.assertEqual(paths,['automation/release.json','automation/verification-request.json'])
  self.assertNotIn('main',self.new['on']['push']['branches'])
 def test_every_required_check_is_preserved(self):
  old=set(self.contract['required_steps'])
  new={re.sub(r'v[0-9]+\.[0-9]+','BASELINE',s['name']) for s in self.new['jobs']['verify']['steps'] if 'name' in s}
  self.assertFalse(old-new)
  text=(ROOT/'.github/workflows/verify-work.yml').read_text()
  self.assertNotIn('REUSE_137_PREFIX',text)
  steps=self.new['jobs']['verify']['steps'];b=next(x['run'] for x in steps if x.get('name')=='Import and full regression checks')
  self.assertNotIn('continue',b)
  self.assertEqual(next(l for l in b.splitlines() if l.startswith('for suite in ')),self.contract['full_loop'])
  for step in steps:
   if re.sub(r'v[0-9]+\.[0-9]+','BASELINE',step.get('name','')) in old and step.get('name')!='Preserve verification logs':self.assertNotIn('if',step)
  self.assertLess(next(i for i,x in enumerate(steps) if x.get('name')=='Verify and render approved rift art integration'),next(i for i,x in enumerate(steps) if x.get('name')=='Import and full regression checks'))
 def test_timings_cover_pass_fail_and_incomplete_steps(self):
  m=module('ci_timings');s='2026-11-13T01:00:00Z';e='2026-11-13T01:00:07Z'
  report=m.summarize({'jobs':[{'id':2,'name':'verify','started_at':s,'completed_at':e,'steps':[{'name':'pass','status':'completed','conclusion':'success','started_at':s,'completed_at':e},{'name':'in progress','status':'in_progress','started_at':e}]}]},1)
  self.assertEqual(report['jobs'][0]['steps'][0]['seconds'],7)
  self.assertIsNone(report['jobs'][0]['steps'][1]['seconds'])
  with self.assertRaises(ValueError):m.seconds(e,s)
 def test_request_requires_source_and_reason(self):
  m=module('request_verification');self.assertEqual(m.request('a'*40,'save regression')['source_before_request'],'a'*40)
  with self.assertRaises(ValueError):m.request('main','reason')
  with self.assertRaises(ValueError):m.request('a'*40,' ')
if __name__=='__main__':unittest.main()
