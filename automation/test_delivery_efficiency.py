import importlib.util,json,pathlib,re,unittest,yaml
ROOT=pathlib.Path(__file__).resolve().parents[1]
def module(name):
 spec=importlib.util.spec_from_file_location(name,ROOT/'automation'/f'{name}.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
class DeliveryTests(unittest.TestCase):
 def setUp(self):
  self.contract=json.loads((ROOT/'docs/qa/delivery-efficiency/verification-contract.json').read_text())
  self.new=yaml.load((ROOT/'.github/workflows/verify-work.yml').read_text(),Loader=yaml.BaseLoader)
  self.full=yaml.load((ROOT/'.github/workflows/verify-full.yml').read_text(),Loader=yaml.BaseLoader)
 def test_development_pushes_never_start_full_ci(self):
  paths=self.new['on']['push']['paths']
  self.assertEqual(paths,['automation/release.json','automation/verification-request.json'])
  self.assertNotIn('main',self.new['on']['push']['branches'])
 def test_every_required_check_is_preserved(self):
  # 검증을 빠른(verify-work)·전체(verify-full) 두 단계로 나눈 뒤에도 기존 필수 검사는 둘 중 하나에 모두 남아야 한다
  rename={'Full regression checks using prepared imported source':'Import and full regression checks','Preserve full verification logs':'Preserve verification logs'}
  norm=lambda n:rename.get(re.sub(r'v[0-9]+\.[0-9]+','BASELINE',n),re.sub(r'v[0-9]+\.[0-9]+','BASELINE',n))
  old=set(self.contract['required_steps'])
  new={norm(s['name']) for w in (self.new,self.full) for s in w['jobs']['verify']['steps'] if 'name' in s}
  self.assertFalse(old-new)
  text=(ROOT/'.github/workflows/verify-full.yml').read_text()+(ROOT/'.github/workflows/verify-work.yml').read_text()
  self.assertNotIn('REUSE_137_PREFIX',text)
  steps=self.full['jobs']['verify']['steps'];b=next(x['run'] for x in steps if x.get('name')=='Full regression checks using prepared imported source')
  self.assertNotIn('continue',b)
  suites=lambda l:set(l.split(' in ',1)[1].rstrip('; do').split())
  self.assertFalse(suites(self.contract['full_loop'])-suites(next(l for l in b.splitlines() if l.startswith('for suite in '))))   # 기존 검사 묶음은 모두 남아 있고, 이후 추가된 검사는 더해질 수 있다
  for step in steps:
   if norm(step.get('name','')) in old and step.get('name')!='Preserve full verification logs':self.assertNotIn('if',step)
  self.assertLess(next(i for i,x in enumerate(steps) if x.get('name')=='Verify and render approved rift art integration'),next(i for i,x in enumerate(steps) if x.get('name')=='Full regression checks using prepared imported source'))
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
