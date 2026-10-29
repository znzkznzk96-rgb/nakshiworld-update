"""Conditional full-campaign economy Monte Carlo. 10-minute updates, no forced unlock dates.
Current two-region tables + explicitly hypothetical future fish/bundles/combat.
Cash, fish donation, aquarium replacements, upgrade spending and owner gates tracked.
"""
import pathlib,sys,json,time,copy,argparse
import numpy as np
P=pathlib.Path(__file__).resolve().parent
sys.path.insert(0,str(P.parent/'capture-robot-six-regions'))
from six_regions import STARS,GRADES,BASE,MULT,VALLEY,GROUPS,VM
ENTRY=np.array([0,6600,104000,1545000,10050000,42450000])
ROD=np.array([0,2000,35000,700000,4500000,19000000])
PARTBASE=np.array([0,3300,52000,1030000,6700000,28300000])
PARTS=np.array([[165,330,594,990]]+[[int(np.floor(max(10,np.floor(PARTBASE[r]*f/10+.5)*10)*1.5+.5)) for f in [.05,.10,.18,.30]] for r in range(1,6)])
AQUAC=[300,900,2400,6000];AQUACAP=[3,6,10,15,20]
BOATC=[160,420,1000,2400,6000]
CAPC=[300,800,1800,4200,9000];REGC=[250,700,1600,3800,8000]
BAGCAP=np.array([.5,1.5,3,6,12,20,30,45,65]);BAGC=[0,150,800,4000,20000,80000,300000,1200000,5000000]
TARGETS=np.array([[1,3,8,9,14,17],[1,4,8,11,14,17]]+[[1,3,8,9,14,17]]*4)
# Robot rate/price stage bundles through each regional tier, with precision and storage included separately.
RB_RATE=[24,36,48,54,60,72];RB_COST=[1080,9000,780000,1100000,1100000,5200000]
RB_PREC=[0,12000,65000,210000,0,0]
CONFIGS={
 'baseline':{},
 'fees_x2':{'fee_scale':2},
 'aquarium_quarter':{'aqua_div':1200},
 'visitors_2_5':{'visitor_max':2.5},
 'infra_progressive':{'infra':True},
 'combined':{'aqua_div':1200,'visitor_max':2.5,'infra':True},
 'combined_fees2':{'aqua_div':1200,'visitor_max':2.5,'infra':True,'fee_scale':2},
 'combined_fees4':{'aqua_div':1200,'visitor_max':2.5,'infra':True,'fee_scale':4},
 'no_aquarium':{'aqua_off':True},
 'no_robot':{'robot_off':True},
}

