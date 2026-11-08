"""Paired replay of verified Godot traces; never changes production balance."""
import argparse, hashlib, heapq, json, math, statistics, time
from pathlib import Path

P = argparse.ArgumentParser()
P.add_argument('--ledger-dir', required=True)
P.add_argument('--output-dir', default=str(Path(__file__).parent))
P.add_argument('--offline-hours', type=float, default=3)
P.add_argument('--valley-base', type=int, default=40000)
A = P.parse_args()
OUT = Path(A.output_dir); OUT.mkdir(parents=True, exist_ok=True)
PREV = Path(__file__).parent.parent / 'owner-income-unlock-20261109'
BASE = json.loads((PREV/'PRICE_INPUT.json').read_text())['prices']
META = json.loads((PREV/'LEDGER_META.json').read_text())
TRACE = []; HASHES = {}; DRAWS = 0
for m in META:
    f = Path(A.ledger_dir)/m['file']
    h = hashlib.sha256(f.read_bytes()).hexdigest()
    assert h == m['sha256'], 'Stop: trace checksum mismatch'
    d = json.loads(f.read_text()); TRACE += d['cases']; DRAWS += d['draws']
    HASHES[f.name] = h
FEE = 4635000
BASES = [0,10000,20000,40000,60000,100000,500000]
POLICIES = ['sell_new','income_greedy','roi_7day','income_greedy_no_owner','roi_1day','roi_2day']
VARIANTS = {'slow':[('slow_20',20,5)],
            'reference':[('reference_5',5,2),('reference_20',20,5)],
            'fast':[('fast_20',20,5)],'max_upgrades':[('max_20',20,5)]}
