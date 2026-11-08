"""Paired fee-grid replay. Input traces are immutable, production code untouched."""
import argparse,gzip,hashlib,heapq,json,math,statistics,time
from pathlib import Path
P=argparse.ArgumentParser()
P.add_argument('--ledger-dir',required=True)
P.add_argument('--output-dir',default=str(Path(__file__).parent))
P.add_argument('--offline-hours',type=float,default=3)
P.add_argument('--income-bases',default='20000,40000,60000')
P.add_argument('--fees',default='4635000,'+','.join(str(x*1000000) for x in range(6,31))+',35000000,40000000')
A=P.parse_args(); OUT=Path(A.output_dir);OUT.mkdir(parents=True,exist_ok=True)
BASES=sorted(set(map(int,A.income_bases.split(','))))
FEES=sorted(set(map(int,A.fees.split(','))))
PREV=Path(__file__).parent.parent/'owner-income-unlock-20261109'
FIXED=Path(__file__).parent.parent/'owner-income-fixed-fee-20261109'
BASE=json.loads((PREV/'PRICE_INPUT.json').read_text())['prices']
META=json.loads((PREV/'LEDGER_META.json').read_text())
D=[];HASHES={};DRAWS=0
for m in META:
    f=Path(A.ledger_dir)/m['file'];h=hashlib.sha256(f.read_bytes()).hexdigest()
    assert h==m['sha256'],'Stop: input trace hash mismatch'
    d=json.loads(f.read_text());D+=d['cases'];DRAWS+=d['draws'];HASHES[f.name]=h
GRADE=[1,1.3,1.7,2.2,3]
POLICIES=['sell_new','income_greedy','roi_7day','income_greedy_no_owner','roi_1day','roi_2day']
VARIANTS={'slow':[('slow_20',20,5)],'reference':[('reference_5',5,2),('reference_20',20,5)],
          'fast':[('fast_20',20,5)],'max_upgrades':[('max_20',20,5)]}
