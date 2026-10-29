"""Stock-only event simulation. Full-stock cycle times are assumptions, not telemetry."""
import random,statistics,json,pathlib
OUT=pathlib.Path(__file__).parent

def run(cap,pace,seed,regen=30,horizon=7200):
 r=random.Random(seed);stock=float(cap);t=0;first=None;floor=None;casts=0;at20=None;at30=0;val30=0
 while t<horizon:
  before=stock;stock=max(0,stock-1)
  if stock==0 and first is None:first=t/60
  stock=min(cap,stock+regen*1.46/3600)
  ratio=stock/cap
  if ratio<=.7 and floor is None:floor=t/60
  wait=r.uniform(2.5,5)*(3.5 if stock<=0 else 1+.6*(1-ratio))
  cycle=1.46+wait+max(0,r.uniform(.8,1.2)*(pace-1.46-3.75))
  effective=max(.7,ratio);w=[p*(.04+.96*effective)**i for i,p in enumerate([.45,.35,.15,.05])]
  value=sum(p*v for p,v in zip(w,[20,85,275,1250]))/sum(w)
  if t+cycle<=1800:at30+=1;val30+=value
  if at20 is None and t+cycle>=1200:at20=min(cap,stock+regen*(1200-t-1.46)/3600)
  stock=min(cap,stock+regen*(cycle-1.46)/3600);t+=cycle;casts+=1
 return {'depleted_min':first,'floor70_min':floor,'stock20':at20,'casts30':at30,'value30':val30}
rows=[]
for pace in [20,30,45]:
 for cap in [80,60,40,30,20]:
  a=[run(cap,pace,s) for s in range(1000)]
  d={'capacity':cap,'full_stock_cycle_s':pace,'runs':len(a),'refill_min':cap/30*60}
  for k in a[0]:
   vals=[v[k] for v in a if v[k] is not None];d[k]=round(statistics.mean(vals),2) if vals else None
  vals=sorted(v['depleted_min'] for v in a if v['depleted_min'] is not None);d['depleted_p10_p90']=[round(vals[int((len(vals)-1)*p)],2) for p in [.1,.9]] if vals else None
  rows.append(d)
for pace in [20,30,45]:
 base=next(x['value30'] for x in rows if x['capacity']==80 and x['full_stock_cycle_s']==pace)
 for x in rows:
  if x['full_stock_cycle_s']==pace:x['gross_value_index_vs80']=round(x['value30']/base*100,1)
(OUT/'results.json').write_text(json.dumps({'assumptions':{'regen_h':30,'full_stock_cycle_s':[20,30,45],'cast_seconds':1.46,'bite_uniform_s':[2.5,5],'early_region_odds_floor':.7,'horizon_s':7200,'seeds':1000,'income_proxy':'fixed four-star-unlocked reservoir, equal success/grade/length, base-price expectation; not net income or progression'},'cases':rows},indent=2)+'\n')
for x in rows:print(x)
