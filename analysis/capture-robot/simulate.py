"""Proposal-only balance experiment. No game files or saves are changed.
30-day compound sale distributions + time-resolved manual/robot stock competition.
Python 3 + numpy. Reproduce: python analysis/capture-robot/simulate.py
"""
import ast, hashlib, json, pathlib, time
import numpy as np

OUT = pathlib.Path(__file__).resolve().parent
ROOT = OUT.parents[1]
SOURCE = ROOT / 'game/main.gd'
TEXT = SOURCE.read_text()
SEED = 20261029
RNG = np.random.default_rng(SEED)

def constant(name):
    line = next(x for x in TEXT.splitlines() if x.startswith('const '+name+':') or x.startswith('const '+name+' ='))
    return ast.literal_eval(line.split('=',1)[1].strip())

STARS = [constant('STAR_P'), constant('OTHER_REGION_STAR_P')]
GRADES = [constant('GRADE_P'), constant('OTHER_REGION_GRADE_P')]
BASE = constant('PRICE_BASE')
MULT = constant('PRICE_GRADE')
VALLEY = constant('VALLEY_PRICE')
GROUPS = [[0,1,2,3,4,5,6,7],[8,9,10,11,12,13],[14,15,16],[17,18]]
RATES = [6,9,12,15,18,24]
STORAGE = [10,20,40,60,90,120]

def distribution(region, stars, precision, stock_ratio=1, star_policy='inherit'):
    # Proposal: ordinary-sized fish lf=1, no forge sale multiplier, no bait,
    # no perfect bonus, no owner/mythic. Locked grade probability falls to normal.
    if star_policy == 'cap2': stars = min(stars,1)
    sw = np.array(STARS[region][:stars+1],float)
    sw *= (.04+.96*max(.7,stock_ratio))**np.arange(stars+1)
    sw /= sw.sum()
    gp = np.array(GRADES[region],float)
    gp[0] += gp[precision+1:].sum(); gp[precision+1:] = 0
    prices=[]; probs=[]
    for s in range(stars+1):
        for idx,k in enumerate(GROUPS[s]):
            base = VALLEY[k] if region else np.linspace(*BASE[s],len(GROUPS[s]))[idx]
            for g in range(precision+1):
                prices.append(int(np.floor(base*MULT[g]+.5)))
                probs.append(sw[s]*gp[g]/len(GROUPS[s]))
    return np.array(prices), np.array(probs)/sum(probs)

