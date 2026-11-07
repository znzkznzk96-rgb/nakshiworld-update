extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String):
	if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func fish(sp: int,value: int=100,grade: int=0)->Dictionary:
	return {"sp":sp,"star":0,"grade":grade,"len":20.0,"w":0.1,"price":value}
func primary()->String:return FileAccess.get_file_as_string("user://save.json")
func block_write():
	var path: String=ProjectSettings.globalize_path("user://save.json.tmp")
	assert("stage4" in path)
	if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	check(DirAccess.make_dir_absolute(path)==OK,"create isolated real write blocker")
func unblock_write():
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path("user://save.json.tmp"))==OK,"remove write blocker")
func capture(m,out: String,name: String):
	m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name+".png"))
func open_bundle(m,kind: int):
	m._switch_scene("village");m.V.open_shop(m,"museum")
	var ui=m.V.bundle_preview
	ui.region=2;ui.tab=kind;ui.selected=-1;ui.reward_open=false;ui.bulk_open=false;ui.dialog_notice=""
func run():
	var out: String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_size=Vector2i(270,540);root.size=Vector2i(810,1620)
	var app=load("res://tests/valley_native_root.gd").new();root.add_child(app);app._start()
	var m=app.box.get_child(0).get_child(0)
	m.SET.sfx=0;m.SET.music=0;m.set_process(false);m.title_open=false;m.TUT.done=true;m.lesson_open=false;m.trans={};m.S={"phase":"idle"}
	check(m.gold==654321 and m.souls==23 and m.pearl==17,"real v106 save wallet migrates unchanged")
	check(m.active_region==1 and m.region_shop.unlocked==[0,1],"legacy region flags retained")
	check(m.bag.size()==1 and m.bag[0].sp==5 and m.bag[0].grade==2 and m.bag[0].price==111,"legacy exact held specimen retained")
	check(m.fish_grades(5)==[2] and absf(m.fish_record_cm(5)-17.2)<0.001,"legacy dex and length retained")
	check(not m.personal_dex.best(m,5,"weight").is_empty(),"legacy personal specimen retained")
	check(m.progression.bundle_counts(1,0)[0]==1 and not m.progression.bundle_done(2,0),"partial legacy donation retained without invented tile completion")
	# Remaining operations use new synthetic balances and bags only.
	var p=m.progression;var ui=m.V.bundle_preview
	p.restore({"certificates":[true,true,false],"main_completed":[true,true,false],"reward_claimed":{"0:0":true,"1:0":true}})
	m.gold=312000;m.souls=0;m.pearl=0;m.bag=[];m.active_region=1;m.region_shop.unlocked=[0,1]
	check(m._save_game(),"save isolated pre-entry fixture")
	m._switch_scene("spots");m.spots.index=2;m.spots.scroll=2
	await capture(m,out,"entry_ready")
	var disk:=primary();block_write()
	m.spots.press(m,m.spots.rects.enter.get_center())
	check(m.gold==312000 and not m.region_shop.is_unlocked(2),"actual write failure rolls unlock and exact fee back")
	check(primary()==disk,"failed unlock preserves primary bytes")
	await capture(m,out,"entry_save_failed")
	unblock_write();m.spots.press(m,m.spots.rects.enter.get_center());m.trans={};m._switch_scene("fish")
	check(m.gold==0 and m.active_region==2 and m.region_shop.is_unlocked(2),"actual entry charges312000 once")
	check(m._save_game(),"save entered region")
	var initial_bag: Array=[fish(p.SUB_SPECIES[2][0],999,4),fish(0,444,3)]
	for i in 6:initial_bag.append(fish(p.SUB_SPECIES[2][i],101+i,0))
	m.bag=initial_bag.duplicate(true)
	check(m._save_game(),"save batch fixture")
	open_bundle(m,1);await capture(m,out,"sub_before")
	ui.press(m,ui.rects.register.get_center());await capture(m,out,"sub_bulk_confirmation")
	check(ui.bulk_plan.size()==6 and int(ui.bulk_plan[0].fish.price)==101,"batch chooses lowest grade specimen without consuming valuable duplicate")
	var original_plan: Array=ui.bulk_plan.duplicate(true)
	m.bag[2].price=102
	var stale_bag: Array=m.bag.duplicate(true);var before_state: Dictionary=p.serialize().duplicate(true)
	ui.press(m,ui.rects.bulk_confirm.get_center())
	check(m.bag==stale_bag and p.serialize()==before_state and ui.bulk_open,"stale batch confirmation cannot donate replacement specimens")
	m.bag=initial_bag.duplicate(true);ui.bulk_plan=p.donation_plan(m,2,1);await capture(m,out,"sub_bulk_confirmation")
	disk=primary();block_write();ui.press(m,ui.rects.bulk_confirm.get_center())
	check(m.bag==initial_bag and p.serialize()==before_state and primary()==disk,"actual batch write failure restores bag progress and primary")
	await capture(m,out,"sub_bulk_save_failed")
	unblock_write();ui.press(m,ui.rects.bulk_confirm.get_center());await capture(m,out,"sub_reward_ready")
	check(p.bundle_done(2,1) and not p.claimed(2,1) and m.gold==0,"side completion waits for explicit claim")
	check(m.bag.size()==2 and m.bag[0].price==999 and m.bag[1].sp==0,"batch consumes only six displayed specimens")
	check(ui.reward_amount(m,2,1)==745,"621 sale value pays rounded120 percent")
	disk=primary();block_write();ui.press(m,ui.rects.claim.get_center())
	check(not p.claimed(2,1) and m.gold==0 and m.souls==0 and primary()==disk,"actual side claim failure rolls wallet flag and primary back")
	await capture(m,out,"sub_claim_save_failed")
	unblock_write();ui.press(m,ui.rects.claim.get_center());await capture(m,out,"sub_claimed")
	check(p.claimed(2,1) and m.gold==745 and m.souls==30,"actual claim pays745 and30 souls")
	ui.press(m,Vector2(70,340));check(m.gold==745 and m.souls==30,"double claim cannot pay twice")
	for sp in p.MAIN_SPECIES[2]:m.bag.append(fish(sp))
	open_bundle(m,0);await capture(m,out,"main_before")
	ui.press(m,ui.rects.register.get_center());await capture(m,out,"main_bulk")
	ui.press(m,ui.rects.bulk_confirm.get_center());await capture(m,out,"main_reward_ready")
	check(p.bundle_done(2,0) and not p.licensed(3),"main completion alone does not grant next eligibility")
	disk=primary();block_write();ui.press(m,ui.rects.claim.get_center())
	check(not p.licensed(3) and not p.claimed(2,0) and m.gold==745 and primary()==disk,"actual main claim failure cannot grant certificate")
	unblock_write();ui.press(m,ui.rects.claim.get_center());await capture(m,out,"main_claimed")
	check(p.licensed(3) and m.gold==745,"main claim grants only next certificate")
	m.bag.append(fish(59,1001,4));check(m._save_game(),"save owner fixture")
	disk=primary();var before_bag: Array=m.bag.duplicate(true);block_write()
	check(not p.donate_bundle(m,2,2,m.bag.size()-1,0) and m.bag==before_bag and not p.bundle_done(2,2) and primary()==disk,"actual single donation failure restores owner specimen and progress")
	unblock_write();check(p.donate_bundle(m,2,2,m.bag.size()-1,0),"owner donation accepts mythic specimen")
	open_bundle(m,2);await capture(m,out,"owner_complete")
	ui.press(m,ui.rects.register.get_center());await capture(m,out,"owner_reward_ready")
	disk=primary();block_write();ui.press(m,ui.rects.claim.get_center())
	check(not p.claimed(2,2) and m.gold==745 and m.pearl==0 and primary()==disk,"actual owner claim failure restores money pearls flag and primary")
	unblock_write();ui.press(m,ui.rects.claim.get_center());await capture(m,out,"owner_claimed")
	check(m.gold==2247 and m.souls==30 and m.pearl==2,"owner1001 pays rounded1502 plus2 pearls")
	m.V.shop="";m._switch_scene("spots");m.spots.index=3;m.spots.scroll=3
	await capture(m,out,"rift_stays_preparing")
	m.spots.press(m,m.spots.rects.enter.get_center())
	check(m.gold==2247 and not m.region_shop.is_unlocked(3),"licensed unfinished rift cannot charge or open")
	m.trans={};m.active_region=2;m._layout()
	check(m._save_game(),"final new-format fixture saved")
	m.audio_feedback.dispose();app.queue_free();await process_frame;await process_frame
	print("BUNDLE_STAGE4_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
