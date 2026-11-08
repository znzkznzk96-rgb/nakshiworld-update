extends SceneTree
func _initialize():call_deferred('run')
func run():
 var failures:Array=[];var rng:=RandomNumberGenerator.new();rng.seed=20261109
 var rows:Array=[];var wins:=0;var ticks_total:=0;var max_ticks:=0;var reloads:=0
 for trial in 3000:
  var d=load('res://addons/expedition/model.gd').new();d.rng.seed=20261109+trial;d.unlocked=10
  var star:int=1+trial%3;var level:int=trial%4;var round_no:int=1+trial%10
  for j in 3:
   var u:Dictionary=d.add_unit(rng.randi_range(0,14),star,[rng.randi_range(0,8),rng.randi_range(0,8),rng.randi_range(0,8)]);u.level=level;d.team.append(u.uid)
  if not d.start(round_no,1000):failures.append('start %d'%trial);break
  var ticks:=0
  while d.active() and ticks<1800:
   if d.battle.phase=='approach':d.battle.phase='fight'
   d.tick();ticks+=1
   for f in d.battle.fighters:
    if int(f.hp)<0 or int(f.hp)>int(f.max_hp) or int(f.shield)<0:failures.append('invalid stats %d'%trial)
   if d.battle.phase=='death':
    d.battle.index+=1
    if int(d.battle.index)>=3:d.finish(true,1000)
    else:d.spawn_enemy()
   elif d.battle.phase=='defeat':d.finish(false,1000)
   if ticks%50==0:
    var state:Dictionary=d.serialize().duplicate(true);var backup=load('res://addons/expedition/model.gd').new();backup.restore(state)
    if backup.serialize()!=state:failures.append('reload mismatch %d'%trial)
    reloads+=1
  if d.active():failures.append('nontermination %d'%trial)
  var win:bool=d.battle.status=='win';wins+=int(win);ticks_total+=ticks;max_ticks=maxi(max_ticks,ticks)
  var reward:Dictionary=d.claim();var pouches:int=d.pouches
  if reward.is_empty() or int(reward.gold)<0 or not d.claim().is_empty() or d.pouches!=pouches:failures.append('duplicate reward %d'%trial)
  rows.append({'trial':trial,'round':round_no,'star':star,'level':level,'win':win,'ticks':ticks,'gold':reward.get('gold',-1)})
  if trial%500==499:print('BATTLE_PROGRESS ',trial+1)
  if not failures.is_empty():break
 var result={'trials':rows.size(),'wins':wins,'total_ticks':ticks_total,'max_ticks':max_ticks,'roundtrip_checks':reloads,'failures':failures,'seed':20261109,'rows':rows,'limitations':'actual tick logic; phases advanced directly without waiting real animation time; random teams, not exhaustive balance recommendation'}
 var f=FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE);f.store_string(JSON.stringify(result));f.close();print('BATTLE_AUDIT ',rows.size(),' failures=',failures);quit(0 if failures.is_empty() else 1)