def solo_count(rate,storage,collect_hours,working_hours):
    # Exact for selected rates: intervals divide 1h; stock regen >=30 > max24.
    # Full storage pauses; collection of a nonfull bin preserves capture progress.
    if storage >= rate*collect_hours:
        return int(rate*working_hours)
    complete=int(working_hours//collect_hours)
    remainder=working_hours-complete*collect_hours
    return complete*min(storage,int(rate*collect_hours))+min(storage,int(rate*remainder))

def competition(rate,regen,capacity,pace,reserve,fixed,dt=2,n=512,hours=4):
    """Vector time-step model; random manual cycle, 90% catch success.
    Manual continues on empty (current game); robot requires actual stock.
    Robot timer pauses if stock <= reserve or full. Collection each 30min.
    Excludes selling/travel/bag time; stresses continuous active play.
    """
    rng=np.random.default_rng(SEED)
    stock=np.full(n,float(capacity)); mt=np.zeros(n); rt=np.zeros(n)
    manual=np.zeros(n); robot=np.zeros(n); bag=np.zeros(n)
    blocked=np.zeros(n); exhausted=np.zeros(n)
    first=np.full(n,np.nan)
    for step in range(int(hours*3600/dt)):
        t=step*dt
        stock=np.minimum(capacity,stock+regen*dt/3600)
        if step and abs(t%1800)<dt/2: bag[:]=0
        mt-=dt
        cast=mt<=0
        insufficient=stock<1
        if np.any(cast):
            idx=np.where(cast)[0]; stock[idx]=np.maximum(0,stock[idx]-1)
            empty=cast & insufficient
            first[empty & np.isnan(first)]=t/60
            exhausted+=empty
            ratio=np.minimum(1,(stock[idx]+regen*1.46/3600)/capacity)
            factor=np.where(insufficient[idx] & fixed,3.5,1+.6*(1-ratio))
            wait=rng.uniform(2.5,5,len(idx))*factor
            mt[idx]+=1.46+wait+rng.uniform(.8,1.2,len(idx))*(pace-5.21)
            manual[idx]+=rng.random(len(idx))<.9
        eligible=(stock>=reserve+1)&(bag<120)
        blocked+=~eligible
        if rate:
            rt+=np.where(eligible,dt,0)
            caught=(rt>=3600/rate)&eligible
            stock[caught]-=1; rt[caught]-=3600/rate
            bag[caught]+=1;robot[caught]+=1
    return dict(rate=rate,regen=regen,capacity=capacity,pace=pace,reserve=reserve,fixed=fixed,dt=dt,trials=n,hours=hours,
      manual_per_h=float(manual.mean()/hours),robot_per_h=float(robot.mean()/hours),
      robot_p10=float(np.quantile(robot/hours,.1)),robot_p90=float(np.quantile(robot/hours,.9)),
      blocked_percent=float(blocked.mean()/int(hours*3600/dt)*100),
      empty_casts_per_h=float(exhausted.mean()/hours),
      first_empty_minutes=float(np.nanmean(first)) if np.any(~np.isnan(first)) else None)

def main():
    started=time.time(); economics=[]; long=[]
    for region in [0,1]:
      for stars in range(4):
       for precision in range(4):
        for ratio in [1,.7]:
         values,p=distribution(region,stars,precision,ratio)
         mean=float(values@p)
         economics.append(dict(region=region,stars=stars+1,precision=precision,stock_ratio=ratio,mean_sale=mean,
           income_h=[round(mean*r,2) for r in RATES],purchase_roi_h={str(c):round(c/(6*mean),2) for c in [1200,2400,4000]}))
    print('Economics: 64 source-based distributions',flush=True)
    # 30-day trajectories: fixed unlocked stage, no reinvestment/quest payouts.
    # Full-stock vs .7 floor bounds on star value are reported separately above.
    for region,stars,precision in [(0,0,0),(0,1,0),(0,3,0),(0,3,1),(1,3,1),(1,3,2)]:
     values,p=distribution(region,stars,precision)
     for rate in RATES:
      for storage in STORAGE:
       for name,collect,work in [('online_2h',.5,2),('offline_8h',8,8),('offline_24h',24,24)]:
        daily=solo_count(rate,storage,collect,work)
        sums=RNG.multinomial(daily*30,p,size=2048)@values
        long.append(dict(region=region,stars=stars+1,precision=precision,rate=rate,storage=storage,
          profile=name,daily_catches=daily,fish30=daily*30,mean_gold30=float(sums.mean()),
          p10_gold30=float(np.quantile(sums,.1)),p90_gold30=float(np.quantile(sums,.9)),
          trials=2048))
    print('30-day histories:',len(long)*2048,flush=True)
    contested=[]
    for pace in [20,30,45]:
     for regen,cap in [(30,40),(50,80),(80,140)]:
      for rate in [0,6,12,24]:
       for reserve in ([0] if not rate else [0,10]):
        contested.append(competition(rate,regen,cap,pace,reserve,True))
    for fixed in [False,True]:
     for dt in [.5,2,5]:
      contested.append(competition(24,30,40,30,10,fixed,dt=dt,n=1024))
    print('Competition histories:',sum(x['trials'] for x in contested),flush=True)
    # Isolated size sensitivity: no bait boost, gauss .15; price scale diagnostic.
    lf=np.clip(RNG.normal(1,.15,1000000),.5,1.65)
    size_factor=float(np.minimum(lf*lf,2.5).mean())
    assert solo_count(6,10,8,8)==10 and solo_count(24,120,24,24)==120
    assert all(abs(distribution(r,s,g)[1].sum()-1)<1e-10 for r in [0,1] for s in range(4) for g in range(4))
    assert all(x['robot_per_h']<=x['rate']+.001 for x in contested)
    result=dict(seed=SEED,source_sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
       production_changed=False,simulation_days=30,economic=economics,long_horizon=long,competition=contested,
       gaussian_size_sensitivity=size_factor,elapsed_seconds=time.time()-started)
    (OUT/'results.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print('DONE',round(time.time()-started,1),'seconds',flush=True)

if __name__=='__main__': main()
