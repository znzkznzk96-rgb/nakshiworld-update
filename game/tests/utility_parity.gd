extends SceneTree
func _initialize():call_deferred("run")
func run():
 var args=OS.get_cmdline_user_args();var input=FileAccess.open(args[0],FileAccess.READ);var output=FileAccess.open(args[1],FileAccess.WRITE);var count=0
 while not input.eof_reached():
  var line=input.get_line().strip_edges();if line.is_empty():continue
  var v=line.split(" ");var d=load("res://addons/expedition/model.gd").new();d.unlocked=10
  for i in 3:
   var j=2+i*7;var u=d.add_unit(int(v[j]),int(v[j+1]),[int(v[j+4]),int(v[j+5]),int(v[j+6])]);u.level=int(v[j+2]);u.rarity=int(v[j+3]);d.team.append(u.uid)
  d.start(int(v[0]),1000);d.battle.utility_revision=int(v[1]);var ticks=0
  while d.active():
   d.battle.phase="fight";d.tick();ticks+=1
   if d.battle.phase=="death":
    d.battle.index+=1
    if int(d.battle.index)>=3:d.finish(true,1000)
    else:d.spawn_enemy()
   elif d.battle.phase=="defeat":d.finish(false,1000)
  var row=[str(int(d.battle.status=="win")),str(ticks)]
  for f in d.battle.fighters:row.append(str(int(f.hp)));row.append(str(int(f.shield)))
  row.append(str(int(d.battle.enemy.hp)));output.store_line(",".join(row));count+=1
 output.close();print("PARITY cases=",count);quit()
