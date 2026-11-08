from pathlib import Path
import json, math, statistics, heapq, hashlib, sys
ROOT=Path(__file__).resolve().parent
LEDGER=Path(sys.argv[1]) if len(sys.argv)>1 else Path('tile-price-ledger.json')
BASE=[25,35,45,50,30,30,50,55,130,145,175,225,150,195,480,560,610,2240,2760,16000]
GRADE=[1,1.3,1.7,2.2,3]
STAR=[0]*8+[1]*6+[2]*3+[3]*2+[4]
PROFILES={'current':BASE,'all_x10':[p*10 for p in BASE], 'gentle':[p*[20,15,10,6,2][STAR[i]] for i,p in enumerate(BASE)],'balanced':[p*[40,30,20,12,3][STAR[i]] for i,p in enumerate(BASE)],'active':[p*[60,40,25,15,4][STAR[i]] for i,p in enumerate(BASE)],'rounded':[1500,1800,2200,2500,1800,1800,2500,2800,5000,6000,6500,8000,5500,7000,15000,18000,20000,36000,45000,65000]}
DATA=json.loads(LEDGER.read_text())
results=[];mismatches=0
for case in DATA['cases']:
 ledger=case['ledger']; dt=[e[0] for e in ledger];times=[];t=0
 for x in dt:t+=x;times.append(t/3600)
 for e in ledger:
  val=math.floor(BASE[e[1]]*GRADE[e[2]]*min(e[3]**2,2.5)+.5)
  if val!=e[7]:mismatches+=1
 for name,prices in PROFILES.items():
  values=[math.floor(prices[e[1]]*GRADE[e[2]]*min(e[3]**2,2.5)+.5) for e in ledger]
  ordinary=0;owners=0;profit=0;half=0;first=None;half_t=times[len(ledger)//2-1]
  for i,(e,p) in enumerate(zip(ledger,values)):
   profit-=[5,15,20][case['bait']];profit+=e[6]
   if e[4]:
    if e[1]==19:owners+=p
    else:ordinary+=p
    if not e[5]:profit+=p
   if first is None and profit>=4635000:first=times[i]
   if i==len(ledger)//2-1:half=profit
  row={'candidate':name,'trial':case['trial'],'bait':case['bait'],'mode':case['mode'],'sale_only_first_fee_hours':first,'sale_only_steady_net_per_hour':(profit-half)/(times[-1]-half_t),'owner_share_of_gross':owners/(ordinary+owners)}
  for policy in ['aquarium_boat0','aquarium_invest']:
   cash=0;aq=[];aq_lv=0;boat=0;rate=0;firstaq=None;passive=0;spent=0
   for i,(e,p) in enumerate(zip(ledger,values)):
    income=rate*e[0]/3600;cash+=income;passive+=income
    cash-=[5,15,20][case['bait']];cash+=e[6]
    if e[4] and not e[5]:
     if len(aq)<[3,6,10,15,20][aq_lv]:heapq.heappush(aq,p)
     elif p>aq[0]:cash+=heapq.heapreplace(aq,p)
     else:cash+=p
    if policy=='aquarium_invest':
     while boat<5 and cash>=[160,420,1000,2400,6000][boat]:
      cost=[160,420,1000,2400,6000][boat];cash-=cost;spent+=cost;boat+=1
     while aq_lv<4 and cash>=[300,900,2400,6000][aq_lv]:
      cost=[300,900,2400,6000][aq_lv];cash-=cost;spent+=cost;aq_lv+=1
    mult=(4+2*boat)/4*60/(60-4*boat)
    rate=sum(aq)*.15*mult
    if cash>=4635000:
     firstaq=times[i];break
   row[policy]={'first_fee_hours':firstaq,'passive_earned_to_goal':passive,'invested':spent,'display_fish':len(aq),'display_value':sum(aq),'boat_lv':boat,'hourly_passive_at_goal':rate}
  results.append(row)
assert mismatches==0,mismatches
summary=[]
for name in PROFILES:
 for mode in ['full','continuous']:
  rr=[r for r in results if r['candidate']==name and r['mode']==mode]
  def desc(xs):
   ys=[x for x in xs if x is not None];return {'completed':len(ys),'n':len(xs),'median':statistics.median(ys) if ys else None,'min':min(ys) if ys else None,'max':max(ys) if ys else None}
  summary.append({'candidate':name,'mode':mode,'sale_only':desc([r['sale_only_first_fee_hours'] for r in rr]),'aquarium_boat0':desc([r['aquarium_boat0']['first_fee_hours'] for r in rr]),'aquarium_invest':desc([r['aquarium_invest']['first_fee_hours'] for r in rr]),'median_owner_share':statistics.median(r['owner_share_of_gross'] for r in rr),'median_net_per_hour':statistics.median(r['sale_only_steady_net_per_hour'] for r in rr)})
out={'draws':DATA['draws'],'seeds':5,'cases':30,'price_profiles':PROFILES,'price_parity_checks':DATA['draws'],'price_parity_mismatches':mismatches,'ledger_sha256':hashlib.sha256(LEDGER.read_bytes()).hexdigest(),'results':results,'summary':summary}
(ROOT/'RESULTS.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
for r in summary:
 print(r['candidate'],r['mode'],'sale',round(r['sale_only']['median'] or 0,2),'aqua0',round(r['aquarium_boat0']['median'] or 0,2),'invest',round(r['aquarium_invest']['median'] or 0,2),'owner%',round(100*r['median_owner_share']))
