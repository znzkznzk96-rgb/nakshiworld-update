"""Early-game robot vs equipment: conditional price model and timed stock simulation."""
import sys,pathlib,json,time
import numpy as np
from functools import lru_cache
OUT=pathlib.Path(__file__).resolve().parent
sys.path.insert(0,str(OUT.parent/'capture-robot-72'))
from compare import solo
from six_regions import dist,mean,STARS,GRADES,MULT,BASE,VALLEY,GROUPS
RNGSEED=20261031
@lru_cache(None)
def species_means(region):
 return np.array([np.mean([VALLEY[k] for k in group]) if region else np.mean(BASE[i]) for i,group in enumerate(GROUPS)])
def value(region,starmax,precision,stock):
 ratio=np.maximum(.7,np.minimum(1,stock))
 w=np.array(STARS[region][:starmax+1])[None,:]*(.04+.96*ratio[:,None])**np.arange(starmax+1)
 w/=w.sum(axis=1)[:,None]
 gp=np.array(GRADES[region]);gp[0]+=sum(gp[precision+1:]);gp[precision+1:]=0
 return w@species_means(region)[:starmax+1]*float(gp@np.array(MULT))

def run(region,rate,pond,regen,profile,manualstars=0,precision=0,fixed=True,n=1024,dt=1,storage=20):
 rng=np.random.default_rng(RNGSEED);stock=np.full(n,float(pond));manualtimer=np.zeros(n);pending=np.zeros(n)
 robotprogress=np.zeros(n);bag=np.zeros(n);rcount=np.zeros(n);mcount=np.zeros(n);rval=np.zeros(n);mval=np.zeros(n)
 snapshots=[]
 # A started manual fight finishes through a scheduled break; new casts wait.
 for tick in range(int(3600/dt)):
  t=tick*dt;stock=np.minimum(pond,stock+regen*dt/3600)
  active=profile=='continuous' or (profile=='mixed' and int(t//600)%2==0)
  running=manualtimer>0;manualtimer[running]-=dt
  finished=running & (manualtimer<=0)
  mcount+=finished & (pending>0);mval[finished]+=pending[finished];pending[finished]=0
  if active:
   cast=manualtimer<=0
   idx=np.where(cast)[0]
   if len(idx):
    insufficient=stock[idx]<1;stock[idx]=np.maximum(0,stock[idx]-1)
    ratio=np.minimum(1,(stock[idx]+regen*1.46/3600)/pond)
    wait=rng.uniform(2.5,5,len(idx))*np.where(insufficient & fixed,3.5,1+.6*(1-ratio))
    manualtimer[idx]=1.46+wait+rng.uniform(.8,1.2,len(idx))*(30-5.21)
    pending[idx]=value(region,manualstars,4,ratio)*(rng.random(len(idx))<.9)
  eligible=(stock>=11)&(bag<storage)
  if rate:
   robotprogress+=eligible*dt
   caught=(robotprogress>=3600/rate)&eligible
   ix=np.where(caught)[0]
   if len(ix):
    rval[ix]+=value(region,precision,precision,stock[ix]/pond)
    stock[ix]-=1;bag[ix]+=1;rcount[ix]+=1;robotprogress[ix]-=3600/rate
  if tick+1 in [int(1800/dt),int(3600/dt)]:
   snapshots.append(dict(minutes=(tick+1)*dt/60,robot_mean=float(rcount.mean()),robot_p10=float(np.quantile(rcount,.1)),robot_p90=float(np.quantile(rcount,.9)),
    manual_mean=float(mcount.mean()),robot_sale=float(rval.mean()),manual_sale=float(mval.mean()),stock=float(stock.mean()),full_fraction=float((bag==storage).mean())))
 return dict(region=region,rate=rate,pond=pond,regen=regen,profile=profile,manualstars=manualstars,precision=precision,fixed=fixed,n=n,dt=dt,storage=storage,snapshots=snapshots)

def main():
 start=time.time();rows=[]
 for region,rates,precision in [(0,[0,12,16,20,24],0),(1,[0,24,28,32,36],1)]:
  for pond,regen in [(40,30),(80,50)]:
   for profile in ['idle','mixed','continuous']:
    for rate in rates:rows.append(run(region,rate,pond,regen,profile,precision=precision,manualstars=precision))
 # Exact equal1000 budget: robot1000 vs reservoir float165+hook330=495, remainder505.
 for profile in ['mixed','continuous']:
  rows.append(run(0,0,40,30,profile,manualstars=2))
 # Current zero-stock bug versus proposed latch and time-step sensitivity.
 for fixed in [False,True]:
  for dt in [.5,2]:rows.append(run(0,12,40,30,'continuous',fixed=fixed,dt=dt))
 capacity=[]
 for region,rate,precision in [(0,12,0),(0,24,0),(1,36,1)]:
  for storage in [10,20,30,40]:
   for hours in [.5,1,2,8]:
    x=solo(rate,40,30,storage,hours,max(hours,8))
    capacity.append(dict(region=region,rate=rate,storage=storage,hours=hours,**x))
 rng=np.random.default_rng(RNGSEED);long=[]
 for region,rate,g in [(0,12,0),(0,24,0),(1,36,1)]:
  for storage in [10,20,40,60]:
   x=solo(rate,40,30,storage,8,8);v,p=dist(region,g)
   sales=rng.multinomial(x['fish']*30,p,size=4096)@v
   long.append(dict(region=region,rate=rate,storage=storage,daily_count=x['fish'],sale30_mean=float(sales.mean()),p10=float(np.quantile(sales,.1)),p90=float(np.quantile(sales,.9))))
 prices=[]
 for region,rates,costs,g in [(0,[12,16,20,24],[1000,240,360,480],0),(1,[28,32,36],[2000,3000,4000],1)]:
  for rate,cost in zip(rates,costs):
   increase=12 if rate==12 else 4
   prices.append(dict(region=region,rate=rate,cost=cost,incremental_payback_h=cost/(increase*mean(region,g))))
 assert solo(12,40,30,20,.5,8)['fish']==6
 assert solo(12,40,30,20,1,8)['fish']==12
 result=dict(rows=rows,capacity=capacity,long=long,prices=prices,elapsed_seconds=time.time()-start,manual_trials=sum(x['n'] for x in rows),sale30_trials=4096*len(long),game_applied=False)
 (OUT/'results.json').write_text(json.dumps(result,indent=2)+'\n')
 print('DONE',result['manual_trials'],result['sale30_trials'],result['elapsed_seconds'],flush=True)
if __name__=='__main__':main()