GRADE = [1,1.3,1.7,2.2,3]
def rnd(v): return math.floor(v+.5)
def replay(events, inc, factor, slots, boat, initial, policy, bait, no_aquarium=False):
    mult = 0 if no_aquarium else .15*((4+2*boat)/4*60/(60-4*boat))
    active={}; owners={}; heap=[]; uid=0; income_sum=0
    def put(sp,sale,value):
        nonlocal uid,income_sum
        active[uid]=(sp,sale,value); heapq.heappush(heap,(value,uid))
        if sp%20==19: owners[sp]=uid
        income_sum+=value; uid+=1
    if initial!='none':
        for r in range(3):
            sale=rnd(([8000,16000,20000][r] if initial=='legacy' else BASE[r][19])*factor)
            ib=([8000,40000,500000] if inc==500000 else [8000,A.valley_base,inc])[r]
            put(r*20+19,sale,min(sale,rnd(ib*factor)))
    while len(active)<5:
        sp=58 if len(active)%2 else 57; sale=rnd(BASE[2][sp%20]*factor)
        put(sp,sale,sale)
    initial_asset=sum(x[1] for x in active.values())
    cash=online=credited=session=0.; goal=None; day7=None
    totals=dict(sale_owner=0,sale_ordinary=0,sale_replaced_owner=0,
                sale_replaced_ordinary=0,online_aquarium=0.,offline_aquarium=0,bait_cost=0)
    caught_owner=0; sold_owner=0; donated=0; decisions=0
    def snapshot(day):
        aquarium_assets=sum(x[1] for x in active.values())
        # Cash conservation and specimen-asset conservation are separate.
        balance=sum(v for k,v in totals.items() if k!='bait_cost')-totals['bait_cost']
        assert abs(cash-balance)<.001
        assert len(owners)==sum(sp%20==19 for sp,_,_ in active.values())
        return dict(day=day,active_hours=online/3600,session_fraction=min(1.,session/10800),
                    cash=cash,totals=totals.copy(),owners_caught=caught_owner,
                    owners_sold=sold_owner,donations=donated,displayed=len(active),
                    displayed_owners=len(owners),hourly_income=income_sum*mult,
                    initial_asset=initial_asset,aquarium_asset=aquarium_assets)
    for dt,sp,success,sale,value,day,was_caught,mandatory in events:
        if day>7 and day7 is None: day7=snapshot(7)
        if sp<0:
            amount=int(A.offline_hours//3)*math.floor(income_sum*mult*3)+math.floor(income_sum*mult*(A.offline_hours%3))
            cash+=amount; totals['offline_aquarium']+=amount
            credited+=A.offline_hours; session=0
        else:
            amount=income_sum*mult*dt/3600; cash+=amount; totals['online_aquarium']+=amount
            online+=dt; credited+=dt/3600; session+=dt
            cost=[5,15,20][bait]; cash-=cost; totals['bait_cost']+=cost
            caught_owner+=int(was_caught and sp%20==19)
            donated+=int(was_caught and mandatory)
            if success:
                retained=False
                if policy!='sell_new' and not no_aquarium and not (policy=='income_greedy_no_owner' and sp%20==19):
                    same=owners.get(sp) if sp%20==19 else None
                    while heap and heap[0][1] not in active: heapq.heappop(heap)
                    old_id=same if same is not None else (None if len(active)<slots else heap[0][1])
                    old=active.get(old_id,(None,0,0))
                    if value>old[2]:
                        payback=(sale-old[1])/((value-old[2])*mult)
                        horizon={'roi_1day':1,'roi_2day':2,'roi_7day':7}.get(policy,7)
                        if policy.startswith('income_greedy') or payback<=max(0,horizon*(3+A.offline_hours)-credited):
                            if old_id is not None:
                                active.pop(old_id); cash+=old[1]
                                key='sale_replaced_owner' if old[0]%20==19 else 'sale_replaced_ordinary'
                                totals[key]+=old[1]
                                if old[0]%20==19: owners.pop(old[0],None)
                                income_sum-=old[2]
                            put(sp,sale,value); retained=True; decisions+=1
                if not retained:
                    cash+=sale; key='sale_owner' if sp%20==19 else 'sale_ordinary'
                    totals[key]+=sale; sold_owner+=int(sp%20==19)
        if goal is None and cash>=FEE: goal=snapshot(day)
        if day>7 and goal is not None: break
    if day7 is None: day7=snapshot(min(day,7))
    return dict(goal=goal,day7=day7,decisions=decisions)

start=time.time(); rows=[]; parity_samples=0; price_mismatches=0
for inc in BASES:
    for c in TRACE:
        factor=1+.05*c['profile']['forge']; events=[]
        for e in c['ledger']:
            if e[1]<0:
                events.append((e[0],-1,False,0,0,e[8],False,False)); continue
            q=GRADE[e[2]]*min(e[3]**2,2.5)*factor
            # Preserve Godot multiplication order before rounding (.5 boundaries).
            sale=rnd(BASE[2][e[1]]*GRADE[e[2]]*min(e[3]**2,2.5)*factor)
            value=rnd(inc*GRADE[e[2]]*min(e[3]**2,2.5)*factor) if e[1]==19 else sale
            if inc==0: parity_samples+=1; price_mismatches+=int(sale!=e[7])
            events.append((e[0],40+e[1],bool(e[4] and e[5]!=1),sale,value,e[8],bool(e[4]),e[5]==1))
        for variant,slots,boat in VARIANTS[c['profile']['id']]:
            initials=['none','legacy','current'] if c['profile']['id']=='reference' else ['none','current']
            for initial in initials:
                for policy in POLICIES:
                    r=replay(events,inc,factor,slots,boat,initial,policy,c['bait'])
                    rows.append(dict(income_base=inc,profile=variant,initial=initial,policy=policy,
                                     trial=c['trial'],bait=c['bait'],**r))
        if inc==0:
            r=replay(events,0,factor,20,5,'none','sell_new',c['bait'],True)
            rows.append(dict(income_base=-1,profile=c['profile']['id']+'_no_aquarium',
                             initial='none',policy='sell_new',trial=c['trial'],bait=c['bait'],**r))
    print('COMPLETED BASIS',inc,'SECONDS',round(time.time()-start,1),flush=True)
assert price_mismatches==0
def percentile(v,p):
    s=sorted(v); return s[int((len(s)-1)*p)]
def summarize(rr):
    goals=[r['goal'] for r in rr if r['goal']]
    days=[r['goal']['day'] if r['goal'] else 15 for r in rr]
    return dict(n=len(rr),completed=len(goals),median_day=statistics.median(days),
                p10_day=percentile(days,.1),p90_day=percentile(days,.9),
                min_day=min(days),max_day=max(days),
                median_active_hours=statistics.median(g['active_hours'] for g in goals),
                median_goal_totals={k:statistics.median(g['totals'][k] for g in goals) for k in goals[0]['totals']},
                median_owners_caught=statistics.median(g['owners_caught'] for g in goals),
                median_owners_sold=statistics.median(g['owners_sold'] for g in goals),
                median_day7_cash=statistics.median(r['day7']['cash'] for r in rr))
groups={}
for r in rows:
    k=(r['income_base'],r['profile'],r['initial'],r['policy']); groups.setdefault(k,[]).append(r)
policy_summary=[dict(zip(['income_base','profile','initial','policy'],k),**summarize(rr)) for k,rr in groups.items()]
best={}
for r in rows:
    k=(r['income_base'],r['profile'],r['initial'],r['trial'],r['bait'])
    def order(x):
        g=x['goal']; return (g['day'],g['session_fraction'],g['active_hours']) if g else (15,1,99)
    if k not in best or order(r)<order(best[k]):best[k]=r
groups={}
for k,r in best.items():groups.setdefault(k[:3],[]).append(r)
summary=[dict(zip(['income_base','profile','initial'],k),**summarize(rr)) for k,rr in groups.items()]
prev=json.loads((PREV/'SEARCH_RESULTS.json').read_text())
# Check prior search using its original three policies; extra policies are new.
oldbest={}
for r in rows:
    if r['policy'] not in ['sell_new','income_greedy','roi_7day']:continue
    k=(r['income_base'],r['profile'],r['initial'],r['trial'],r['bait'])
    if k not in oldbest or order(r)<order(oldbest[k]):oldbest[k]=r
oldgroups={}
for k,r in oldbest.items():oldgroups.setdefault(k[:3],[]).append(r)
look={k:summarize(rr) for k,rr in oldgroups.items()}
parity=[]
for old in prev['summary']:
    if A.offline_hours!=3:continue
    if old['fee']!=FEE or old['income_base'] not in BASES:continue
    if A.valley_base!=16000 and old['initial']!='none' and old['income_base']!=500000:continue
    new=look[old['income_base'],old['profile'],old['initial']]
    for field in ['median_day','p10_day','p90_day','min_day','max_day','completed']:
        assert new[field]==old[field],(field,old,new)
    # Old search multiplied a precombined q; exact game-order rounding is used here.
    assert abs(new['median_active_hours']-old['median_active_hours'])<.02
    parity.append([old['income_base'],old['profile'],old['initial']])
result=dict(fee=FEE,owner_sale_bases=[8000,40000,500000],
            detached_other_owner_bases=[8000,A.valley_base],tile_owner_income_bases=BASES,
            zero_basis_diagnostic=True,no_aquarium_income_counterfactual=True,
            offline_credit_hours=A.offline_hours,trace_draws_reused=DRAWS,new_godot_draws=0,
            traces=len(TRACE),economic_paths=len(rows),summary=summary,policy_summary=policy_summary,
            policies=POLICIES,
            price_parity_samples=parity_samples,price_mismatches=price_mismatches,
            prior_fixed_fee_parity_groups=len(parity),trace_hashes=HASHES,
            source_commit='fe95f5593f6ba2a133caf81cee69bd70bf00cf15',
            duration_seconds=time.time()-start,game_changed=False,deployed=False)
(OUT/'RESULTS.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
(OUT/'PATHS.json').write_text(json.dumps(rows,ensure_ascii=False,separators=(',',':'))+'\n')
for r in summary:
    if r['initial']=='none': print(r['income_base'],r['profile'],r['median_day'],round(r['median_active_hours'],3),flush=True)
