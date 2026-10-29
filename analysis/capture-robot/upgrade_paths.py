"""30-day self-funded upgrade experiment, fixed region/license; no manual income.
Compares cheap/base/expensive prices, capacity ceilings, and purchase ordering.
"""
import json,time
import numpy as np
from simulate import OUT,distribution,solo_count,RATES,SEED

BUY=1200
SPEED_COST=[600,1400,3000,6000,12000]
CAP_COST=[300,800,1800,4000,8000]
PRECISION_COST=[1200,4000,12000]
CAPS={60:[10,20,30,40,50,60],120:[10,20,40,60,90,120]}

def main():
 start=time.time(); rows=[]; roi=[]
 for region in [0,1]:
  for precision in range(4):
   vals,p=distribution(region,precision,precision)
   avg=float(vals@p)
   roi.append(dict(region=region,precision=precision,stars=precision+1,mean_sale=avg,
    hourly=[round(r*avg,2) for r in RATES],speed_payback_h=[round(c/((RATES[i+1]-RATES[i])*avg),2) for i,c in enumerate(SPEED_COST)]))
 for region in [0,1]:
  maxprec=region+1  # first / second existing regional completion license
  for capmax in [60,120]:
   caps=CAPS[capmax]
   for factor in [.5,1,2]:
    for profile,collect,work in [('online_2h',.5,2),('offline_8h',8,8)]:
     for policy in ['speed_first','storage_first','marginal_roi']:
      rng=np.random.default_rng(SEED); gross=[];banks=[];final=[]; repay=[]
      values={g:distribution(region,g,g) for g in range(maxprec+1)}
      means={g:float(v@p) for g,(v,p) in values.items()}
      def income(s,b,g):return solo_count(RATES[s],caps[b],collect,work)*means[g]
      for trial in range(256):
       s=b=g=0; money=0.;total=0.;paid=None
       for day in range(1,31):
        count=solo_count(RATES[s],caps[b],collect,work)
        v,p=values[g]; reward=int(rng.multinomial(count,p)@v)
        total+=reward;money+=reward
        if paid is None and total>=BUY*factor:paid=day
        # At each collection buy affordable upgrades; ROI policy rejects zero gain.
        for _ in range(13):
         candidates=[]
         current=income(s,b,g)
         if s<5:candidates.append(('speed',SPEED_COST[s]*factor,income(s+1,b,g)-current))
         if b<5:candidates.append(('storage',CAP_COST[b]*factor,income(s,b+1,g)-current))
         if g<maxprec:candidates.append(('precision',PRECISION_COST[g]*factor,income(s,b,g+1)-current))
         if not candidates:break
         if policy=='marginal_roi':
          candidates=[x for x in candidates if x[2]>0]
          if not candidates:break
          choice=max(candidates,key=lambda x:x[2]/x[1])
         else:
          order=['speed','storage','precision'] if policy=='speed_first' else ['storage','precision','speed']
          choice=min(candidates,key=lambda x:order.index(x[0]))
         key,cost,delta=choice
         if money<cost:break
         money-=cost
         if key=='speed':s+=1
         elif key=='storage':b+=1
         else:g+=1
       gross.append(total);banks.append(money);final.append((s,b,g));repay.append(paid or 31)
      rows.append(dict(region=region,license_cap=maxprec,capacity_ceiling=capmax,price_scale=factor,profile=profile,policy=policy,trials=256,
        gross30=float(np.mean(gross)),gross_p10=float(np.quantile(gross,.1)),gross_p90=float(np.quantile(gross,.9)),cash30=float(np.mean(banks)),
        mean_final_levels=np.mean(final,axis=0).tolist(),gross_purchase_payback_day=float(np.mean(repay))))
 result=dict(base_purchase=BUY,speed_cost=SPEED_COST,storage_cost=CAP_COST,precision_cost=PRECISION_COST,storage_options=CAPS,
   precision_economics=roi,paths=rows,trials=len(rows)*256,elapsed_seconds=time.time()-start)
 (OUT/'upgrade_results.json').write_text(json.dumps(result,indent=2)+'\n')
 print('DONE',len(rows),'paths',len(rows)*256,'30-day histories',round(time.time()-start,1),'seconds')
if __name__=='__main__':main()
