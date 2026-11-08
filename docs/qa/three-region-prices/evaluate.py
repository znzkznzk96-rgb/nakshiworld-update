from pathlib import Path
import json,math,heapq,statistics,hashlib,sys
ROOT=Path(__file__).resolve().parent
LEDGER=Path(sys.argv[1]) if len(sys.argv)>1 else Path('three-region-ledger.json')
D=json.loads(LEDGER.read_text());G=[1,1.3,1.7,2.2,3]
OLD0=[10+20*i/7 for i in range(8)]+[50+14*i for i in range(6)]+[200,275,350,1000,1500,8000]
OLD1=[25,35,45,50,30,30,50,55,130,145,175,225,150,195,480,560,610,2240,2760,16000]
OLD=[OLD0,OLD1,OLD1]
NEW=[[20,25,30,35,40,45,50,55,100,130,160,190,220,250,400,550,700,1500,2200,8000],[100,140,180,200,120,120,200,220,500,600,700,900,600,800,1800,2200,2500,4500,5500,16000],[500,700,900,1000,600,600,1000,1100,2000,2400,2800,3600,2400,3200,5500,6500,7500,12000,15000,20000]]
results=[];parity=0
for c in D['cases']:
 area=c['region'];forge=[0,2,3][area];boat=[0,1,2][area];cap=[3,5,5][area]
 for e in c['ledger']:
  if e[1]>=0:
   assert math.floor(OLD[area][e[1]]*G[e[2]]*min(e[3]**2,2.5)+.5)==e[7],(area,e);parity+=1
 for tag,table in [('old',OLD),('new',NEW)]:
  for policy in ['sale_only','aquarium']:
   aq=[] if area==0 else [table[0][19]]*3 if area==1 else [table[0][19],table[1][19],table[1][19],table[2][19],table[2][19]]
   if area==2:aq=[math.floor(p*1.15+.5) for p in aq]
   heapq.heapify(aq);cash=0;active=0;gross=0;baitcost=0;passive=0;donation_value=0;sub_value=0;bonus=0;goal=None;half=0;half_active=0;before_offline=0
   rate=lambda:sum(aq)*.15*(4+2*boat)/4*60/(60-4*boat) if policy=='aquarium' else 0
   for i,e in enumerate(c['ledger']):
    if e[1]<0:
     earn=math.floor(rate()*3);cash+=earn;passive+=earn
    else:
     earn=rate()*e[0]/3600;cash+=earn;passive+=earn;active+=e[0];cash-=[5,15,20][c['bait']];baitcost+=[5,15,20][c['bait']]
     p=math.floor(table[area][e[1]]*G[e[2]]*min(e[3]**2,2.5)*(1+.05*forge)+.5)
     if e[4]:
      gross+=p
      if e[5]:donation_value+=p
      elif policy=='aquarium' and (area==0 or e[1]==19):
       if len(aq)<cap:heapq.heappush(aq,p)
       elif p>aq[0]:cash+=heapq.heapreplace(aq,p)
       else:cash+=p
      else:cash+=p
      if e[5]==2:sub_value+=p
      if e[6]&1:cash+=[5940,93600,93600][area];bonus+=[5940,93600,93600][area]
      if e[6]&2:
       reward=math.floor(sub_value*1.2+.5) if area==0 else 31200;cash+=reward;bonus+=reward
    if goal is None and cash>=[19800,312000,4635000][area]:goal={'day':e[8],'active_hours':active/3600,'at_login':e[1]<0}
    if i==len(c['ledger'])//2:half=cash;half_active=active
   results.append({'region':area,'trial':c['trial'],'bait':c['bait'],'table':tag,'policy':policy,'goal':goal,'gross':gross,'bait_cost':baitcost,'passive':passive,'donations':donation_value,'bonuses':bonus,'fishing_gross_per_active_hour':gross/(active/3600),'fishing_net_per_active_hour':(gross-baitcost)/(active/3600),'aq_rate_at_end':rate()})
summary=[]
for area in range(3):
 for tag in ['old','new']:
  for policy in ['sale_only','aquarium']:
   rr=[r for r in results if r['region']==area and r['table']==tag and r['policy']==policy];gg=[r['goal'] for r in rr if r['goal']];days=[g['day'] for g in gg];hours=[g['active_hours'] for g in gg]
   summary.append({'region':area,'table':tag,'policy':policy,'n':len(rr),'goals_reached':len(gg),'median_day':statistics.median(days) if gg else None,'min_day':min(days) if gg else None,'max_day':max(days) if gg else None,'median_active_hours':statistics.median(hours) if gg else None,'median_fishing_net_per_active_hour':statistics.median(r['fishing_net_per_active_hour'] for r in rr)})
x={'draws':parity,'seed_count':5,'bait_types':3,'old_base_prices':OLD,'new_base_prices':NEW,'summary':summary,'results':results,'price_parity_mismatches':0,'ledger_sha256':hashlib.sha256(LEDGER.read_bytes()).hexdigest()};(ROOT/'SIMULATION.json').write_text(json.dumps(x,indent=2)+'\n')
for r in summary:print(r)