def run(config,n=256,seed=20261030,days=240,pace=35,fish_scale=1,offline=8,success=.9,owner_success=.6,spend_other=.15,collection=1,policy='balanced'):
 cfg={'fee_scale':1.,'aqua_div':300.,'visitor_max':5.25,'infra':False,'aqua_off':False,'robot_off':False,**config}
 rng=np.random.default_rng(seed);ids=np.arange(n);region=np.zeros(n,int);gold=np.zeros(n);parts=np.zeros(n,int);rod=np.zeros(n,int);bag=np.zeros(n,int);boat=np.zeros(n,int);aqlev=np.zeros(n,int);caplev=np.zeros(n,int);reglev=np.zeros(n,int)
 stock=np.full(n,40.);gauge=np.zeros(n);donated=np.zeros((n,6),int);aquarium=np.zeros((n,20));aqspecies=np.full((n,20),-1,int)
 bot=np.zeros(n,bool);btier=np.full(n,-1,int);bprec=np.zeros(n,int);bcap=np.full(n,20);rbank=np.zeros(n);robot_wait=np.zeros(n)
 reached=np.full((n,6),np.nan);reached[:,0]=0;finished=np.full(n,np.nan);owner_count=np.zeros(n,int)
 earn_manual=np.zeros(n);earn_aqua=np.zeros(n);earn_robot=np.zeros(n);spent=np.zeros(n);other=np.zeros(n);milestones=[];stalls=np.zeros(n);lastbuy=np.zeros(n);maxgap=np.zeros(n)
 baseprices=np.zeros((6,20))
 for r in range(6):
  for s,group in enumerate(GROUPS):baseprices[r,group]=np.array([VALLEY[k] for k in group]) if r==1 else np.linspace(*BASE[s],len(group))*(VM[r]*fish_scale if r>=2 else 1)
  baseprices[r,19]=(16000 if r==1 else 8000*(VM[r]*fish_scale if r>=2 else 1))
 def visitors():
  old=(4+2*boat)/4*60/(60-4*boat)
  return old if cfg['visitor_max']==5.25 else 1+(old-1)*(cfg['visitor_max']-1)/4.25
 def buy(mask,cost):
  nonlocal gold,spent,lastbuy,maxgap
  ok=mask&(gold>=cost)&np.isnan(finished);gold[ok]-=np.broadcast_to(cost,(n,))[ok];spent[ok]+=np.broadcast_to(cost,(n,))[ok]
  maxgap[ok]=np.maximum(maxgap[ok],now-lastbuy[ok]);lastbuy[ok]=now
  return ok
 def infrastructure_cost(arr,lv):
  c=np.array(arr)[np.minimum(lv,len(arr)-1)].astype(float)
  # Trial: regional price curves + license stage ceiling. Existing save migration not modeled.
  if cfg['infra']:c*=np.array([1,4,20,80,250])[np.minimum(lv,4)]
  return c
 def process_catch(mask,sp,grade,price,weight,is_robot=False,is_owner=False):
  nonlocal gold,aquarium,aqspecies,donated,earn_manual,earn_robot,gauge,other
  matches=(sp[:,None]==TARGETS[region])&(donated<collection)&mask[:,None]
  donated+=matches.astype(int);need=matches.any(axis=1)
  available=mask&~need
  # Top-value storage, displaced fish sold; donation gets first priority.
  limit=np.array(AQUACAP)[aqlev]
  masked=np.where(np.arange(20)[None,:]<limit[:,None],aquarium,np.inf)
  slot=masked.argmin(axis=1);old=aquarium[ids,slot]
  keep=available&(price>old)&(not cfg['aqua_off'])
  # Bank old value only when replacing an occupied slot. New fish sale opportunity is forgone.
  sale=np.where(available,np.where(keep,old,price),0)
  aquarium[ids[keep],slot[keep]]=price[keep];aqspecies[ids[keep],slot[keep]]=region[keep]*20+sp[keep]
  fraction=spend_other if not is_robot else 0.
  diverted=sale*fraction;gold+=sale-diverted;other+=diverted
  if is_robot:earn_robot+=sale
  else:
   earn_manual+=sale
   gauge+=np.where(mask&(parts==4)&(not is_owner),np.array([1,1,2,3,5])[grade],0);gauge=np.minimum(100,gauge)
 for day in range(days):
  active=np.isnan(finished)
  if not active.any():break
  # Only one login a day: actual offline cap8 hours, not24.
  if day:
   offline_gain=aquarium.sum(axis=1)/cfg['aqua_div']*60*visitors()*offline
   offline_gain*=active;gold+=offline_gain;earn_aqua+=offline_gain
   stock=np.minimum(40+20*caplev,stock+(30+10*reglev)*22)
  for segment in range(12):
   now=day*2+(segment+1)/6;active=np.isnan(finished)
   if not active.any():break
   # Gear-first policy; no forced dates, only affordability and actual collection gates.
   for p in range(4):
    ok=buy(active&(parts==p),PARTS[region,p]);parts[ok]+=1
   ok=buy(active&(rod<region),ROD[region]);rod[ok]=region[ok]
   # Maintain practical bag; old bag remains until affordable next bag.
   needbag=(bag<np.minimum(8,region+3))
   ok=buy(active&needbag,np.array(BAGC)[np.minimum(bag+1,8)]);bag[ok]+=1
   ceiling=np.minimum(5,region+1) if cfg['infra'] else np.full(n,5)
   for lv,arr,kind in [(boat,BOATC,'boat'),(aqlev,AQUAC,'aqua'),(caplev,CAPC,'cap'),(reglev,REGC,'regen')]:
    maximum=4 if kind=='aqua' else 5
    eligible=active&(lv<maximum)&(lv<ceiling)&(parts>=3)
    if cfg['aqua_off'] and kind in ['aqua','boat']:eligible[:]=False
    if policy=='rush':eligible &= region>=2
    # avoid buying more slots when available aquarium slots mostly empty
    if kind=='aqua':eligible &= (aquarium>0).sum(axis=1)>=np.array(AQUACAP)[aqlev]
    ok=buy(eligible,infrastructure_cost(arr,lv));lv[ok]+=1
   if not cfg['robot_off']:
    ok=buy(active&~bot&(parts>=3),np.full(n,1000));bot[ok]=True
    # Batched regional robot upgrades price paid in full; intentional abstraction.
    nxt=np.minimum(btier+1,5)
    ok=buy(active&bot&(btier<region),np.array(RB_COST)[nxt]);btier[ok]+=1
    ok=buy(active&bot&(bprec<np.minimum(region,3)),np.array(RB_PREC)[np.minimum(bprec+1,3)]);bprec[ok]+=1
    bcap=np.where(bot,20+10*np.minimum(region,4),20)
   # Cash upgrades consume money; enhancement/expedition soul paths represented by other-spending sensitivity.
   cap=40+20*caplev;regen=30+10*reglev
   # Determine manual attempts from combat pace + bag trips + expected empty-stock wait.
   smax=np.minimum(parts,3);ratio=np.clip(stock/cap,0,1);oddsratio=np.where(region<2,np.maximum(.7,ratio),ratio)
   sw=np.array(STARS)[(region>0).astype(int),:4]*(.04+.96*oddsratio[:,None])**np.arange(4)
   sw*=np.arange(4)[None,:]<=smax[:,None];sw/=sw.sum(axis=1)[:,None]
   avgweight=sw@np.array([.08,.25,.7,1.8])*1.15
   trips=success*avgweight/BAGCAP[bag]*40 #40 seconds/return; inventory sale itself immediate in accounting
   waitpenalty=np.where(stock<1,9.375,2.25*(1-ratio))
   cycle=pace+trips+waitpenalty
   attempts=np.where(active,rng.poisson(600/cycle),0)
   # Robot exact long-run empty-stock bound for serial reserve+work, blended with startup stock.
   rate=np.where(bot,np.where(btier>=0,np.array(RB_RATE)[np.maximum(btier,0)],12),0)
   empty_rate=np.divide(rate*regen,rate+regen,out=np.zeros(n),where=(rate+regen)>0)
   robot_rate=np.where(stock>attempts+rate/6,rate,empty_rate)
   rbank+=np.where(active,robot_rate/6,0)
   robot_n=np.minimum(np.floor(rbank).astype(int),bcap);rbank-=robot_n
   # shared stock consumption, including failed manual casts; no extra robot supply
   robot_n=np.minimum(robot_n,np.floor(stock+regen/6).astype(int))
   stock=np.maximum(0,np.minimum(cap,stock+regen/6)-attempts-robot_n)
   aqua_gain=aquarium.sum(axis=1)/cfg['aqua_div']*60*visitors()/6*active
   gold+=aqua_gain;earn_aqua+=aqua_gain
   gold-=attempts*5
   # Draw all captures in this10-minute segment. Poisson attempts may exceed mean.
   for k in range(int(attempts.max(initial=0))):
    mask=active&(attempts>k)&(rng.random(n)<success)
    boss=active&(attempts>k)&(gauge>=100)&(parts==4)
    if np.any(boss):
     win=boss&(rng.random(n)<owner_success)
     owner_count+=win;gauge[boss]=np.where(win[boss],0,70)
     finish=win&(region==5);finished[finish]=now
     # Owner sold or displayed as normal valuable fish, never force quest extra rewards.
     vals=baseprices[region,19]*np.minimum(rng.normal(1,.15,n).clip(.5,1.65)**2,2.5)
     process_catch(win,np.full(n,19),np.zeros(n,int),vals,np.full(n,4.5),is_owner=True)
    mask&=~boss
    u=rng.random(n);star=(u[:,None]>np.cumsum(sw,axis=1)).sum(axis=1).clip(0,3)
    sp=np.zeros(n,int)
    for st,group in enumerate(GROUPS):
     ix=np.where(star==st)[0];sp[ix]=rng.choice(group,len(ix))
    gp=np.array(GRADES)[(region>0).astype(int)];g=(rng.random(n)[:,None]>np.cumsum(gp,axis=1)).sum(axis=1).clip(0,4)
    lf=np.clip(rng.normal(1,.15,n),.5,1.65)
    vals=np.floor(baseprices[region,sp]*np.array(MULT)[g]*np.minimum(lf*lf,2.5)+.5)
    process_catch(mask,sp,g,vals,np.zeros(n))
   for k in range(int(robot_n.max(initial=0))):
    mask=active&(robot_n>k)
    rw=sw*(np.arange(4)[None,:]<=bprec[:,None]);rw/=rw.sum(axis=1)[:,None]
    st=(rng.random(n)[:,None]>np.cumsum(rw,axis=1)).sum(axis=1).clip(0,3)
    sp=np.zeros(n,int)
    for s,group in enumerate(GROUPS):
     ix=np.where(st==s)[0];sp[ix]=rng.choice(group,len(ix))
    gp=np.array(GRADES)[(region>0).astype(int)].copy()
    for gg in range(1,5):
     locked=bprec<gg;gp[locked,0]+=gp[locked,gg];gp[locked,gg]=0
    g=(rng.random(n)[:,None]>np.cumsum(gp,axis=1)).sum(axis=1).clip(0,3)
    vals=np.floor(baseprices[region,sp]*np.array(MULT)[g]+.5)
    process_catch(mask,sp,g,vals,np.zeros(n),True)
   # existing next-region license main bundle, all grades eligible. No required previous owner.
   nextregion=np.minimum(region+1,5)
   enter=active&(region<5)&(donated>=collection).all(axis=1)&(gold>=ENTRY[nextregion]*cfg['fee_scale'])
   if np.any(enter):
    fee=ENTRY[nextregion]*cfg['fee_scale'];gold[enter]-=fee[enter];spent[enter]+=fee[enter]
    region[enter]+=1;parts[enter]=0;gauge[enter]=0;donated[enter]=0;reached[ids[enter],region[enter]]=now
  if day in [0,2,6,13,29,49,74,99,149,199,239]:
   milestones.append(dict(day=day+1,region_counts=np.bincount(region,minlength=6).tolist(),finished=int(np.isfinite(finished).sum()),gold_p50=float(np.median(gold))))
 def summary(a):
  valid=a[np.isfinite(a)]
  return {'observed':len(valid),'p10':float(np.quantile(valid,.1)) if len(valid) else None,'p50':float(np.median(valid)) if len(valid) else None,'p90':float(np.quantile(valid,.9)) if len(valid) else None}
 completed=np.isfinite(finished)
 return dict(config=cfg,n=n,seed=seed,days_horizon=days,pace=pace,fish_scale=fish_scale,offline=offline,success=success,owner_success=owner_success,spend_other=spend_other,collection=collection,policy=policy,
  end_hours=summary(finished),censored=int((~completed).sum()),within_100_200h=float(((finished>=100)&(finished<=200)).mean()),below_100h=float((finished<100).mean()),above_200h_or_censored=float(((finished>200)|~completed).mean()),
  region_hours=[summary(reached[:,i]) for i in range(6)],mean_manual_sale=float(earn_manual.mean()),mean_robot_sale=float(earn_robot.mean()),mean_aqua_income=float(earn_aqua.mean()),mean_spending=float(spent.mean()),mean_other_spending=float(other.mean()),
  median_upgrade_gap_hours=float(np.median(maxgap)),milestones=milestones)

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--mode',default='screen');args=parser.parse_args();start=time.time();rows=[]
 if args.mode=='screen':cases=[(k,v,{}) for k,v in CONFIGS.items()]
 else:
  selected=json.loads((P/'selected.json').read_text())
  cases=[]
  for fish_scale in [.5,1,2]:
   for pace in [25,35,50]:
    for policy in ['balanced','rush']:cases.append(('selected',selected,dict(fish_scale=fish_scale,pace=pace,policy=policy)))
  for off in [0,4,8]:cases.append(('selected',selected,dict(offline=off)))
  for sp in [0,.3]:cases.append(('selected',selected,dict(spend_other=sp)))
  for own in [.3,.9]:cases.append(('selected',selected,dict(owner_success=own)))
 for name,cfg,kw in cases:
  result=run(cfg,n=128 if args.mode=='screen' else 256,**kw);result['name']=name;rows.append(result)
  (P/(args.mode+'.json')).write_text(json.dumps(rows,indent=2)+'\n')
  print(name,kw,'end',result['end_hours'],'censored',result['censored'],'target',round(result['within_100_200h'],3),flush=True)
 print('DONE',time.time()-start,flush=True)
if __name__=='__main__':main()
