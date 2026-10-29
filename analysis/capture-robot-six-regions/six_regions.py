"""Conditional six-region economy stress test, NOT a license completion simulator."""
import sys,pathlib,json,math,hashlib,time
import numpy as np
from functools import lru_cache
OUT=pathlib.Path(__file__).resolve().parent
sys.path.insert(0,str(OUT.parent/'capture-robot'))
from simulate import STARS,GRADES,BASE,MULT,VALLEY,GROUPS
SEED=20261030
VM=json.loads((OUT.parents[1]/'docs/analysis/valley-prices/historical/tuned8.json').read_text())['vm']
RATES=[6,9,12,16,20,24];CAPS=[10,20,30,40,50,60]

@lru_cache(None)
def dist(region,precision,scale=1,stock=1):
 starmax=min(precision,3)
 sw=np.array(STARS[0 if region==0 else 1][:starmax+1],float)
 sw*=(.04+.96*stock)**np.arange(starmax+1);sw/=sw.sum()
 gp=np.array(GRADES[0 if region==0 else 1],float);gp[0]+=gp[precision+1:].sum();gp[precision+1:]=0
 values=[];probs=[]
 for s in range(starmax+1):
  for i,k in enumerate(GROUPS[s]):
   b=VALLEY[k] if region==1 else np.linspace(*BASE[s],len(GROUPS[s]))[i]
   if region>=2:b*=VM[region]*scale
   for g in range(precision+1):values.append(math.floor(b*MULT[g]+.5));probs.append(sw[s]*gp[g]/len(GROUPS[s]))
 return np.array(values),np.array(probs)/sum(probs)
@lru_cache(None)
def mean(*args):
 v,p=dist(*args);return float(v@p)
def nice(x):
 unit=10**max(2,int(math.log10(max(x,1)))-1)
 return math.ceil(x/unit)*unit

def costs():
 # Design target, not discovered fact: 48 incremental productive hours speed/precision;
 # ten extra daily full-bin collections storage. Calibrate at full-stock central scenario.
 speed=[0];storage=[0];precision=[0]
 for region in range(1,6):
  g=min(region,3);price=mean(region,g)
  speed.append(nice((RATES[region]-RATES[region-1])*price*48))
  storage.append(nice(10*price*10))
  precision.append(nice((price-mean(region,g-1))*RATES[region-1]*48) if region<=3 else 0)
 return {'purchase':3000,'speed':speed,'storage':storage,'precision':precision}
C=costs()
OLD={'purchase':1200,'speed':[0,600,1400,3000,6000,12000],'storage':[0,300,800,1800,4000,8000],'precision':[0,1200,4000,12000,0,0]}
BIG={'purchase':3000,'speed':[0,30000,300000,3000000,30000000,100000000],'storage':[0,30000,300000,3000000,30000000,100000000],'precision':[0,30000,300000,3000000,0,0]}

