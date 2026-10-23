"""Economic Monte Carlo, NOT a Godot combat bot. See REPORT.md for policy assumptions."""
import ast, hashlib, json, math, pathlib, random, re, statistics, time
import numpy as np
OUT=pathlib.Path(__file__).parent
SNAPSHOT=json.loads((OUT/'baseline_constants.json').read_text())
globals().update(SNAPSHOT)
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

def trial(seed,prices=(5,15,20),bait=0,mode='daily',success=.85,cycle=30,aquarium=True,invest=True,stock_floor=.7,target=104000,session_hours=2,interval_hours=24,expand20=False,exhibit_owner=False,offline_cap_hours=8,first_unlock=6600):
 r=random.Random(seed);gold=0.;stock=80.;cap=80.;regen=30.;area=0;parts=[0,0];gauges=[0.,0.];baglv=0;bag=[];bagw=0.;aqua=[];aqcap=3;aqexpanded=False;rodbought=False;caplv=reglv=0
 main=[set(),set()];sub=[set(),set()];sv=[0,0];owner_done=[False,False]
 active=elapsed=0.;online_income=offline_income=0.;casts=0;session=0.;bait_spent=0.;sale=reward=passive=expense=0.;bare=0;owners=0;valley=None;money_ready=None;lic_ready=None;low=0
 def advance(sec,on=True):
  nonlocal active,elapsed,stock,gold,passive,session,online_income,offline_income
  elapsed+=sec
  if on:active+=sec;session+=sec
  credited=sec if on else min(sec,offline_cap_hours*3600)
  stock=min(cap,stock+regen*(sec if on else min(sec,28800))/3600)
  gain=sum(x[0] for x in aqua)/300*credited/60
  if not on:gain=math.floor(gain) # game floors each offline claim
  gold+=gain;passive+=gain
  if on:online_income+=gain
  else:offline_income+=gain
 def visit():
  nonlocal gold,bag,bagw,sale,reward,expense,parts,reglv,regen,caplv,cap,baglv,rodbought,aqcap,aqexpanded,area,valley,lic_ready,money_ready
  advance(30)
  for sp,g,lf,pr,w,owner in bag:
   ar=sp//20
   if sp in MAIN[ar] and sp not in main[ar]:main[ar].add(sp)
   elif sp in SUB[ar] and sp not in sub[ar]:
    sub[ar].add(sp);sv[ar]+=pr
    if len(sub[ar])==6:gold+=math.floor(sv[ar]*1.2+.5);reward+=math.floor(sv[ar]*1.2+.5)
   elif owner and not owner_done[ar] and not exhibit_owner:gold+=math.floor(pr*1.5+.5);reward+=math.floor(pr*1.5+.5);owner_done[ar]=True
   elif aquarium and (len(aqua)<aqcap or any(pr>x[0]*1.2 and x[1]<=BAGCAP[baglv] for x in aqua)):
    if len(aqua)>=aqcap:
     old=min((x for x in aqua if x[1]<=BAGCAP[baglv]),key=lambda x:x[0]);aqua.remove(old);gold+=old[0];sale+=old[0]
    aqua.append((pr,w)) # use this fish weight, not last-catch closure variable
   else:gold+=pr;sale+=pr
  bag=[];bagw=0.
  # Goal is eligibility + funds, never actual entry into unimplemented region.
  if area==1 and gold>=target and money_ready is None:money_ready=elapsed/3600
  if area==1 and len(main[1])==6 and lic_ready is None:lic_ready=elapsed/3600
  if area==1 and len(main[1])==6 and gold>=target:return True
  if area==0 and len(main[0])==6 and gold>=first_unlock:
   gold-=first_unlock;expense+=first_unlock;area=1;valley=[active/3600,elapsed/3600,casts]
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
   if aquarium and expand20 and aqcap in [6,10,15]:
    nextcap,cost={6:(10,900),10:(15,2400),15:(20,6000)}[aqcap]
    if gold>=cost+1000:gold-=cost;expense+=cost;aqcap=nextcap
  return False
 for _ in range(7000):
  if elapsed>24*90*3600:break
  if session>=session_hours*3600:
   if bag and visit():break
   advance(max(0,interval_hours*3600-session),False);session=0
   # Claim login income and check goals/purchases before another cast.
   if visit():break
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
 done=area==1 and len(main[1])==6 and gold>=target
 return dict(day=int(elapsed//86400)+1,online_income=online_income,offline_income=offline_income,aqua_capacity=aqcap,aqua_value=sum(x[0] for x in aqua),done=done,active_h=active/3600,elapsed_h=elapsed/3600,casts=casts,valley=valley,bait_spent=bait_spent,sales=sale,rewards=reward,passive=passive,upgrades_and_region=expense,bare_casts=bare,owners=owners,low_stock_fraction=low/max(1,casts),gold=gold,license_h=lic_ready,money_h=money_ready)

def summarize(rows):
 done=[x for x in rows if x['done']]
 out={'runs':len(rows),'completed':len(done),'completion_rate':len(done)/len(rows)}
 for k in ['day','online_income','offline_income','aqua_capacity','aqua_value','active_h','elapsed_h','casts','bait_spent','sales','rewards','passive','upgrades_and_region','bare_casts','owners','low_stock_fraction','gold','license_h','money_h']:
  a=[x[k] for x in done if x[k] is not None]
  if a:out[k]={'p10':round(float(np.quantile(a,.1)),3),'median':round(float(np.median(a)),3),'p90':round(float(np.quantile(a,.9)),3),'mean':round(float(np.mean(a)),3)}
 for idx,k in enumerate(['valley_active_h','valley_elapsed_h','valley_casts']):
  a=[x['valley'][idx] for x in done if x['valley']]
  if a:out[k]={'p10':round(float(np.quantile(a,.1)),3),'median':round(float(np.median(a)),3),'p90':round(float(np.quantile(a,.9)),3)}
 out['censored_median_active_h']=round(float(np.median([x['active_h'] for x in rows if not x['done']])),3) if len(done)<len(rows) else None
 out['bait_share_of_inflow']=round(sum(x['bait_spent'] for x in done)/max(1,sum(x['sales']+x['rewards']+x['passive'] for x in done)),4)
 out['aquarium_share_of_inflow']=sum(x['passive'] for x in done)/max(1,sum(x['sales']+x['rewards']+x['passive'] for x in done))
 out['day_counts']={str(day):sum(x['day']==day for x in done) for day in sorted({x['day'] for x in done})}
 out['money_before_license_fraction']=round(sum(x['money_h'] is not None and x['license_h'] is not None and x['money_h']<x['license_h'] for x in done)/max(1,len(done)),4)
 return out


