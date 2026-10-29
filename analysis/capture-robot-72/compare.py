"""72/h proposal: intermediate speed prices and exact solo stock/storage events.
No gameplay modifications. Regional income imports prior explicitly conditional model.
"""
import sys,pathlib,json,math,hashlib
import numpy as np
OUT=pathlib.Path(__file__).resolve().parent
sys.path.insert(0,str(OUT.parent/'capture-robot-six-regions'))
from six_regions import mean,dist,nice,C
RATES=[6,8,10,12,15,18,22,26,30,36,42,48,54,60,66,72]
REGIONS=[0,0,0,1,1,1,2,2,2,3,3,3,4,4,5,5]

def solo(rate,pond,regen,storage,hours,collect_hours,reserve=10):
 t=0.;stock=float(pond);bag=0;total=0;progress=0.;blocked=0.;full=0.
 period=3600/rate;next_collect=collect_hours*3600;end=hours*3600
 while t<end-1e-7:
  if t>=next_collect-1e-7:
   bag=0;next_collect+=collect_hours*3600
  if bag>=storage:
   elapsed=min(end,next_collect)-t;full+=elapsed
  elif stock<reserve+1-1e-7:
   elapsed=min(end-t,next_collect-t,(reserve+1-stock)*3600/regen);blocked+=elapsed
  else:
   elapsed=min(end-t,next_collect-t,period-progress)
   progress+=elapsed
  assert elapsed>1e-9,(t,stock,bag,progress)
  stock=min(pond,stock+regen*elapsed/3600);t+=elapsed
  if progress>=period-1e-7:
   assert stock>=reserve+1-1e-6
   stock-=1;bag+=1;total+=1;progress=0.
 assert stock>=0 and total<=int(rate*hours+1e-6)
 return dict(fish=total,actual_per_h=total/hours,stock_end=stock,stock_wait_h=blocked/3600,storage_full_h=full/3600)

def main():
 rng=np.random.default_rng(20261031);prices=[];rows=[];uncertainty=[]
 for i,(rate,region) in enumerate(zip(RATES,REGIONS)):
  cost=0 if i==0 else nice((rate-RATES[i-1])*mean(region,min(region,3))*48)
  prices.append(dict(level=i,region=region+1,rate=rate,price=cost,seconds_per_fish=3600/rate))
  for scale in ([1] if region<2 else [.5,1,2]):
   for ratio in [1,.7,.3]:
    if i:uncertainty.append(dict(level=i,scale=scale,stock=ratio,payback_active_h=cost/((rate-RATES[i-1])*mean(region,min(region,3),scale,ratio))))
  for pond,regen in [(40,30),(80,50),(140,80)]:
   for storage in [10,60]:
    for hours,collect in [(2,.5),(8,8),(24,.5)]:
     result=solo(rate,pond,regen,storage,hours,collect)
     # 30 repeated identical days, ample recovery between the2h/8h sessions.
     # 24h session is a throughput stress, not a repeated-full-stock30day claim.
     row=dict(level=i,region=region+1,rate=rate,pond=pond,regen=regen,storage=storage,hours=hours,collect_h=collect,**result)
     if hours!=24:
      v,p=dist(region,min(region,3),1,1)
      totals=rng.multinomial(result['fish']*30,p,size=2048)@v
      row.update(sale30_mean=float(totals.mean()),sale30_p10=float(np.quantile(totals,.1)),sale30_p90=float(np.quantile(totals,.9)),trials=2048)
     rows.append(row)
 # Independent closed-form conservation and unconstrained checks.
 assert solo(72,140,80,60,2,.5)['fish']==144
 assert solo(72,140,80,60,8,8)['fish']==60
 assert solo(6,40,30,10,8,8)['fish']==10
 for x in rows:
  assert x['fish']<=math.floor(x['pond']+x['regen']*x['hours']+1e-6)
 out=dict(prices=prices,rows=rows,sensitivity=uncertainty,purchase_price=3000,
  speed_cost_sum=sum(x['price'] for x in prices),other_upgrade_costs=C,
  model='solo stock event simulation; future regional prices conditional; no manual concurrency',
  revenue_30day_histories=sum(x.get('trials',0) for x in rows),game_applied=False)
 (OUT/'results.json').write_text(json.dumps(out,indent=2)+'\n')
 print('DONE',len(rows),'stock scenarios',out['revenue_30day_histories'],'30-day revenue draws')
 print('prices',[(x['rate'],x['price']) for x in prices])
 for x in rows:
  if x['rate']==72 and x['storage']==60:print('MAX',x['pond'],x['regen'],x['hours'],x['fish'],round(x['actual_per_h'],2))
if __name__=='__main__':main()
