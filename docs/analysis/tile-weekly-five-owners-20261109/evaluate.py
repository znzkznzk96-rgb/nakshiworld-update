from pathlib import Path
import json,math,statistics,sys,heapq
ROOT=Path(__file__).resolve().parent
DATA=json.loads(Path(sys.argv[1] if len(sys.argv)>1 else 'tile-week-ledger.json').read_text());BASE=[25,35,45,50,30,30,50,55,130,145,175,225,150,195,480,560,610,2240,2760,16000];GRADE=[1,1.3,1.7,2.2,3];STAR=[0]*8+[1]*6+[2]*3+[3]*2+[4]
profiles={'current':BASE}
for multi in [2,5,10,15,20,25]:
 for owner in [16000,20000,24000,28000]:
  prices=[round(v*multi*[1,.8,.6,.35][STAR[i]]/10)*10 if i<19 else owner for i,v in enumerate(BASE)];profiles[f'ordinary{multi}_owner{owner}']=prices
profiles['weekly_rounded']=[450,650,800,900,550,550,900,1000,1800,2100,2500,3200,2200,2800,5000,6000,6500,10000,12000,18000]
profiles['weekly_final']=[200,280,360,400,240,240,400,440,850,950,1100,1450,950,1250,2300,2700,2900,6500,8000,18000]
rows=[];parity=0
for c in DATA['cases']:
 for e in c['ledger']:
  if e[1]>=0:assert math.floor(BASE[e[1]]*GRADE[e[2]]*min(e[3]**2,2.5)+.5)==e[7];parity+=1
 for name,prices in profiles.items():
  vals=[math.floor(prices[e[1]]*GRADE[e[2]]*min(e[3]**2,2.5)*1.15+.5) if e[1]>=0 else 0 for e in c['ledger']]
  for mix in ['mixed','five_tile']:
   for boat in [1,2,3]:
    # Fixed5 owner fish, standard size, normal grade, forge3 price. No automatic expansion to20.
    for replace in [False,True]:
     displayed_base=8000+2*16000+2*prices[19] if mix=='mixed' else 5*prices[19]
     aq=([round(8000*1.15)]+[round(16000*1.15)]*2+[round(prices[19]*1.15)]*2) if mix=='mixed' else [round(prices[19]*1.15)]*5;heapq.heapify(aq)
     display_value=sum(aq);mult=(4+2*boat)/4*60/(60-4*boat);rate=display_value*.15*mult
     cash=0;active=0;passive=0;goal=None
     for e,p in zip(c['ledger'],vals):
      if e[1]<0:
       earn=math.floor(rate*8);cash+=earn;passive+=earn
      else:
       earn=rate*e[0]/3600;cash+=earn;passive+=earn;active+=e[0];cash-=[5,15,20][c['bait']];cash+=e[6]
       if e[4] and not e[5]:
        if replace and e[1]==19 and p>aq[0]:cash+=heapq.heapreplace(aq,p);rate=sum(aq)*.15*mult
        else:cash+=p
      if cash>=4635000:
       goal={'day':e[8],'active_hours':active/3600,'at_login':e[1]<0,'cash':cash};break
     rows.append({'profile':name,'replace_owners':replace,'mixture':mix,'boat_expansions':boat,'trial':c['trial'],'bait':c['bait'],'hourly_aquarium_income':rate,'displayed_price_sum':display_value,'goal':goal,'passive_at_goal':passive})
summary=[]
for name in profiles:
 for mix in ['mixed','five_tile']:
  for boat in [1,2,3]:
   for replace in [False,True]:
    rr=[r for r in rows if r['profile']==name and r['mixture']==mix and r['boat_expansions']==boat and r['replace_owners']==replace];gg=[r['goal'] for r in rr if r['goal']];days=[g['day'] for g in gg];hours=[g['active_hours'] for g in gg]
    summary.append({'profile':name,'replace_owners':replace,'mixture':mix,'boat_expansions':boat,'completed':len(gg),'n':len(rr),'median_day':statistics.median(days) if days else None,'min_day':min(days) if days else None,'max_day':max(days) if days else None,'median_active_hours':statistics.median(hours) if hours else None,'median_passive_share':(statistics.median(r['passive_at_goal']/r['goal']['cash'] for r in rr if r['goal']) if gg else None),'around_week_cases':sum(6<=day<=8 for day in days),'hourly_aquarium_income':rr[0]['hourly_aquarium_income']})
out={'source_game_commit':'c74960ababa175a55a40fcd225799c1174e55f43','draws':parity,'seed_count':5,'bait_types':3,'profiles':profiles,'summary':summary,'price_parity_mismatches':0}
(ROOT/'RESULTS.json').write_text(json.dumps(out,indent=2)+'\n')
for s in summary:
 if s['boat_expansions']==2 and s['mixture']=='mixed' and s['replace_owners']:
  other=next(r for r in summary if r['profile']==s['profile'] and r['boat_expansions']==2 and r['mixture']=='five_tile' and r['replace_owners'])
  print(s['profile'],'mixed',s['median_day'],round(s['median_active_hours'] or 0,1),'tile5',other['median_day'],round(other['median_active_hours'] or 0,1),'passive%',round((s['median_passive_share'] or 0)*100),'week',s['around_week_cases'])
