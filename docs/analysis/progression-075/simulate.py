"""Economic Monte Carlo, NOT a Godot combat bot. See REPORT.md for policy assumptions."""
import ast, hashlib, json, math, pathlib, random, re, statistics, time
import numpy as np
ROOT=pathlib.Path(__file__).resolve().parents[3]
OUT=pathlib.Path(__file__).parent
M=(ROOT/'game/main.gd').read_text();V=(ROOT/'game/village.gd').read_text();C=(ROOT/'game/addons/reservoir/regional_catalog.gd').read_text();P=(ROOT/'game/addons/reservoir/regional_progress.gd').read_text();B=(ROOT/'game/addons/reservoir/region_shop.gd').read_text()
def const(src,key):
 s=re.search(r'^const '+key+r'\s*:?\s*=\s*(\[[^\n]+\])',src,re.M).group(1)
 return ast.literal_eval(s)
STAR=[const(M,'STAR_P'),const(M,'OTHER_REGION_STAR_P')];GRADE=[const(M,'GRADE_P'),const(M,'OTHER_REGION_GRADE_P')]
BY=const(C,'BY_STAR');MEAN=const(C,'MEANS');MAX=[min(150,x*1.65) for x in MEAN[:20]]+const(C,'VALLEY_MAX')
BASE=[]
for s,indices in enumerate(BY):
 lo,hi=const(M,'PRICE_BASE')[s]
 BASE.extend([lo+(hi-lo)*j/max(1,len(indices)-1) for j in range(len(indices))])
BASE+=const(M,'VALLEY_PRICE');GM=const(M,'PRICE_GRADE');WM=const(M,'W_GRADE');WB=const(M,'W_BASE')
MAIN=const(P,'MAIN_SPECIES');SUB=const(P,'SUB_SPECIES');BAGCAP=const(M,'BAG_CAP');BAGPRICE=const(M,'BAG_PRICE')
def pick(r,w):
 x=r.random()*sum(w)
 for i,v in enumerate(w):
  x-=v
  if x<0:return i
 return len(w)-1
def length(r,sp,bait,owner=False):
 def one():
  if sp<20 and bait!=1 and not owner:return min(MAX[sp]/MEAN[sp],max(.5,min(1.65,r.gauss(1,.15))))
  for _ in range(64):
   x=r.gauss(1,.15)
   if .5<=x<MAX[sp]/MEAN[sp]:return x
  return 1.
 x=one()
 return max(x,one()) if bait==1 else x

