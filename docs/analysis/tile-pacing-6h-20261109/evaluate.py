from pathlib import Path
import json,math,statistics,heapq,sys
ROOT=Path(__file__).resolve().parent
D=json.loads(Path(sys.argv[1] if len(sys.argv)>1 else 'tile-daily-ledger.json').read_text());BASE=[25,35,45,50,30,30,50,55,130,145,175,225,150,195,480,560,610,2240,2760,16000];GRADE=[1,1.3,1.7,2.2,3]
PRICES={'current':BASE,'ordinary_x2':[x*(2 if i<19 else 1) for i,x in enumerate(BASE)],'ordinary_x3':[x*(3 if i<19 else 1) for i,x in enumerate(BASE)],'ordinary_x5':[x*(5 if i<19 else 1) for i,x in enumerate(BASE)],'all_x1.5':[round(x*1.5) for x in BASE]}
# Isolated hypothetical aquarium hourly caps, for diagnosing pace only, not approved changes.
POLICIES=[('empty',None),('inherited',None),('empty',80000),('empty',100000),('empty',120000)]
rows=[];parity=0
for c in D['cases']:
 for e in c['ledger']:
  if e[1]>=0:
   assert math.floor(BASE[e[1]]*GRADE[e[2]]*min(e[3]**2,2.5)+.5)==e[7];parity+=1
 for name,prices in PRICES.items():
  for init,cap in POLICIES:
   aq=[] if init=='empty' else [16000]*20;heapq.heapify(aq);aqlv=0 if init=='empty' else 4;boat=0 if init=='empty' else 5
   cash=0;active=0;passive=0;invested=0;goal=None;checkpoints=[];current_day=1
   def rate():return min(sum(aq)*.15*(4+2*boat)/4*60/(60-4*boat),cap if cap else float('inf'))
   for e in c['ledger']:
    day=e[8]
    if e[1]<0:
     checkpoints.append({'day':current_day,'active_hours':active/3600,'cash_before_offline':cash,'passive_rate':rate()});current_day=day
     earn=math.floor(rate()*8);cash+=earn;passive+=earn
    else:
     earn=rate()*e[0]/3600;cash+=earn;passive+=earn;active+=e[0];cash-=[5,15,20][c['bait']];cash+=e[6]
     if e[4] and not e[5]:
      p=math.floor(prices[e[1]]*GRADE[e[2]]*min(e[3]**2,2.5)+.5)
      if len(aq)<[3,6,10,15,20][aqlv]:heapq.heappush(aq,p)
      elif p>aq[0]:cash+=heapq.heapreplace(aq,p)
      else:cash+=p
     while boat<5 and cash>=[160,420,1000,2400,6000][boat]:
      cost=[160,420,1000,2400,6000][boat];cash-=cost;invested+=cost;boat+=1
     while aqlv<4 and cash>=[300,900,2400,6000][aqlv]:
      cost=[300,900,2400,6000][aqlv];cash-=cost;invested+=cost;aqlv+=1
    if cash>=4635000:
     goal={'day':day,'active_hours':active/3600,'at_login':e[1]<0,'cash':cash};break
   rows.append({'profile':name,'initial_aquarium':init,'hourly_cap':cap,'trial':c['trial'],'bait':c['bait'],'goal':goal,'checkpoints':checkpoints,'passive':passive,'invested':invested})
summary=[]
for name in PRICES:
 for init,cap in POLICIES:
  rr=[r for r in rows if r['profile']==name and r['initial_aquarium']==init and r['hourly_cap']==cap];goals=[r['goal'] for r in rr if r['goal']]
  summary.append({'profile':name,'initial_aquarium':init,'hourly_cap':cap,'completed':len(goals),'cases':len(rr),'median_active_hours':statistics.median(g['active_hours'] for g in goals) if goals else None,'min_active_hours':min(g['active_hours'] for g in goals) if goals else None,'max_active_hours':max(g['active_hours'] for g in goals) if goals else None,'median_day':statistics.median(g['day'] for g in goals) if goals else None,'target_cases':sum(g['day'] in [3,4] and 18<=g['active_hours']<=24.1 for g in goals)})
x={'source_game_commit':'c74960ababa175a55a40fcd225799c1174e55f43','draws':parity,'price_parity_mismatches':0,'prices':PRICES,'summary':summary,'results':rows}
(ROOT/'RESULTS.json').write_text(json.dumps(x,indent=2)+'\n')
for s in summary:print(s['profile'],s['initial_aquarium'],s['hourly_cap'],'day',s['median_day'],'hours',round(s['median_active_hours'] or 0,2),'target',s['target_cases'])
