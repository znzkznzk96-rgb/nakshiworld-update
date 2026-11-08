import json,math,statistics,hashlib
from pathlib import Path
import sys
ledger=Path(sys.argv[1]);tables=Path(sys.argv[2]);D=json.loads(ledger.read_text());BASE=json.loads(tables.read_text())['prices']
BASE[1][-1]=40000;BASE[2][-1]=500000
rows=[]
for c in D['cases']:
 area=c['region'];fee=[19800,312000,4635000][area];forge=[0,1,3][area];factor=1+.05*forge
 for initial in ['legacy_owners','current_owners','no_owners']:
  for policy in ['sell_all_new','replace_owner']:
   # 5 displayed fish, each owner species at most once; region-appropriate boat2 already paid.
   aq=[]
   for r in range(area+1):
    if initial=='no_owners':break
    aq.append((r*20+19,round(([8000,16000,20000][r] if initial=='legacy_owners' else BASE[r][19])*factor)))
   while len(aq)<5:aq.append((area*20+18,round(BASE[area][18]*factor)))
   cash=0.;active=0.;goal=None;owners=0;passive=0.;new_sales=0.
   for e in c['ledger']:
    rate=sum(p for sp,p in aq)*.15*(8/4*60/52)
    earn=math.floor(rate*3) if e[1]<0 else rate*e[0]/3600
    cash+=earn;passive+=earn
    if e[1]>=0:
     active+=e[0];cash-=[5,15,20][c['bait']]
     p=math.floor(BASE[area][e[1]]*[1,1.3,1.7,2.2,3][e[2]]*min(e[3]**2,2.5)*factor+.5)
     if e[4] and not e[5]:
      if e[1]==19:owners+=1
      same=next((i for i,(sp,v) in enumerate(aq) if sp==area*20+19),None)
      if policy=='replace_owner' and e[1]==19 and (same is None or p>aq[same][1]):
       ix=same if same is not None else min(range(len(aq)),key=lambda i:aq[i][1]);cash+=aq[ix][1];aq[ix]=(area*20+19,p)
      else:cash+=p;new_sales+=p
     if e[6]&1:cash+=[5940,93600,93600][area]
     if e[6]&2:cash+=[0,31200,31200][area] # reservoir variable-value reward omitted, conservative.
    if cash>=fee:goal={'day':e[8],'active_hours':active/3600,'cash':cash};break
   rows.append({'region':area,'initial':initial,'policy':policy,'trial':c['trial'],'bait':c['bait'],'goal':goal,'owners_caught':owners,'passive':passive,'sale':new_sales})
summary=[]
for area in range(3):
 for init in ['legacy_owners','current_owners','no_owners']:
  for pol in ['sell_all_new','replace_owner']:
   rr=[r for r in rows if r['region']==area and r['initial']==init and r['policy']==pol];gg=[r['goal'] for r in rr if r['goal']]
   summary.append({'region':area,'initial':init,'policy':pol,'completed':len(gg),'n':len(rr),'median_day':statistics.median(x['day'] for x in gg) if gg else None,'min_day':min((x['day'] for x in gg),default=None),'max_day':max((x['day'] for x in gg),default=None),'median_active_hours':statistics.median(x['active_hours'] for x in gg) if gg else None})
out={'summary':summary,'cases':rows,'actual_godot_draws':D['draws'],'ledger_sha256':hashlib.sha256(ledger.read_bytes()).hexdigest(),'limitations':['trace replay, catch outcomes fixed; prices/one-per-owner-species updated','3h/day online, once/day login then3h offline credit, 5slots/boat2 assumed already paid','zero cash; equipment acquisition/mandatory license completion not simulated','reservoir variable side bundle reward omitted','no offline robot catches; no expedition grants or travel/bag/menu time','goal is money threshold only; region3 remains preparation']};Path('critical-economy-sim.json').write_text(json.dumps(out,indent=2)+'\n')
for x in summary:print(x)
