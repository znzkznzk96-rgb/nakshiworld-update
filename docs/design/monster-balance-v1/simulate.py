import json,itertools,math
from pathlib import Path
ROOT=Path(__file__).parent
ROSTER=json.loads((ROOT/'roster.json').read_text())
# All stats are at acquisition level, no level/gear/element multipliers.
BASE=[(190,34,12),(165,38,8),(310,16,36),(325,14,34),(215,23,15),(180,36,10),(245,18,18),(205,22,14),(295,18,38),(230,21,17),(220,32,16),(305,19,32),(235,19,20),(160,40,7),(315,15,40)]
STAR={1:(1,1,1),2:(1.75,1.65,1.35),3:(2.65,2.55,1.75)}
MONSTERS=[('슬라임',65,9,3),('강화슬라임',90,12,7),('얼음슬라임',85,16,5),('박쥐',70,18,2),('흡혈박쥐',105,24,5),('기어다니미',120,23,8),('강화기어다니미',155,30,11),('꼬마골렘',185,26,28),('천유령',130,31,6),('강화천유령',165,38,10),('외눈그림자',145,40,8),('강화외눈그림자',190,47,12),('그림자손',170,42,16),('강화그림자손',225,50,22),('문틈괴물',200,34,25),('강화문틈괴물',240,40,32),('독슬라임',120,25,6),('그림자박쥐',200,51,12)]
BOSSES={'3R':('결정슬라임',290,26,14),'5R':('박쥐우두머리',460,37,20),'7R':('거대골렘',700,49,34),'10R':('그림자왕',1000,70,40)}
ROUNDS=[[1,1,2],[2,3,4],[3,4,'3R'],[5,6,17],[5,7,'5R'],[8,9,9],[8,10,'7R'],[11,12,13],[14,15,18],[15,16,'10R']]
def rnd(v):return math.floor(v+.5)
def unit(i,star):
 hp,atk,defense=[rnd(x*y) for x,y in zip(BASE[i],STAR[star])]
 return dict(id=ROSTER[i]['id'],role=ROSTER[i]['role'],star=star,hp=hp,max_hp=hp,atk=atk,defense=defense,actions=0)
def damage(atk,defense):return max(1,rnd(atk*100/(100+defense)))
def fight(indices,stars,round_no=10,boss_override=None,healing=True):
 party=[unit(i,s) for i,s in zip(indices,stars)];ticks=0;cleared=0;hp_at_boss=None
 for key in ROUNDS[round_no-1]:
  name,hp,atk,defense=(MONSTERS[key-1] if isinstance(key,int) else (boss_override if key=='10R' and boss_override else BOSSES[key]))
  if not isinstance(key,int):hp_at_boss=sum(u['hp'] for u in party)
  while hp>0 and ticks<120:
   alive=[u for u in party if u['hp']>0]
   if not alive:break
   front=alive[0];out=0;heals=[]
   for u in alive:
    u['actions']+=1
    if healing and u['role']=='support' and u['actions']%3==0:heals.append(rnd(u['atk']*.8))
    else:out+=damage(u['atk'],defense)
   # Simultaneous resolution: a monster killed this tick still lands its attack.
   hp-=out;front['hp']=max(0,front['hp']-damage(atk,front['defense']))
   for heal in heals:
    living=[u for u in party if u['hp']>0]
    if living:living[0]['hp']=min(living[0]['max_hp'],living[0]['hp']+heal)
   ticks+=1
  if hp>0 or not any(u['hp']>0 for u in party):break
  cleared+=1
 remaining=sum(u['hp'] for u in party);maximum=sum(u['max_hp'] for u in party)
 return {'clear':cleared==3,'remaining_hp':remaining,'remaining_pct':round(100*remaining/maximum,1),'seconds':round(ticks*1.5,1),'enemies_cleared':cleared,'boss_entry_hp':hp_at_boss,'survivors':sum(u['hp']>0 for u in party)}
GROUPS={role:[i for i,u in enumerate(ROSTER) if u['role']==role] for role in ('defense','attack','support')}
COMBOS=list(itertools.product(GROUPS['defense'],GROUPS['attack'],GROUPS['support']))
def aggregate(stars,boss=None,healing=True):
 rs=[fight(c,stars,boss_override=boss,healing=healing) for c in COMBOS];wins=[r for r in rs if r['clear']]
 return {'tested':len(rs),'clears':len(wins),'composition_clear_pct':round(100*len(wins)/len(rs),1),'min_remaining_pct':min([r['remaining_pct'] for r in wins],default=0),'max_remaining_pct':max([r['remaining_pct'] for r in wins],default=0)}
def main():
 BOSSES['10R']=('그림자왕',1000,70,40)
 results={str(st):aggregate(st) for st in ([1,1,1],[2,1,1],[1,2,1],[1,1,2],[2,2,1],[2,1,2],[1,2,2],[2,2,2],[3,1,1])}
 reference=(3,0,6)
 details={str(st):[fight(reference,st,r) for r in range(1,11)] for st in ([1,1,1],[2,1,1],[2,2,1],[2,2,2])}
 # Enumerate all ordered 3-unit squads (duplicates allowed), with the first two promoted.
 stress={}
 for stars in ([1,1,1],[2,1,1],[1,2,1],[1,1,2],[2,2,1]):
  rs=[fight(c,stars)['clear'] for c in itertools.product(range(15),repeat=3)]
  stress[str(stars)]={'tested':len(rs),'clears':sum(rs),'composition_clear_pct':round(sum(rs)/len(rs)*100,1)}
 output={'boss10':BOSSES['10R'],'balanced_role_compositions':results,'all_ordered_compositions':stress,'reference_ids':[ROSTER[i]['id'] for i in reference],'reference_rounds':details,'support_off_sensitivity':aggregate([2,2,1],healing=False),'interpretation':'composition coverage, not random win probability','assumptions':{'team_size':3,'seconds_per_tick':1.5,'damage':'max(1,round_half_up(ATK*100/(100+DEF)))','simultaneous_damage':True,'support':'every third action replaces attack with 0.8*ATK heal to living frontline','within_round_hp_carries':True,'each_round_benchmark_starts_full':True,'between_round_recovery_policy':'not decided; benchmark full-health is not free recovery rule','level_gear_elements':'excluded','battle_timeout_seconds':180}}
 (ROOT/'results.json').write_text(json.dumps(output,ensure_ascii=False,indent=2))
 soldiers=[{**r,'base':dict(zip(['hp','atk','def'],BASE[i])),'stars':{s:{k:unit(i,int(s))[v] for k,v in [('hp','max_hp'),('atk','atk'),('def','defense')]} for s in ('1','2','3')}} for i,r in enumerate(ROSTER)]
 enemies=[dict(id=i+1,name=n,hp=h,atk=a,defense=d) for i,(n,h,a,d) in enumerate(MONSTERS)]+[dict(id=k,name=v[0],hp=v[1],atk=v[2],defense=v[3]) for k,v in BOSSES.items()]
 (ROOT/'balance.json').write_text(json.dumps({'status':'initial_tuning_not_game_integrated','soldiers':soldiers,'enemies':enemies,'rounds':ROUNDS,'rules':output['assumptions']},ensure_ascii=False,indent=2))
 print(json.dumps({'boss10':BOSSES['10R'],'role_results':results,'reference_10R':{str(s):fight(reference,s) for s in ([1,1,1],[2,1,1],[2,2,1],[2,2,2])},'all_orders':stress},ensure_ascii=False,indent=2))
if __name__=='__main__':main()
