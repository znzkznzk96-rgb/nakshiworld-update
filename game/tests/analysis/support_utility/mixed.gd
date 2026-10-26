extends "res://tests/analysis/support_utility/run.gd"
func run():
 if OS.get_cmdline_user_args().size()>1 and OS.get_cmdline_user_args()[1]=="refined":profiles[1]={"name":"refined","regen":.035,"rescue":.15,"ward":.075,"cd":5,"threshold":.35,"expose":.15}
 var ref=Base.new();var roles={"attack":[],"defense":[],"support":[]}
 for i in 15:roles[ref.catalog.soldiers[i].role].append(i)
 var rows=[]
 for cfg in [[1,0],[1,3],[2,0],[2,3]]:
  for room in range(1,11):
   for role in ["attack","support"]:
    var wins=0;var per={}
    for a in roles.defense:
     for b in roles.attack:
      for c in roles[role]:
       var r=fight([a,b,c],[2,2,cfg[0]],3,4,room,1,cfg[1]);wins+=r.win
       var key=str(c)
       if not per.has(key):per[key]=0
       per[key]+=r.win
    rows.append({"third_star":cfg[0],"third_level":cfg[1],"room":room,"role":role,"wins":wins,"teams":125,"per":per})
 var file=FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE);file.store_string(JSON.stringify({"cases":total,"rows":rows}));file.close();print("MIXED_DONE cases=",total);quit()
