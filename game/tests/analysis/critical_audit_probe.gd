extends SceneTree
var rows:Array=[]
var disk:PackedByteArray
func _initialize():call_deferred('run')
func snapshot(m)->Dictionary:return {'gold':m.gold,'rod_lv':m.rod_lv,'rod_enh':m.rod_enh.duplicate(),'catch_state':m.S.duplicate(true),'bag':m.bag.duplicate(true),'buyback':m.buyback.serialize(),'aqua':m.aqua.duplicate(true),'aqua_lv':m.aqua_lv,'boat_lv':m.boat_lv,'bait':m.bait,'parts':m.parts_owned.duplicate(),'equipment':m.equipment.serialize().duplicate(true),'expedition':m.expedition.data.serialize().duplicate(true)}
func fish()->Dictionary:return {'sp':0,'star':0,'grade':0,'len':10.0,'w':.1,'price':100}
func block(m):
 m._save_game()
 if FileAccess.file_exists('user://save.json.tmp'):DirAccess.remove_absolute('user://save.json.tmp')
 disk=FileAccess.get_file_as_bytes('user://save.json')
 assert(DirAccess.make_dir_absolute('user://save.json.tmp')==OK)
func unblock():assert(DirAccess.remove_absolute('user://save.json.tmp')==OK)
func record(m,label,before,result):rows.append({'case':label,'reported_result':result,'memory_unchanged':snapshot(m)==before,'disk_unchanged':FileAccess.get_file_as_bytes('user://save.json')==disk})
func run():
 var m=load('res://main.gd').new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.lesson_open=false
 m.gold=1000;m.bag=[];m.buyback.entries=[];m.buyback.remember(fish());block(m);var before=snapshot(m);record(m,'buyback_real_write_failure',before,m.buyback.purchase(m,int(m.buyback.entries[0].id)));unblock()
 m.gold=1000;m.bag=[fish()];block(m);before=snapshot(m);m.sell_all();record(m,'sell_all_real_write_failure',before,null);unblock()
 m.gold=10000;m.aqua_lv=0;m.aqua=[fish(),null,null];block(m);before=snapshot(m);record(m,'aqua_expand_real_write_failure',before,m.aqua_expand());unblock()
 var d=m.expedition.data;d.restore({});var a=d.add_unit(0,1,[3,3,3]);var b=d.add_unit(1,1,[3,3,3]);d.unit(a.uid).level=3;d.unit(b.uid).level=3;d.souls=[10,10,10,10,10]
 var v=m.expedition;v.selected=[a.uid,b.uid];v.opened='merge_confirm';v.rects={'merge_confirm':Rect2(10,10,50,30)};block(m);before=snapshot(m);v.press(m,Vector2(25,20));record(m,'merge_real_write_failure',before,null);unblock()
 m.gold=10000;m.boat_lv=0;block(m);before=snapshot(m);m.V._act(m,'boat');record(m,'shop_boat_real_write_failure',before,null);unblock()
 m.gold=10000;m.bait=0;block(m);before=snapshot(m);m.V._act(m,'worm:10');record(m,'shop_bait_real_write_failure',before,null);unblock()
 m.gold=10000;m.bag=[fish()];block(m);before=snapshot(m);m.V._act(m,'sell:0');record(m,'single_fish_sale_real_write_failure',before,null);unblock()
 m.equipment.rods=[0,1];m.rod_lv=0;m.rod_owned=1;m.equipment.rod_equipped=true;block(m);before=snapshot(m);record(m,'equip_real_write_failure',before,m.equipment.equip(m,'rod:1',true));unblock()
 m.rod_lv=0;m.equipment.rod_equipped=true;block(m);before=snapshot(m);record(m,'gear_sale_real_write_failure',before,m.equipment.sell(m,'rod:1'));unblock()
 m.bag=[];m.S={'phase':'catch','sp':0,'star':0,'grade':0,'len':10.0,'weight':.1,'lf':1.0};block(m);before=snapshot(m);m.keep_fish();record(m,'keep_catch_real_write_failure',before,null);unblock()
 d.restore({});a=d.add_unit(0,1,[3,3,3]);b=d.add_unit(1,1,[3,3,3]);d.unit(a.uid).level=3;d.unit(b.uid).level=3;d.souls=[10,10,10,10,10];d.begin_merge(a.uid,b.uid,m.gold)
 v.rects={'inherit:0':Rect2(10,10,50,30)};v.opened='alchemy';block(m);before=snapshot(m);v.press(m,Vector2(25,20));record(m,'inherit_real_write_failure',before,null);unblock()
 var path=OS.get_cmdline_user_args()[0];var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(rows,'  '));f.close();print('AUDIT_PROBE ',JSON.stringify(rows));assert(rows.all(func(r):return r.memory_unchanged and r.disk_unchanged));m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
