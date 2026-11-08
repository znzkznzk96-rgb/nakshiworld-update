from pathlib import Path
import json,math,statistics,heapq,bisect,time,hashlib
import argparse
parser=argparse.ArgumentParser();parser.add_argument('--offline-hours',type=float,default=3);parser.add_argument('--focus',action='store_true');parser.add_argument('--ledger',default='joint-owner-ledger.json');parser.add_argument('--max-ledger',default='joint-owner-max-ledger.json');parser.add_argument('--price-table',default='owner500/docs/qa/owner-sale-500000/PRICE_TABLES.json');parser.add_argument('--output',default='joint-balance-results.json');args=parser.parse_args();OFFLINE=args.offline_hours;start=time.time()
a=json.load(open(args.ledger));b=json.load(open(args.max_ledger));D=a['cases']+b['cases']
BASE=json.load(open(args.price_table))['prices'];BASE[1][19]=40000;BASE[2][19]=500000
FEES=[4635000]+[x*1000000 for x in range(6,41)]
BASIS=[20000,40000,60000,80000,100000,500000]
if args.focus:BASIS=[60000];FEES=[25000000]
variants={'slow':[('slow_20',20,5)],'reference':[('reference_5',5,2),('reference_20',20,5)],'fast':[('fast_20',20,5)],'max_upgrades':[('max_20',20,5)]}
policies=['sell_new','income_greedy','roi_7day']
rows=[];draws=a['draws']+b['draws']
for inc in BASIS:
 for c in D:
  profile=c['profile'];factor=1+.05*profile['forge'];oldbases=[8000,16000,20000]
  events=[]
  for e in c['ledger']:
   if e[1]<0:events.append((e[0],-1,False,0,0,e[8]));continue
   q=[1,1.3,1.7,2.2,3][e[2]]*min(e[3]**2,2.5)*factor
   p=math.floor(BASE[2][e[1]]*q+.5);income=math.floor(inc*q+.5) if e[1]==19 else p
   # Mandatory six-species donation only. Optional owner/side bundles may be skipped to advance faster.
   events.append((e[0],40+e[1],bool(e[4] and e[5]!=1),p,income,e[8]))
  for variant,slots,boat in variants[profile['id']]:
   initial_types=['legacy','current','none'] if profile['id']=='reference' else ['current','none']
   mult=.15*((4+2*boat)/4*60/(60-4*boat))
   for initial in initial_types:
    for policy in policies:
     active={};owners={};heap=[];uid=0;income_sum=0
     if initial!='none':
      for r in range(3):
       sale=round((oldbases[r] if initial=='legacy' else BASE[r][19])*factor)
       ib=[8000,16000,inc][r] if inc!=500000 else [8000,40000,500000][r]
       value=min(sale,round(ib*factor));active[uid]=(r*20+19,sale,value);owners[r*20+19]=uid;heapq.heappush(heap,(value,uid));income_sum+=value;uid+=1
     while len(active)<5:
      sp=58 if len(active)%2 else 57;sale=round(BASE[2][sp%20]*factor);active[uid]=(sp,sale,sale);heapq.heappush(heap,(sale,uid));income_sum+=sale;uid+=1
     cash=0.;online=0.;credited=0.;session=0.;idx=0;goals=[None]*len(FEES);day=1;owner_sales=0
     for dt,sp,success,sale,value,day in events:
      if sp<0:cash+=int(OFFLINE//3)*math.floor(income_sum*mult*3)+math.floor(income_sum*mult*(OFFLINE%3));credited+=OFFLINE;session=0
      else:
       cash+=income_sum*mult*dt/3600;online+=dt;credited+=dt/3600;session+=dt;cash-=[5,15,20][c['bait']]
       if success:
        retained=False
        if policy!='sell_new':
         is_owner=sp%20==19
         same=owners.get(sp) if is_owner else None
         while heap and heap[0][1] not in active:heapq.heappop(heap)
         old_id=same if same is not None else (None if len(active)<slots else heap[0][1])
         old=active.get(old_id,(None,0,0))
         if value>old[2]:
          payback=(sale-old[1])/((value-old[2])*mult)
          if policy=='income_greedy' or payback<=max(0,7*(3+OFFLINE)-credited):
           if old_id is not None:
            active.pop(old_id);cash+=old[1]
            if old[0]%20==19:owners.pop(old[0],None)
           active[uid]=(sp,sale,value);heapq.heappush(heap,(value,uid))
           if is_owner:owners[sp]=uid
           income_sum+=value-old[2];uid+=1;retained=True
        if not retained:cash+=sale;owner_sales+=int(sp%20==19)
      while idx<len(FEES) and cash>=FEES[idx]:
       goals[idx]=(day,min(1.,session/10800) if sp>=0 else 0.,online/3600);idx+=1
      if idx==len(FEES):break
     for fee,goal in zip(FEES,goals):rows.append({'income_base':inc,'fee':fee,'profile':variant,'initial':initial,'policy':policy,'trial':c['trial'],'bait':c['bait'],'goal':goal})
 print('GRID_PROGRESS',inc,'seconds',round(time.time()-start,1),flush=True)
policy_summary=[]
if args.focus:
 groups={}
 for r in rows:groups.setdefault((r['profile'],r['initial'],r['policy']),[]).append(r)
 for key,rr in groups.items():
  days=[r['goal'][0] if r['goal'] else 15 for r in rr]
  policy_summary.append({'profile':key[0],'initial':key[1],'policy':key[2],'median_day':statistics.median(days),'min_day':min(days),'max_day':max(days),'n':len(rr)})
# Fastest of legitimate policies per seed/bait/starting aquarium; 14-day censoring retained.
by={}
for r in rows:
 key=(r['income_base'],r['fee'],r['profile'],r['initial'],r['trial'],r['bait'])
 if key not in by or (r['goal'] and (not by[key]['goal'] or r['goal'][:2]<by[key]['goal'][:2])):by[key]=r
buckets={}
for key,r in by.items():buckets.setdefault(key[:4],[]).append(r)
def pct(xs,q):
 ss=sorted(xs);return ss[int((len(ss)-1)*q)]
summary=[]
for key,rr in buckets.items():
 vals=[r['goal'][0] if r['goal'] else 15 for r in rr];gg=[r['goal'] for r in rr if r['goal']]
 summary.append(dict(zip(['income_base','fee','profile','initial'],key),n=len(rr),completed=len(gg),median_day=statistics.median(vals),p10_day=pct(vals,.1),p90_day=pct(vals,.9),min_day=min(vals),max_day=max(vals),median_active_hours=statistics.median(g[2] for g in gg) if len(gg)==len(rr) else None))
look={(r['income_base'],r['fee'],r['profile'],r['initial']):r for r in summary}
rank=[]
for inc in BASIS[:-1]:
 for fee in FEES[1:]:
  ref=[look[inc,fee,'reference_20',ini] for ini in ['legacy','current','none']]
  med=statistics.mean(r['median_day'] for r in ref)
  fast=statistics.mean(look[inc,fee,'max_20',i]['median_day'] for i in ['current','none'])
  slow=statistics.mean(look[inc,fee,'slow_20',i]['median_day'] for i in ['current','none'])
  censor=sum(r['n']-r['completed'] for r in ref)
  score=abs(med-7)+.35*max(0,5-min(r['p10_day'] for r in ref))+.3*max(0,max(r['p90_day'] for r in ref)-9)+.5*max(0,4.5-fast)+.25*max(0,slow-11)+censor*.1
  rank.append({'income_base':inc,'fee':fee,'score':score,'reference_mean_median':med,'fast_median':fast,'slow_median':slow,'reference_censored':censor})
rank.sort(key=lambda r:(r['score'],abs(r['income_base']-60000),r['fee']))
out={'policy_summary':policy_summary,'draws':draws,'trace_cases':len(D),'parameter_paths':len(rows)//len(FEES),'threshold_evaluations':len(rows),'income_bases':BASIS,'fees':FEES,'ranking':rank[:40],'summary':summary,'ledger_hashes':{p:hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in [args.ledger,args.max_ledger]},'duration_seconds':time.time()-start,'offline_credit_hours_per_day':OFFLINE,'source':'fe95f5593f6ba2a133caf81cee69bd70bf00cf15','notes':['fee goal only; region3 prepared not available',f'daily3h online plus{OFFLINE}h total offline credit in max3h settlements, starts zero cash; gear upgrades already paid','main donations kept; optional side/owner donations skipped in fastest-policy comparison','starting5fish; empty expanded slots filled only by actual caught fish','normal aquarium value equals stored sale; owner income detached with grade/size/forge preserved, initial legacy capped by old stored sale','sell-new, income-greedy, fixed7day-credit-horizon payback policies compared; not a proven globally optimal policy','cycle/success profiles are explicit assumptions; real game start_wait/grade/gauge/stock RNG used','14day noncompletions censored as15 for ranking; completed counts explicit','no travel/bag/menu downtime, robot or expedition income; no shared-account savings/asset liquidation']}
Path(args.output).write_text(json.dumps(out,indent=2)+'\n')
print('TOP',json.dumps(rank[:12]),flush=True)
