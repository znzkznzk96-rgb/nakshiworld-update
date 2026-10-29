"""Current reservoir six-species main bundle +6600 entry fee; no10R gate.
Conditional playtime, not wall-clock prediction; robot online12/h average9/h under competition.
"""
import pathlib,json,sys
import numpy as np
P=pathlib.Path(__file__).resolve().parent
sys.path.insert(0,str(P.parent/'capture-robot-six-regions'))
from six_regions import STARS,GRADES,MULT,BASE,GROUPS
TARGET=[1,3,8,9,14,17];COST=[165,330,594];N=10000

def sim(policy,seconds,spending):
 rng=np.random.default_rng(20261030);gold=np.zeros(N);parts=np.zeros(N,int);owned=np.zeros(N,bool);donated=np.zeros((N,6),bool);finish=np.zeros(N);robotclock=np.zeros(N);robocount=np.zeros(N);rcost=1000;purchase=np.zeros(N)
 # same low-stock odds floor as actual early regions, all grades eligible for grade0 targets.
 sws=[]
 for p in range(4):
  w=np.array(STARS[0][:p+1])*(.04+.96*.7)**np.arange(p+1);sws.append(np.cumsum(w/w.sum()))
 price=[np.linspace(*BASE[i],len(GROUPS[i])) for i in range(4)]
 for step in range(1,2501):
  active=finish==0
  if not active.any():break
  # Successful catches every seconds: includes failure/bag/market time in pace assumption.
  u=rng.random(N);star=np.zeros(N,int)
  for p in range(4):star[parts==p]=np.searchsorted(sws[p],u[parts==p])
  sp=np.zeros(N,int);base=np.zeros(N)
  for s in range(4):
   ids=np.where(star==s)[0];k=rng.integers(0,len(GROUPS[s]),len(ids));sp[ids]=np.array(GROUPS[s])[k];base[ids]=price[s][k]
  grade=rng.choice(5,N,p=GRADES[0]);lf=np.clip(rng.normal(1,.15,N),.5,1.65)
  vals=np.floor(base*np.array(MULT)[grade]*np.minimum(lf*lf,2.5)+.5)
  give=(sp[:,None]==TARGET)&~donated&active[:,None];keep=give.any(axis=1);donated|=give
  # spending: budget diverted from sales to all other non-entry activities. Bait5/success optimistic on failures.
  gold+=np.where(active,np.where(keep,0,vals*(1-spending))-5,0)
  if policy=='robot_first':
   buy=active&~owned&(gold>=rcost);owned[buy]=True;gold[buy]-=rcost;purchase[buy]=step*seconds
  for p in range(3):
   buy=active&(parts==p)&(gold>=COST[p]);gold[buy]-=COST[p];parts[buy]+=1
  if policy=='parts_first':
   buy=active&~owned&(parts==3)&(gold>=rcost);owned[buy]=True;gold[buy]-=rcost;purchase[buy]=step*seconds
  robotclock+=owned*active*seconds
  caught=robotclock>=400 # measured about9/h long-run competition; not guaranteed continuous12/h
  robotclock[caught]-=400;robocount+=caught
  ids=np.where(caught)[0];rsp=rng.integers(0,8,len(ids));rv=np.floor(np.linspace(10,30,8)[rsp]+.5)
  rgive=(rsp[:,None]==TARGET)&~donated[ids];donated[ids]|=rgive
  gold[ids]+=np.where(rgive.any(axis=1),0,rv*(1-spending))
  done=active&donated.all(axis=1)&(gold>=6600);finish[done]=step*seconds/3600
 observed=finish[finish>0]
 return dict(policy=policy,seconds_per_success=seconds,other_spending=spending,n=N,censored=int((finish==0).sum()),hours_p10=float(np.quantile(observed,.1)),hours_p50=float(np.median(observed)),hours_p90=float(np.quantile(observed,.9)),robot_catches_mean=float(robocount.mean()))
rows=[sim(p,s,b) for p in ['none','parts_first','robot_first'] for s in [30,45,60] for b in [0,.3]]
(P/'results.json').write_text(json.dumps(rows,indent=2)+'\n')
for x in rows:print(x)
