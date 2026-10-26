"""Follow-up comparisons; snapshot constants keep v0.75 baseline independent of game edits."""
import importlib.util,json,pathlib,random,hashlib
import numpy as np
P=pathlib.Path(__file__).parent
s=importlib.util.spec_from_file_location('base',P.parent/'progression-075/simulate.py');m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
keys=['STAR','GRADE','BY','MEAN','MAX','BASE','GM','WM','WB','MAIN','SUB','BAGCAP','BAGPRICE']
f=P/'baseline_constants.json'
if not f.exists():f.write_text(json.dumps({k:getattr(m,k) for k in keys},ensure_ascii=False,indent=2)+'\n')
snapshot=json.loads(f.read_text())
for k,v in snapshot.items():setattr(m,k,v)
variants={
 'floor30':{'floor':.3},'floor50':{'floor':.5},'floor70':{'floor':.7},'floor85':{'floor':.85},
 'valley_star_50_32_14_4':{'floor':.7,'star':[.50,.32,.14,.04,0]},
 'valley_star_45_35_15_5':{'floor':.7,'star':[.45,.35,.15,.05,0]},
 'valley_grade_reservoir':{'floor':.7,'grade':[.71,.15,.1,.03,.01]},
 'valley_general_price150':{'floor':.7,'price':1.5}}
results={}
for name,v in variants.items():
 for k,x in snapshot.items():setattr(m,k,json.loads(json.dumps(x)))
 if 'star' in v:m.STAR[1]=v['star']
 if 'grade' in v:m.GRADE[1]=v['grade']
 if 'price' in v:m.BASE[20:39]=[round(x*v['price']) for x in m.BASE[20:39]]
 rows=[m.trial(20261023+i,prices=(5,15,20),bait=0,mode='continuous',stock_floor=v['floor']) for i in range(400)]
 results[name]={'parameters':v,**m.summarize(rows)}
 r=random.Random(75076);sales=[]
 for region in range(2):
  total=0
  for j in range(100000):
   st=m.pick(r,m.STAR[region]);sp=r.choice(m.BY[st])+region*20;g=m.pick(r,m.GRADE[region]);lf=m.length(r,sp,0)
   total+=int(m.BASE[sp]*m.GM[g]*min(lf*lf,2.5)+.5)
  sales.append(total/100000)
 results[name]['full_stock_great_worm_mean_sale']=sales
 results[name]['valley_reservoir_ratio']=sales[1]/sales[0]
 (P/'results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
 print(name,results[name]['completed'],results[name].get('active_h'),sales,flush=True)
