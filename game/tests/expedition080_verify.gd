extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
	m.title_open=false;m.TUT.done=true;m.lesson_open=false;m.scene="village";m.trans={}
	var v=m.expedition;var d=v.data;d.restore({})
	for id in [3,0,6,1]: d.add_unit(id,1,[0,0,0])
	v.open(m,"explore");v.explore_tab=1
	for uid in [1,2,3]:
		v.rects={"formation_unit:%d"%uid:Rect2(0,0,20,20)};v.press(m,Vector2(10,10))
		check(not uid in d.team,"selection does not equip before confirmation")
		v.draw_formation(m,139,650);v.press(m,v.formation_ui.modal_rects.confirm.get_center())
	check(d.team==[1,2,3],"confirmation equips first three in order")
	v.rects={"clear_slot:1":Rect2(0,0,20,20)};v.press(m,Vector2(10,10));check(d.team==[1,3],"explicit remove clears selected slot")
	v.rects={"formation_unit:4":Rect2(0,0,20,20)};v.press(m,Vector2(10,10));v.formation_target=0
	v.draw_formation(m,139,650);v.press(m,v.formation_ui.modal_rects.confirm.get_center());check(d.team==[4,3],"confirmed slot replaces")

	d.team=[1,2,3];d.start(1,1000);v.rects={"formation_unit:1":Rect2(0,0,20,20)};v.press(m,Vector2(10,10));check(d.team==[1,2,3],"active team cannot change")
	for i in 60: d.update(.1,1000)
	check(d.battle.fx.has("incoming") and d.battle.fx.has("blocked") and d.battle.fx.has("outgoing"),"damage events captured")
	check(int(d.battle.fx.incoming)>=0 and int(d.battle.fx.blocked)>=0,"damage absorption separated")
	v.rects={"go_alchemy":Rect2(0,0,20,20)};v.press(m,Vector2(10,10));check(v.opened=="alchemy","explore to alchemy")
	v.rects={"roster":Rect2(0,0,20,20)};v.press(m,Vector2(10,10));check(v.tab==2,"explicit upgrade entry")
	v.rects={"upgrade:1":Rect2(0,0,20,20)};v.press(m,Vector2(10,10));check(v.opened=="training" and v.training_uid==1,"explicit per unit upgrade")
	var source: Image=Image.create(5,5,false,Image.FORMAT_RGBA8);source.fill(Color.TRANSPARENT)
	for y in range(1,4):
		for x in range(1,4): source.set_pixel(x,y,Color.BLUE)
	source.set_pixel(2,2,Color.TRANSPARENT)
	var fixed: Image=load("res://addons/expedition/opaque_body.gd").prepare(ImageTexture.create_from_image(source),5).get_image()
	check(fixed.get_pixel(2,2).a==1 and fixed.get_pixel(0,0).a==0 and fixed.get_pixel(1,1)==Color.BLUE,"opaque body keeps exterior and original color")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("EXPEDITION080_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