def study(policy,scale,profile,pace,n=512):
 rng=np.random.default_rng(SEED)
 cash=np.zeros(n);spent=np.zeros(n);gross=np.zeros(n);manualtotal=np.zeros(n)
 owned=np.zeros(n,bool);speed=np.zeros(n,int);cap=np.zeros(n,int);prec=np.zeros(n,int)
 stages=[]
 active,work,collect={'frequent':(2,2,.5),'daily':(1,8,8),'casual':(.5,8,8)}[profile]
 # Manual activity and robot-only window are disjoint, conservatively avoid double use.
 for day in range(90):
  region=day//15;gmax=min(region,3)
  # Players get region/license externally every15days; no inferred unlock times.
  manualprice=mean(region,3,scale,.7)
  catchrate=3600/pace*.9*.65 # 90% success,65% time actually fishing vs travel/selling
  # 5 coin basic bait assumption for future regions; premium bait excluded.
  attempts=3600/pace*.65*active
  income=max(0,catchrate*active*manualprice-attempts*5)
  manualtotal+=income
  # Only25% of manual net income is available for robot; rest reserved for core progression.
  cash+=income*.25
  for idx in range(n):
   if not owned[idx] and cash[idx]>=policy['purchase']:
    cash[idx]-=policy['purchase'];spent[idx]+=policy['purchase'];owned[idx]=True
   if not owned[idx]:continue
   r=RATES[speed[idx]];b=CAPS[cap[idx]]
   count=int(r*work) if b>=r*collect else int(work/collect)*b
   v,p=dist(region,prec[idx],scale)
   reward=int(rng.multinomial(count,p)@v);cash[idx]+=reward;gross[idx]+=reward
   for unused in range(14):
    options=[]
    current=count*mean(region,prec[idx],scale)
    if speed[idx]<region:
     k=speed[idx]+1;nr=RATES[k];nc=int(nr*work) if b>=nr*collect else int(work/collect)*b
     options.append(('speed',policy['speed'][k],nc*mean(region,prec[idx],scale)-current))
    if cap[idx]<region:
     k=cap[idx]+1;nb=CAPS[k];nc=int(r*work) if nb>=r*collect else int(work/collect)*nb
     options.append(('storage',policy['storage'][k],nc*mean(region,prec[idx],scale)-current))
    if speed[idx]<region and cap[idx]<region:
     ns=speed[idx]+1;nb=cap[idx]+1;nr=RATES[ns];bc=CAPS[nb]
     nc=int(nr*work) if bc>=nr*collect else int(work/collect)*bc
     options.append(('combo',policy['speed'][ns]+policy['storage'][nb],nc*mean(region,prec[idx],scale)-current))
    if prec[idx]<gmax:
     k=prec[idx]+1;options.append(('precision',policy['precision'][k],count*(mean(region,k,scale)-mean(region,prec[idx],scale))))
    options=[o for o in options if o[2]>0 and o[1]>0]
    if not options:break
    key,cost,gain=max(options,key=lambda o:o[2]/o[1])
    if cash[idx]<cost:break
    cash[idx]-=cost;spent[idx]+=cost
    if key=='speed':speed[idx]+=1
    if key=='storage':cap[idx]+=1
    if key=='precision':prec[idx]+=1
    if key=='combo':speed[idx]+=1;cap[idx]+=1
    r=RATES[speed[idx]];b=CAPS[cap[idx]];count=int(r*work) if b>=r*collect else int(work/collect)*b
  if day%15==14:
   stages.append({'region':region+1,'day':day+1,'robot_gross_p50':float(np.median(gross)),
    'cash_p50':float(np.median(cash)),'spent_p50':float(np.median(spent)),
    'speed_level_mean':float(speed.mean()),'storage_level_mean':float(cap.mean()),'precision_level_mean':float(prec.mean()),
    'current_speed_max_fraction':float((speed==region).mean()),'manual_net_total':float(manualtotal.mean())})
 return {'scale':scale,'profile':profile,'pace':pace,'trials':n,'stages':stages}

def main():
 start=time.time();rows=[];checks=[]
 for region in range(6):
  for scale in ([1] if region<2 else [.5,1,2]):
   for stock in [1,.7,.3]:
    g=min(region,3);av=mean(region,g,scale,stock)
    row={'region':region+1,'source':'current' if region<2 else 'historical_scenario','scale':scale,'stock':stock,'robot_mean_sale':av,'rate':RATES[region],'storage':CAPS[region],
     'robot_sale_h':av*RATES[region],'daily_one_collection_sale':av*min(CAPS[region],RATES[region]*8)}
    if region:
     delta=(RATES[region]-RATES[region-1])*av
     row['speed_roi_h']={k:v['speed'][region]/delta for k,v in [('old',OLD),('inflated',BIG),('income_target',C)]}
     row['storage_roi_days']=C['storage'][region]/(10*av)
    rows.append(row)
 for name,policy in [('old',OLD),('inflated',BIG),('income_target',C)]:
  for scale in [.5,1,2]:
   for profile in ['frequent','daily','casual']:
    for pace in [20,30,45]:
     x=study(policy,scale,profile,pace);x['policy']=name;checks.append(x)
  print(name,'completed',flush=True)
 assert abs(mean(0,0)-20)<1e-8
 assert all(abs(dist(r,min(r,3))[1].sum()-1)<1e-8 for r in range(6))
 assert all(RATES[i]<=(30+10*i) for i in range(6))
 result={'seed':SEED,'historical_multipliers':VM,'costs':C,'old_costs':OLD,'inflated_costs':BIG,'economic_grid':rows,'progression_scenarios':checks,
 'trials':len(checks)*512,'simulated_days':90,'elapsed_seconds':time.time()-start,'game_changed':False}
 (OUT/'results.json').write_text(json.dumps(result,indent=2)+'\n')
 print('DONE',result['trials'],'90-day histories',result['elapsed_seconds'],flush=True)
if __name__=='__main__':main()