def rnd(v):return math.floor(v+.5)
def replay(events,inc,factor,slots,boat,initial,policy,bait):
    mult=.15*((4+2*boat)/4*60/(60-4*boat))
    active={};owners={};heap=[];uid=0;income_sum=0
    def put(sp,sale,value):
        nonlocal uid,income_sum
        active[uid]=(sp,sale,value);heapq.heappush(heap,(value,uid))
        if sp%20==19:owners[sp]=uid
        income_sum+=value;uid+=1
    if initial!='none':
        for r in range(3):
            sale=rnd(([8000,16000,20000][r] if initial=='legacy' else BASE[r][19])*factor)
            put(r*20+19,sale,min(sale,rnd([8000,40000,inc][r]*factor)))
    while len(active)<5:
        sp=58 if len(active)%2 else 57;sale=rnd(BASE[2][sp%20]*factor);put(sp,sale,sale)
    cash=online=credited=session=0.;sale_owner=sale_ordinary=0
    aq_online=0.;aq_offline=bait_cost=0;goals=[None]*len(FEES);idx=0
    for dt,sp,success,sale,value,day in events:
        if sp<0:
            amount=int(A.offline_hours//3)*math.floor(income_sum*mult*3)+math.floor(income_sum*mult*(A.offline_hours%3))
            cash+=amount;aq_offline+=amount;credited+=A.offline_hours;session=0
        else:
            amount=income_sum*mult*dt/3600;cash+=amount;aq_online+=amount
            online+=dt;credited+=dt/3600;session+=dt
            cost=[5,15,20][bait];cash-=cost;bait_cost+=cost
            if success:
                retained=False
                if policy!='sell_new' and not (policy=='income_greedy_no_owner' and sp%20==19):
                    same=owners.get(sp) if sp%20==19 else None
                    while heap and heap[0][1] not in active:heapq.heappop(heap)
                    old_id=same if same is not None else (None if len(active)<slots else heap[0][1])
                    old=active.get(old_id,(None,0,0))
                    if value>old[2]:
                        payback=(sale-old[1])/((value-old[2])*mult)
                        horizon={'roi_1day':1,'roi_2day':2,'roi_7day':7}.get(policy,7)
                        if policy.startswith('income_greedy') or payback<=max(0,horizon*(3+A.offline_hours)-credited):
                            if old_id is not None:
                                active.pop(old_id);cash+=old[1]
                                if old[0]%20==19:sale_owner+=old[1];owners.pop(old[0],None)
                                else:sale_ordinary+=old[1]
                                income_sum-=old[2]
                            put(sp,sale,value);retained=True
                if not retained:
                    cash+=sale
                    if sp%20==19:sale_owner+=sale
                    else:sale_ordinary+=sale
        while idx<len(FEES) and cash>=FEES[idx]:
            assert abs(cash-(sale_owner+sale_ordinary+aq_online+aq_offline-bait_cost))<.001
            assert len(owners)==sum(sp%20==19 for sp,_,_ in active.values())
            goals[idx]=[day,min(1.,session/10800),online/3600,cash,sale_owner,sale_ordinary,aq_online,aq_offline,bait_cost]
            idx+=1
        if idx==len(FEES):break
    # All fee goals in one path must be reached in chronological order.
    gg=[g for g in goals if g]
    assert all(x[:2]<=y[:2] for x,y in zip(gg,gg[1:]))
    return goals
start=time.time();paths=[];price_samples=0;price_mismatches=0
for inc in BASES:
    for c in D:
        factor=1+.05*c['profile']['forge'];events=[]
        for e in c['ledger']:
            if e[1]<0:events.append((e[0],-1,False,0,0,e[8]));continue
            sale=rnd(BASE[2][e[1]]*GRADE[e[2]]*min(e[3]**2,2.5)*factor)
            value=rnd(inc*GRADE[e[2]]*min(e[3]**2,2.5)*factor) if e[1]==19 else sale
            if inc==BASES[0]:price_samples+=1;price_mismatches+=int(sale!=e[7])
            events.append((e[0],40+e[1],bool(e[4] and e[5]!=1),sale,value,e[8]))
        for variant,slots,boat in VARIANTS[c['profile']['id']]:
            for initial in (['none','legacy','current'] if c['profile']['id']=='reference' else ['none','current']):
                for policy in POLICIES:
                    paths.append(dict(income_base=inc,profile=variant,initial=initial,policy=policy,
                                      trial=c['trial'],bait=c['bait'],goals=replay(events,inc,factor,slots,boat,initial,policy,c['bait'])))
    print('BASIS_COMPLETE',inc,'SECONDS',round(time.time()-start,1),flush=True)
assert price_mismatches==0
def pct(v,p):
    s=sorted(v);return s[int((len(s)-1)*p)]
def stats(goals):
    g=[x for x in goals if x];days=[x[0] if x else 15 for x in goals]
    return dict(n=len(goals),completed=len(g),median_day=statistics.median(days),
                p10_day=pct(days,.1),p90_day=pct(days,.9),min_day=min(days),max_day=max(days),
                median_active_hours=statistics.median(x[2] for x in g) if g else None,
                mean_goal_sources=[statistics.mean(x[i] for x in g) for i in range(3,9)] if g else None,
                mean_owner_income_share=statistics.mean(x[4]/sum(x[4:8]) for x in g) if g else None)
groups={}
for r in paths:
    k=(r['income_base'],r['profile'],r['initial']);groups.setdefault(k,[]).append(r)
summary=[];policy_summary=[]
for k,rr in groups.items():
    for fi,fee in enumerate(FEES):
        by_seed={}
        for r in rr:
            sk=(r['trial'],r['bait']);g=r['goals'][fi]
            if sk not in by_seed or (g and (not by_seed[sk] or g[:2]<by_seed[sk][:2])):by_seed[sk]=g
        summary.append(dict(zip(['income_base','profile','initial'],k),fee=fee,**stats(list(by_seed.values()))))
        for policy in POLICIES:
            policy_summary.append(dict(zip(['income_base','profile','initial'],k),fee=fee,policy=policy,
                                       **stats([r['goals'][fi] for r in rr if r['policy']==policy])))
parity=0
if A.offline_hours==3 and 4635000 in FEES:
    old=json.loads(gzip.decompress((FIXED/'RESULTS.json.gz').read_bytes()))
    look={(r['income_base'],r['profile'],r['initial']):r for r in old['summary']}
    for r in summary:
        if r['fee']!=4635000:continue
        prior=look[r['income_base'],r['profile'],r['initial']]
        for field in ['median_day','p10_day','p90_day','min_day','max_day','completed','median_active_hours']:
            assert r[field]==prior[field],(field,r,prior)
        parity+=1
look={(r['income_base'],r['fee'],r['profile'],r['initial']):r for r in summary};ranking=[]
for inc in BASES:
    for fee in FEES:
        ref=[look[inc,fee,'reference_20',i] for i in ['none','legacy','current']]
        med=statistics.mean(r['median_day'] for r in ref)
        fast=statistics.mean(look[inc,fee,'max_20',i]['median_day'] for i in ['none','current'])
        slow=statistics.mean(look[inc,fee,'slow_20',i]['median_day'] for i in ['none','current'])
        censored=sum(r['n']-r['completed'] for r in ref)
        score=abs(med-7)+.35*max(0,5-min(r['p10_day'] for r in ref))+.3*max(0,max(r['p90_day'] for r in ref)-9)+.5*max(0,4.5-fast)+.25*max(0,slow-11)+censored*.1
        ranking.append(dict(income_base=inc,fee=fee,score=score,reference_mean_median=med,
                            reference_none_median=ref[0]['median_day'],fast_median=fast,slow_median=slow,censored=censored))
ranking.sort(key=lambda r:(r['score'],r['fee'],r['income_base']))
result=dict(fees=FEES,income_bases=BASES,owner_sale_bases=[8000,40000,500000],other_owner_income_bases=[8000,40000],
            offline_hours=A.offline_hours,policies=POLICIES,trace_hashes=HASHES,trace_draws_reused=DRAWS,new_draws=0,
            traces=len(D),economic_paths=len(paths),threshold_evaluations=len(paths)*len(FEES),
            price_parity_samples=price_samples,price_mismatches=price_mismatches,fixed_fee_parity_groups=parity,
            summary=summary,policy_summary=policy_summary,ranking=ranking,
            goal_columns=['day','session_fraction','active_hours','cash','owner_sales','ordinary_sales','aquarium_online','aquarium_offline','bait_cost'],
            cash_conservation=True,owner_cap_assertions=True,fee_chronology=True,source_commit='fe95f5593f6ba2a133caf81cee69bd70bf00cf15',
            duration_seconds=time.time()-start,game_changed=False,deployed=False)
(OUT/'RESULTS.json.gz').write_bytes(gzip.compress(json.dumps(result,ensure_ascii=False,indent=2).encode(),mtime=0))
(OUT/'PATHS.json.gz').write_bytes(gzip.compress(json.dumps(paths,separators=(',',':')).encode(),mtime=0))
print('TOP',json.dumps(ranking[:15]),flush=True)
