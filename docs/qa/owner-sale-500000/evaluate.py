from pathlib import Path
import json,math,heapq,statistics,hashlib,sys
ROOT=Path(__file__).resolve().parent
LEDGER=Path(sys.argv[1]) if len(sys.argv)>1 else Path('three-region-ledger.json')
TABLES=Path(sys.argv[2]) if len(sys.argv)>2 else ROOT.parent.parent/'qa/three-region-prices/PRICE_TABLES.json'
D=json.loads(LEDGER.read_text());BASE=json.loads(TABLES.read_text())['prices'];G=[1,1.3,1.7,2.2,3];CASES={'current':(16000,20000),'approved500':(40000,500000),'rewarding':(50000,100000),'high':(60000,150000)}
rows=[];encounters=[]
for c in D['cases']:
 if c['region']!=2:continue
 success=sum(e[1]>=0 and e[4] for e in c['ledger']);owners=sum(e[1]==19 and e[4] for e in c['ledger']);encounters.append((success-owners)/owners)
 for name,(valley,tile) in CASES.items():
  for policy in ['linked','separate_income']:
   initial=[BASE[0][19],BASE[1][19],BASE[1][19],BASE[2][19],BASE[2][19]]
   aq=[(round(p*1.15),round(p*1.15)) for p in initial];heapq.heapify(aq);cash=0;active=0;passive=0;goal=None;owner_sales=0
   rate=lambda:sum(v[0] for v in aq)*.15*(8/4*60/52)
   for e in c['ledger']:
    if e[1]<0:
     earn=math.floor(rate()*3);cash+=earn;passive+=earn
    else:
     earn=rate()*e[0]/3600;cash+=earn;passive+=earn;active+=e[0];cash-=[5,15,20][c['bait']]
     price_base=tile if e[1]==19 else BASE[2][e[1]]
     factor=G[e[2]]*min(e[3]**2,2.5)*1.15;p=math.floor(price_base*factor+.5)
     iv=math.floor((BASE[2][19] if policy=='separate_income' and e[1]==19 else price_base)*factor+.5)
     if e[4] and not e[5]:
      if e[1]==19 and iv>aq[0][0]:
       old=heapq.heapreplace(aq,(iv,p));cash+=old[1]
      else:cash+=p
      if e[1]==19:owner_sales+=p
     if e[6]&1:cash+=93600
     if e[6]&2:cash+=31200
    if cash>=4635000:goal={'day':e[8],'active_hours':active/3600,'at_login':e[1]<0};break
   rows.append({'candidate':name,'valley_owner_base':valley,'tile_owner_base':tile,'policy':policy,'trial':c['trial'],'bait':c['bait'],'goal':goal,'passive_earned':passive,'aq_hourly_at_goal':rate()})
summary=[]
for name in CASES:
 for policy in ['linked','separate_income']:
  rr=[r for r in rows if r['candidate']==name and r['policy']==policy];gg=[r['goal'] for r in rr if r['goal']]
  summary.append({'candidate':name,'policy':policy,'median_day':statistics.median(g['day'] for g in gg),'min_day':min(g['day'] for g in gg),'max_day':max(g['day'] for g in gg),'median_active_hours':statistics.median(g['active_hours'] for g in gg),'n':len(rr),'completed':len(gg)})
x={'status':'approved500_linked_implemented_other_candidates_comparison_only','basis_game_source':'6b22974fb502bec3774bc6be7333a2ce68ea0916','owner_candidates':CASES,'median_successful_ordinary_catches_per_owner':statistics.median(encounters),'summary':summary,'results':rows,'ledger_sha256':hashlib.sha256(LEDGER.read_bytes()).hexdigest()};(ROOT/'RESULTS.json').write_text(json.dumps(x,indent=2)+'\n')
print('ordinary catches per owner',x['median_successful_ordinary_catches_per_owner'])
for r in summary:print(r)