def trial(seed,prices=(1,6,8),bait=0,mode='rest',success=.85,cycle=30,aquarium=True,invest=True,stock_floor=None):
 r=random.Random(seed);gold=0.;stock=80.;cap=80.;regen=30.;area=0;parts=[0,0];gauges=[0.,0.];baglv=0;bag=[];bagw=0.;aqua=[];aqcap=3;aqexpanded=False;rodbought=False;caplv=reglv=0
 main=[set(),set()];sub=[set(),set()];sv=[0,0];owner_done=[False,False]
 active=elapsed=0.;casts=0;session=0.;bait_spent=0.;sale=reward=passive=expense=0.;bare=0;owners=0;valley=None;money_ready=None;lic_ready=None;low=0
 def advance(sec,on=True):
  nonlocal active,elapsed,stock,gold,passive,session
  elapsed+=sec
  if on:active+=sec;session+=sec
  stock=min(cap,stock+regen*min(sec,28800)/3600)
  gain=sum(x[0] for x in aqua)/300*min(sec,28800)/60
  gold+=gain;passive+=gain
 def visit():
  nonlocal gold,bag,bagw,sale,reward,expense,parts,reglv,regen,caplv,cap,baglv,rodbought,aqcap,aqexpanded,area,valley,lic_ready,money_ready
  advance(30)
  for sp,g,lf,pr,w,owner in bag:
   ar=sp//20
   if sp in MAIN[ar] and sp not in main[ar]:main[ar].add(sp)
   elif sp in SUB[ar] and sp not in sub[ar]:
    sub[ar].add(sp);sv[ar]+=pr
    if len(sub[ar])==6:gold+=math.floor(sv[ar]*1.2+.5);reward+=math.floor(sv[ar]*1.2+.5)
   elif owner and not owner_done[ar]:gold+=math.floor(pr*1.5+.5);reward+=math.floor(pr*1.5+.5);owner_done[ar]=True
   elif aquarium and (len(aqua)<aqcap or any(pr>x[0]*1.2 and x[1]<=BAGCAP[baglv] for x in aqua)):
    if len(aqua)>=aqcap:
     old=min((x for x in aqua if x[1]<=BAGCAP[baglv]),key=lambda x:x[0]);aqua.remove(old);gold+=old[0];sale+=old[0]
    aqua.append((pr,wt))
   else:gold+=pr;sale+=pr
  bag=[];bagw=0.
  # Goal is eligibility + funds, never actual entry into unimplemented region.
  if area==1 and gold>=52000 and money_ready is None:money_ready=elapsed/3600
  if area==1 and len(main[1])==6 and lic_ready is None:lic_ready=elapsed/3600
  if area==1 and len(main[1])==6 and gold>=52000:return True
  if area==0 and len(main[0])==6 and gold>=3300:
   gold-=3300;expense+=3300;area=1;valley=[active/3600,elapsed/3600,casts]
  costs=[165,330,594,990] if area==0 else [170,330,590,990]
  while parts[area]<4 and gold>=costs[parts[area]]+20:
   c=costs[parts[area]];gold-=c;expense+=c;parts[area]+=1
  if invest:
   if reglv<2 and gold>=[250,700][reglv]+100:
    c=[250,700][reglv];gold-=c;expense+=c;reglv+=1;regen+=10
   if caplv<1 and gold>=400:gold-=300;expense+=300;caplv+=1;cap+=20
   if baglv<2 and gold>=BAGPRICE[baglv+1]+100:
    baglv+=1;gold-=BAGPRICE[baglv];expense+=BAGPRICE[baglv]
   if not rodbought and gold>=2500:gold-=2000;expense+=2000;rodbought=True
   if aquarium and not aqexpanded and gold>=800:gold-=300;expense+=300;aqcap=6;aqexpanded=True
  return False
 for _ in range(7000):
  if elapsed>24*90*3600:break
  if mode=='sessions' and session>=1200:
   if bag and visit():break
   advance(max(0,4*3600-session),False);session=0
  if mode=='rest' and stock<cap*.5:
   if bag and visit():break
   advance((cap-stock)/regen*3600,False);session=0
  used=bait if gold>=prices[bait] else (0 if gold>=prices[0] else -1)
  if used<0:bare+=1
  else:gold-=prices[used];bait_spent+=prices[used]
  casts+=1;stock=max(0,stock-1);ratio=stock/cap
  if ratio<.3:low+=1
  eff=max(ratio,stock_floor) if stock_floor is not None else ratio
  w=[v*(.04+.96*eff)**i*(.1 if used<0 and i else 1) if i<=min(parts[area],3) else 0 for i,v in enumerate(STAR[area])]
  if stock<=0 and stock_floor is None:w=[1,0,0,0,0]
  star=pick(r,w);sp=r.choice(BY[star])+20*area
  mult=1.5 if used==2 else (.85 if used<0 else 1.)
  grade=pick(r,[p*mult**i for i,p in enumerate(GRADE[area])])
  # 30% PERFECT / 60% GREAT / 10% MISS; MISS downgrades but still fights.
  hook=r.random()
  if hook<.3 and r.random()<.2:grade=min(4,grade+1)
  elif hook>=.9:grade=max(0,grade-1)
  owner=parts[area]==4 and gauges[area]>=100 and hook<.9
  if owner:star=4;sp=area*20+19
  lf=length(r,sp,used,owner)
  advance(cycle + 3.75*((1.5 if used<0 else 1)*(3.5 if stock<=0 else 1+.6*(1-ratio))-1)+(3 if owner else 0))
  if r.random()>success:
   if owner:gauges[area]=70
   continue
  if owner:gauges[area]=0;owners+=1
  elif parts[area]==4:gauges[area]=min(100,gauges[area]+(3 if grade==4 else 2 if grade==3 else 1))
  pr=math.floor(BASE[sp]*GM[grade]*min(lf*lf,2.5)+.5);wt=WB[star]*lf**3*WM[grade]
  bag.append((sp,grade,lf,pr,wt,owner));bagw+=wt
  if bagw>=BAGCAP[baglv]*.9 or len(bag)>=12:
   if visit():break
 else:pass
 done=area==1 and len(main[1])==6 and gold>=52000
 return dict(done=done,active_h=active/3600,elapsed_h=elapsed/3600,casts=casts,valley=valley,bait_spent=bait_spent,sales=sale,rewards=reward,passive=passive,upgrades_and_region=expense,bare_casts=bare,owners=owners,low_stock_fraction=low/max(1,casts),gold=gold,license_h=lic_ready,money_h=money_ready)

