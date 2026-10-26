import numpy as np,pandas as pd,json,pathlib,itertools,time
import argparse
parser=argparse.ArgumentParser();parser.add_argument('--data',type=pathlib.Path,required=True);parser.add_argument('--mode',choices=['grid','sensitivity'],default='grid');ARGS=parser.parse_args()
ROOT=ARGS.data;fish=pd.read_csv(ROOT/'fish.csv');growth=json.load(open(ROOT/'growth.json'))
profiles=[]
for g in growth:
 clear=0
 for b in g['battles']:
  if not b['win']:break
  clear+=1
 profiles.append({**g,'clear':clear})
NEED=np.array([x['need'] for x in profiles],dtype=int);COST=np.array([x['gold'] for x in profiles]);CLEAR=np.array([x['clear'] for x in profiles]);WIN=np.array([[b['win'] for b in x['battles']] for x in profiles]);CYCLE=np.array([[b['cycle_seconds'] for b in x['battles']] for x in profiles])
FIRST=np.array([0,1,1,2,1,3,1,4,1,1,5]);FC=FIRST.cumsum();GC=np.array([0]+[26*r for r in range(1,11)]).cumsum();BPROB=np.array([0,0,.05,0,.08,0,.12,0,0,.20]);TARGET=np.array([1,3,8,9,14,17]);GEARC=np.array([165,330,594,10**9]);GOALS=['party','r3_ready','r5_ready','r10_ready','bundle','bundle_fee_only','license_ready']
def run(drop,price,share=.25,farm=False,seconds=35,stock=.7,n=2000,seed=83083):
 rng=np.random.default_rng(seed);ids=np.arange(n);team=rng.integers(0,2,n);coins=np.zeros(n);baseline=np.zeros(n);revenue=np.zeros(n);spent=np.zeros(n);training=np.zeros(n,int);parts=np.zeros(n,int);stage=np.full(n,-1);cleared=np.zeros(n,int);souls=np.zeros((n,5),int);donated=np.zeros((n,6),bool);carry=np.zeros(n);purchased=np.zeros(n,int);fished=np.zeros(n,int);first=np.zeros(n,int);repeat=np.zeros(n,int);markers={k:np.zeros(n,int) for k in GOALS}
 pools=[fish[(fish.parts==p)&(fish.stock==stock)][['species','price']].to_numpy(dtype=int) for p in range(4)];pools=np.stack(pools)
 def mark(key,cond,t):markers[key][cond&(markers[key]==0)]=t
 def grant(q):
  if np.any(q):souls[:]+=rng.multinomial(q,np.full(5,.2))
 def advance(t):
  for _ in range(16):
   nxt=np.minimum(stage+1,15);ix=team*16+nxt;valid=(stage<15)&np.all(souls>=NEED[ix],axis=1)&(coins>=COST[ix]-training)&(parts==3)&(markers['license_ready']==0)
   if not np.any(valid):break
   coins[valid]-=(COST[ix]-training)[valid];training[valid]=COST[ix][valid];stage[valid]+=1
   newclear=np.maximum(cleared,np.where(valid,CLEAR[ix],cleared));nb=FC[newclear]-FC[cleared];coins[:]+=GC[newclear]-GC[cleared];grant(nb);first[:]+=nb;cleared[:]=newclear
  mark('party',stage>=0,t);mark('r3_ready',cleared>=3,t);mark('r5_ready',cleared>=5,t);mark('r10_ready',cleared>=10,t)
 for t in range(1,5001):
  active=markers['license_ready']==0
  sample=pools[parts,rng.integers(0,pools.shape[1],n)];sp=sample[:,0];value=sample[:,1]
  donations=(sp[:,None]==TARGET)&~donated&active[:,None];kept=donations.any(axis=1);donated|=donations
  gain=np.where(active,np.where(kept,0,value)-5,0);coins+=gain;baseline+=gain;revenue+=np.maximum(0,gain)
  for _ in range(3):
   afford=(parts<3)&(coins>=GEARC[parts])&active
   coins[afford]-=GEARC[parts[afford]];baseline[afford]-=GEARC[parts[afford]];parts[afford]+=1
  got=(rng.random(n)<drop)&active;elem=rng.integers(0,5,n);np.add.at(souls,(ids[got],elem[got]),1);fished+=got
  advance(t)
  if farm:
   ix=team*16+np.maximum(stage,0);eligible=WIN[ix]&(np.arange(1,11)[None,:]<=cleared[:,None]);rate=np.where(eligible,BPROB[None,:]/CYCLE[ix],0);boss=rate.argmax(axis=1);can=(stage>=0)&(rate.max(axis=1)>0)&active;cycle=CYCLE[ix,boss]
   carry[can]+=seconds;wins=np.where(can,np.floor(carry/cycle),0).astype(int);carry-=wins*cycle;q=rng.binomial(wins,BPROB[boss]);grant(q);repeat+=q;coins+=wins*2*(boss+1)
  ix=team*16+np.minimum(stage+1,15);reserve=np.where(cleared<10,COST[ix]-training,6600);budget=np.maximum(0,np.minimum(coins-reserve,revenue*share-spent));buy=np.where((parts==3)&(cleared<10)&active,np.floor(budget/price),0).astype(int);coins-=buy*price;spent+=buy*price;purchased+=buy;grant(buy)
  advance(t)
  bundle=donated.all(axis=1);mark('bundle',bundle,t);mark('bundle_fee_only',bundle&(baseline>=6600),t);mark('license_ready',bundle&(coins>=6600)&(cleared>=10),t)
  if np.all(markers['license_ready']):break
 out={'drop':drop,'price':price,'share':share,'farm':farm,'seconds_per_successful_catch':seconds,'stock':stock,'players':n,'censored':int((markers['license_ready']==0).sum()),'seed':seed,'median_shop_pouches':float(np.median(purchased)),'median_fish_pouches':float(np.median(fished)),'median_repeat_pouches':float(np.median(repeat)),'median_shop_spend':float(np.median(spent)),'median_unused_souls':float(np.median(souls.sum(axis=1)-NEED[team*16+np.maximum(stage,0)].sum(axis=1)))}
 for key,v in markers.items():
  obs=v[v>0];out[key+'_p50']=float(np.median(obs)) if len(obs) else None;out[key+'_p90']=float(np.quantile(obs,.9)) if len(obs) else None
 return out
if __name__=='__main__':
 import sys
 if ARGS.mode=='sensitivity':cases=[dict(drop=d,price=p,share=share,farm=farm,seconds=sec,stock=stock,n=5000,seed=84083) for d,p in [(.20,250),(.25,250),(.25,500)] for share,farm,sec,stock in [(0,False,35,.7),(.25,False,35,.7),(.5,False,35,.7),(1.0,False,35,.7),(.25,True,20,.7),(.25,True,35,.7),(.25,True,60,.7),(.25,False,35,1.0)]];name='sensitivity'
 else:cases=[dict(drop=d,price=p,n=2000) for d,p in itertools.product([.10,.15,.20,.25],[100,250,500,1000])];name='grid'
 results=[];start=time.time()
 for c in cases:
  r=run(**c);results.append(r);print({k:r[k] for k in ['drop','price','share','farm','r3_ready_p50','r10_ready_p50','bundle_p50','license_ready_p50','license_ready_p90','median_shop_pouches','censored']},flush=True)
  (ROOT/(name+'.json')).write_text(json.dumps(results,indent=2)+'\n')
 print('DONE',sum(x['players'] for x in results),'seconds',time.time()-start)
