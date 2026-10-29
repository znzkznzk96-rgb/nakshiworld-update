"""40-stock sensitivity; no production gameplay changes.
Fix candidate: latch insufficient stock (<1) BEFORE consumption; last full fish
still receives normal wait. Current behavior recovers during the cast.
"""
import random,statistics,json,pathlib
OUT=pathlib.Path(__file__).parent

def run(cap,pace,seed,regen=30,fixed=False):
 r=random.Random(seed);stock=float(cap);t=0;first=None;low=None;counts={1200:0,1800:0,3600:0};left={};penalties=0
 while t<7200:
  insufficient=stock<1;stock=max(0,stock-1)
  if stock==0 and first is None:first=t/60
  stock=min(cap,stock+regen*1.46/3600);ratio=stock/cap
  if ratio<=.7 and low is None:low=t/60
  penalized=insufficient if fixed else stock<=0
  wait=r.uniform(2.5,5)*(3.5 if penalized else 1+.6*(1-ratio))
  cycle=1.46+wait+max(0,r.uniform(.8,1.2)*(pace-1.46-3.75))
  for horizon in counts:
   if t+cycle<=horizon:counts[horizon]+=1
   if t<horizon<=t+cycle:left[horizon]=min(cap,stock+regen*(horizon-t-1.46)/3600)
  if t+cycle<=1800 and penalized:penalties+=1
  stock=min(cap,stock+regen*(cycle-1.46)/3600);t+=cycle
 return dict(first_empty=first,odds_floor=low,casts20=counts[1200],casts30=counts[1800],casts60=counts[3600],stock20=left[1200],stock30=left[1800],penalized30=penalties)
rows=[]
for pace in [20,30,45]:
 for name,cap,regen,fix in [('current80',80,30,False),('capacity40',40,30,False),('capacity40_fixed',40,30,True),('expanded60_fixed',60,30,True),('regen40_fixed',40,40,True)]:
  trials=[run(cap,pace,s,regen,fix) for s in range(1000)];row=dict(case=name,cap=cap,regen=regen,pace=pace,fixed=fix)
  for key in trials[0]:
   v=[x[key] for x in trials if x[key] is not None];row[key]=round(statistics.mean(v),2) if v else None
  rows.append(row)
print(json.dumps(rows,ensure_ascii=False,indent=2));(OUT/'compare40_results.json').write_text(json.dumps(rows,indent=2)+'\n')
