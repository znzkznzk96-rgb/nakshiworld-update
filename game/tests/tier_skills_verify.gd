extends SceneTree
const Model=preload('res://addons/expedition/model.gd')
var checks:int=0
var failures:Array=[]
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label)
func setup(id:int,star:int,pos:int=2):
 var m=Model.new()
 for i in 3:
  m.soldiers.append({"uid":i+1,"id":id if i==pos else 0,"star":star,"level":3,"iv":[0,0,0],"locked":false})
 m.team=[1,2,3];m.start(1,0)
 m.battle.phase='fight';m.battle.enemy.hp=1000000;m.battle.enemy.max_hp=1000000;m.battle.enemy.atk=1
 for f in m.battle.fighters:f.hp=int(f.max_hp)*.5
 return m
func _init():
 for star in [1,2,3]:
  for id in 15:
   for pos in 3:
    var m=setup(id,star,pos)
    for n in 200:m.update(.1,n*.1)
    var f:Dictionary=m.battle.fighters[pos]
    check(int(f.skill_count)>0,'cast %d %d %d'%[star,id,pos])
    check(float(f.shield)<=float(f.max_hp)*.35+1,'shield cap')
    var restored=Model.new();restored.restore(JSON.parse_string(JSON.stringify(m.serialize())))
    for n in 20:m.update(.1,21+n*.1);restored.update(.1,21+n*.1)
    if not equivalent(m.battle,restored.battle):
     print('SAVE_PARITY_MISMATCH')
    if not equivalent(m.battle,restored.battle):
     print('FAILED CASE ',star,' ',id,' ',pos);quit(1);return
    check(true,'save parity')
 # All 45 texture resources resolve to nonempty square transparent atlases.
 for star in [1,2,3]:
  for id in 15:
   var tex=load('res://art/ui/soldier_skills/tiered/t%d_%02d.tres'%[star,id])
   check(tex is AtlasTexture and tex.get_width()==tex.get_height(),'icon '+str(star)+'/'+str(id))
 # exact 7 second CD: assassin 2star at 3,10,17.
 var m=setup(13,2)
 for n in 171:m.update(.1,n*.1)
 var times:Array=[]
 for e in m.battle.skill_casts:
  if int(e.uid)==3:times.append(snappedf(float(e.time),.1))
 check(times==[3.0,10.0,17.0],'seconds not attack count '+str(times))
 # New encounter starts clocks fresh.
 m.spawn_enemy();check(float(m.battle.enemy_ready)==1.5,'reset enemy schedule')
 # Stats scale actual skill damage.
 var a=setup(0,3);var b=setup(0,3)
 b.battle.fighters[2].atk*=2
 a.TIER_SKILLS.cast(a,a.battle.fighters[2]);b.TIER_SKILLS.cast(b,b.battle.fighters[2])
 check(abs(int(b.battle.fighters[2].skill_damage)-2*int(a.battle.fighters[2].skill_damage))<=1,'stat scaling')
 # A running pre-update battle remains on its original engine.
 var old=setup(0,2);old.battle.erase('tier_skill_revision')
 check(not old.TIER_SKILLS.enabled(old),'old battle compatibility')
 print('TIER_SKILLS_VERIFY failures=',failures,' checks=',checks)
 quit(0 if failures.is_empty() else 1)

func equivalent(a,b)->bool:
 if a is Dictionary:
  if not b is Dictionary or a.size()!=b.size():return false
  for k in a:
   if not b.has(k) or not equivalent(a[k],b[k]):return false
  return true
 if a is Array:
  if not b is Array or a.size()!=b.size():return false
  for i in a.size():
   if not equivalent(a[i],b[i]):return false
  return true
 if (a is float or a is int) and (b is float or b is int):return abs(float(a)-float(b))<.000001
 return a==b
