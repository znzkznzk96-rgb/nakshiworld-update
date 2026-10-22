"""Price sensitivity only; not a progression/fight/owner-frequency simulation."""
import json, pathlib, numpy as np, hashlib
ROOT=pathlib.Path(__file__).parent
rng=np.random.default_rng(20261022)
n=1_000_000
names=['버들치','쉬리','조약돌고기','나뭇잎꼬리','오름피라미','물방울송사리','거꾸로미꾸리','이끼붕어','산천어','송어','열목어','폭포오름잉어','구름피라미','돌등고기','무지개송어','황쏘가리','하늘연어','거꾸로잉어','구름메기','배후의 산천어']
stars=np.array([0]*8+[1]*6+[2]*3+[3]*2+[4])
# Mean preserves historical star averages (~0.12% rounding deviation at star3).
balanced=np.array([30,45,55,60,40,35,65,70,160,180,220,280,190,245,600,700,760,2800,3450,20000])
choices={'conservative':np.floor(balanced*.8/5+.5)*5,'balanced':balanced,'generous':np.floor(balanced*1.2/5+.5)*5}
base=np.concatenate([np.linspace(10,30,8),np.linspace(50,120,6),np.linspace(200,350,3),[1000,1500,8000]])
means=np.array([10,12,20,20,11,6,12,18,35,50,55,60,15,30,60,50,80,100,140,180])
maximum=np.array([18,22,35,35,20,10,22,32,60,85,95,105,28,55,100,85,140,180,240,300])
grade_mult=np.array([1,1.3,1.7,2.2,3.])
raw_gp=np.array([.8653,.0661,.0628,.0042,.0016])
starw=np.array([.62,.27,.09,.018,0.])
results=[]
for parts,stock in [(0,1.),(1,1.),(2,1.),(3,1.),(3,.3),(3,0.)]:
 w=starw*(.04+.96*stock)**np.arange(5);w[np.arange(5)>min(parts,3)]=0
 if stock==0:w=np.array([1.,0,0,0,0])
 ss=rng.choice(5,n,p=w/w.sum())
 sp=np.zeros(n,dtype=int)
 for star in range(4):
  ii=np.flatnonzero(ss==star);sp[ii]=rng.choice(np.flatnonzero(stars==star),len(ii))
 lf=rng.normal(1,.15,n)
 bad=(lf<.5)|(lf>=maximum[sp]/means[sp])
 while bad.any():
  lf[bad]=rng.normal(1,.15,bad.sum());bad=(lf<.5)|(lf>=maximum[sp]/means[sp])
 for baitcost,baitmult in [(10,1.),(60,1.25)]:
  gp=raw_gp*baitmult**np.arange(5);gp/=gp.sum()
  grade=rng.choice(5,n,p=gp)
  # Explicit neutral-hook assumption: all GREAT, no grade promotions/demotions.
  common=grade_mult[grade]*np.minimum(lf*lf,2.5)
  for key,prices in {'current_no_region_multiplier':base,**choices}.items():
   sales=np.floor(prices[sp]*common+.5)
   results.append({'parts':parts,'stock_ratio':stock,'bait_cost':baitcost,'candidate':key,'mean_sale':round(float(sales.mean()),3),'mean_sale_less_one_bait':round(float(sales.mean()-baitcost),3)})
sub=[0,3,5,2,12,16]
owner=[]
for key,p in choices.items():
 owner.append({'candidate':key,'base_owner':int(p[19]),'owner_normal_donation':round(float(p[19]*1.5)),'owner_mythic_donation':round(float(p[19]*3*1.5)),'side_normal_average_size_donation':round(float(p[sub].sum()*1.2))})
rows=[{'star':int(stars[i]+1),'species':name,'current_nominal':int(np.floor(base[i]+.5)),**{k:int(v[i]) for k,v in choices.items()}} for i,name in enumerate(names)]
out={'seed':20261022,'draws_per_cohort':n,'cohorts':6,'bait_profiles':2,'nominal_definition':'normal grade, mean species length, enhancement+0','assumptions':['Prices conditional on successful landing; allGREAT hook assumed; no fight loss','Current star weights and pond-stock gating; uniform species within star','Current grade odds tilted by bait multiplier; truncated normal length relative to species mean','No owner frequency included; owner accumulation rule unapproved','No aquarium income, donations, cleaning diversion, journey times or progression days in net-per-landed-fish metric','Current source uses identical regional slot prices, without legacy2.5 multiplier'],'species':rows,'price_sensitivity':results,'bundle_examples':owner}
(ROOT/'results.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
print('SPECIES')
for row in rows:print(row)
print('FULL STOCK WORM:')
for r in results:
 if r['stock_ratio']==1 and r['bait_cost']==10:print(r)
print('FULL STOCK ALL PARTS BOTH BAITS:')
for r in results:
 if r['stock_ratio']==1 and r['parts']==3:print(r)
print('BUNDLES',owner)
