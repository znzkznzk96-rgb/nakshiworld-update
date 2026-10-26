"""Design-only deterministic combat, not Godot gameplay or a retention forecast."""
import json, pathlib, math
OUT=pathlib.Path(__file__).parent
ROSTER=[
 ('붕어 방패병','수호','수호',200,12,30,0),
 ('블루길 창병','맹공','맹공',130,26,10,0),
 ('피라미 척후병','질주','질주',115,23,15,0),
 ('미꾸리 의무병','생명','생명',150,10,18,3),
 ('송사리 등불사','신비','신비',105,28,8,0),
 ('메기 철퇴병','맹공','수호',175,21,22,0),
 ('장어 돌격병','맹공','질주',125,27,12,0),
 ('향어 호위병','수호','생명',190,13,28,1.5),
 ('버들치 전령','질주','생명',135,17,16,2),
 ('달빛 주술사','생명','신비',120,19,12,2),
]
NAMES=['젖은 현관','비어 있는 탈의실','반복되는 세면대','꺼지지 않는 복도','거울 없는 세면실','잠긴 관리실','물소리 나는 계단','끝없는 여과실','돌아오는 복도','출구를 닮은 문']
# Enemy HP is the stage obstruction meter; ATK/DEF are its resistance.
STAGES=[(160,12,0),(260,18,3),(420,26,6),(650,36,9),(950,49,12),(1350,65,16),(1850,84,20),(2500,108,24),(3300,138,28),(4300,175,32)]
def stats(unit,lv=1,star=1,region=0):
 u=ROSTER[unit];f=(1+.12*(lv-1))*[0,1,1.6,2.35][star]*(1.6 if region==1 else 1)
 return dict(name=u[0],hp=u[3]*f,atk=u[4]*f,defense=u[5]*f,heal=u[6]*f)
def fight(team,stage):
 hp=sum(x['hp'] for x in team);full=hp;enemy,atk,defense=STAGES[stage];total=enemy
 armor=sum(x['defense'] for x in team)/len(team)
 damage=sum(x['atk'] for x in team)*100/(100+defense)
 incoming=atk*100/(100+armor)
 heal=sum(x['heal'] for x in team)
 for sec in range(1,46):
  enemy=max(0,enemy-damage)
  if enemy==0:return dict(win=True,ticks=sec,battle_seconds=sec*2,hp_pct=round(100*hp/full,1),progress=100)
  hp=min(full,hp-incoming+heal)
  if hp<=0:return dict(win=False,ticks=sec,battle_seconds=sec*2,hp_pct=0,progress=round(100*(1-enemy/total),1))
 return dict(win=False,ticks=45,battle_seconds=90,hp_pct=round(100*hp/full,1),progress=round(100*(1-enemy/total),1))
def costs(lv):return sum(80+40*(n-1) for n in range(1,lv))
def main():
 cases={
 'starter_1star_lv1':[(0,1,1,0),(1,1,1,0),(3,1,1,0)],
 'reservoir_1star_lv5':[(0,5,1,0),(1,5,1,0),(3,5,1,0)],
 'reservoir_2star_lv8':[(0,8,2,0),(1,8,2,0),(3,8,2,0)],
 'reservoir_3star_lv10':[(0,10,3,0),(1,10,3,0),(3,10,3,0)],
 'valley_1star_lv5':[(0,5,1,1),(1,5,1,1),(3,5,1,1)],
 'valley_2star_lv8':[(0,8,2,1),(1,8,2,1),(3,8,2,1)],
 'mixed_two_valley_2star_lv8':[(0,8,2,1),(1,8,2,1),(3,8,2,0)],
 'mixed_two_valley_2star_lv10':[(0,10,2,1),(1,10,2,1),(3,8,2,0)],
 }
 results={}
 for name,c in cases.items():
  team=[stats(*a) for a in c];results[name]={'team':team,'level_gold':sum(costs(a[1]) for a in c),'stages':[fight(team,i) for i in range(10)]}
 # 5 common families across regions, preserving fish ID as inventory metadata.
 groups={'맹공':[4,12,14,15],'수호':[1,6,8,11],'질주':[0,7,13,16],'생명':[3,5,9,17],'신비':[2,10,18]}
 assert sorted(sum(groups.values(),[]))==list(range(19))
 stars=[[0,1,2,3,4,5,6,7],[8,9,10,11,12,13],[14,15,16],[17,18]]
 drop={'맹공':.16,'수호':.15,'질주':.16,'생명':.18,'신비':.25}
 supply={}
 for stock in [1,.7]:
  probs=[a*(.04+.96*stock)**i for i,a in enumerate([.45,.35,.15,.05])];probs=[p/sum(probs) for p in probs]
  supply[str(stock)]={g:sum(probs[i]/len(ids) for i,ids in enumerate(stars) for sp in ids if sp in members)*drop[g] for g,members in groups.items()}
 for case in results.values():
  assert all(0<=x['progress']<=100 and 0<=x['hp_pct']<=100 for x in case['stages'])
 # Stronger matched teams should not turn a victory into defeat.
 for stage in range(10):
  for lv in range(1,15):
   a=fight([stats(u,lv,2) for u in [0,1,3]],stage)
   b=fight([stats(u,lv+1,2) for u in [0,1,3]],stage)
   assert not a['win'] or b['win']
 data={'model':'proposal-v1','roster':ROSTER,'combat_tick_seconds':2,'travel_seconds':5,'stage_names':NAMES,'stages':STAGES,'cases':results,'soul_supply_per_successful_catch':supply,'drop_rates':drop,'groups':groups}
 (OUT/'model-results.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
 for n,c in results.items(): print(n,''.join('O' if x['win'] else '-' for x in c['stages']),c['stages'][-1],c['level_gold'])
 print('soul',supply)
if __name__=='__main__':main()