def summarize(rows):
 done=[x for x in rows if x['done']]
 out={'runs':len(rows),'completed':len(done),'completion_rate':len(done)/len(rows)}
 for k in ['active_h','elapsed_h','casts','bait_spent','sales','rewards','passive','upgrades_and_region','bare_casts','owners','low_stock_fraction','gold','license_h','money_h']:
  a=[x[k] for x in done if x[k] is not None]
  if a:out[k]={'p10':round(float(np.quantile(a,.1)),3),'median':round(float(np.median(a)),3),'p90':round(float(np.quantile(a,.9)),3),'mean':round(float(np.mean(a)),3)}
 for idx,k in enumerate(['valley_active_h','valley_elapsed_h','valley_casts']):
  a=[x['valley'][idx] for x in done if x['valley']]
  if a:out[k]={'p10':round(float(np.quantile(a,.1)),3),'median':round(float(np.median(a)),3),'p90':round(float(np.quantile(a,.9)),3)}
 out['censored_median_active_h']=round(float(np.median([x['active_h'] for x in rows if not x['done']])),3) if len(done)<len(rows) else None
 out['bait_share_of_inflow']=round(sum(x['bait_spent'] for x in done)/max(1,sum(x['sales']+x['rewards']+x['passive'] for x in done)),4)
 out['money_before_license_fraction']=round(sum(x['money_h'] is not None and x['license_h'] is not None and x['money_h']<x['license_h'] for x in done)/max(1,len(done)),4)
 return out

def mainrun():
 cases=[]
 for mode in ['rest','sessions','continuous']:
  for bait in range(3):cases.append((f'current_{mode}_bait{bait}',dict(mode=mode,bait=bait)))
 for bait in range(3):cases.append((f'price_5_20_35_rest_bait{bait}',dict(mode='rest',bait=bait,prices=(5,20,35))))
 for success in [.65,.98]:cases.append((f'success_{success}_rest',dict(success=success)))
 for cycle in [20,45]:cases.append((f'cycle_{cycle}_rest',dict(cycle=cycle)))
 cases.extend([('no_aquarium_rest',dict(aquarium=False)),('no_invest_rest',dict(invest=False)),('candidate_stock_floor70_continuous',dict(mode='continuous',stock_floor=.7))])
 
 for bait in range(3):
  cases.append((f'price_5_15_20_rest_bait{bait}',dict(mode='rest',bait=bait,prices=(5,15,20))))
  cases.append((f'price_5_15_20_floor70_continuous_bait{bait}',dict(mode='continuous',bait=bait,prices=(5,15,20),stock_floor=.7)))
 results=json.loads((OUT/'results.json').read_text())['cases'] if (OUT/'results.json').exists() else {};N=400
 for name,kw in cases:
  if name in results:continue # reuse unchanged completed cases; delete results.json for full rerun
  rows=[trial(20261023+i,**kw) for i in range(N)]
  results[name]={'parameters':kw,**summarize(rows)}
  print(name,json.dumps({k:results[name].get(k) for k in ['completed','active_h','elapsed_h','bait_share_of_inflow','money_before_license_fraction']},ensure_ascii=False),flush=True)
 (OUT/'results.json').write_text(json.dumps({'seed_start':20261023,'runs_per_case':N,'max_casts':7000,'max_elapsed_days':90,'cases':results},ensure_ascii=False,indent=2)+'\n')
 # Conditional expected return, separate from progression: 100k catches / region / bait / stock.
 if (OUT/'bait_expected.json').exists():return
 rows=[];r=random.Random(75)
 for area in range(2):
  for stock in [1.,.5,.3]:
   for bait in range(3):
    total=0;w=[p*(.04+.96*stock)**i for i,p in enumerate(STAR[area])]
    for j in range(100000):
     star=pick(r,w);sp=r.choice(BY[star])+area*20;g=pick(r,[p*(1.5 if bait==2 else 1)**i for i,p in enumerate(GRADE[area])]);lf=length(r,sp,bait)
     total+=math.floor(BASE[sp]*GM[g]*min(lf*lf,2.5)+.5)
    ev=total/100000;rows.append(dict(region=area,stock=stock,bait=bait,mean_sale=round(ev,3),current_bait_share=round([1,6,8][bait]/ev,4),candidate_bait_share=round([5,20,35][bait]/ev,4)))
 (OUT/'bait_expected.json').write_text(json.dumps(rows,indent=2)+'\n')
 source=['game/main.gd','game/village.gd','game/addons/reservoir/regional_catalog.gd','game/addons/reservoir/regional_progress.gd','game/addons/reservoir/region_shop.gd','game/addons/reservoir/spot_selection.gd']
 (OUT/'PROVENANCE.json').write_text(json.dumps({'baseline':'v0.75','source_commit':'20911202cbb3ac8beca3706df3ec5c71a0fe46bb','work_head_before_analysis':'386a19f4e5411a149de34382c72374c5586eafb8','source_zip_sha256':'994847b57f071a62280e49df1ac1d95f5cfd9a91b2e228db31e63222df333bbb','files':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in source}},indent=2)+'\n')
if __name__=='__main__':mainrun()
