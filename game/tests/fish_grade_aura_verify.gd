extends SceneTree
class Probe extends "res://main.gd":
	func _fish_effect_rect(_r:Rect2,_c:Color)->void:pass
	func _fish_effect_circle(_p:Vector2,_r:float,_c:Color)->void:pass
const Aura=preload("res://addons/reservoir/fish_grade_aura.gd")
var failures:Array=[]
func check(ok:bool,label:String):
	if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
	var m=Probe.new();m.SET.sfx=0;m.SET.music=0;m.development_preview=true;root.add_child(m);await process_frame;m.set_process(false)
	var a=m.fish_grade_aura
	var r=Rect2(60,80,15,15)
	check(is_equal_approx(Aura.mask_alpha(r.get_center(),[r]),0.04),"cue interior faint")
	check(Aura.mask_alpha(r.end+Vector2(6,0),[r])>0.04 and Aura.mask_alpha(r.end+Vector2(6,0),[r])<1,"feather transition")
	check(Aura.mask_alpha(r.end+Vector2(20,0),[r])==1 and Aura.mask_alpha(r.get_center(),[])==1,"outside and absent restore")
	var cases=0
	for grade in range(1,5):
		for sp in [0,7,19,40,59]:
			for center in [Vector2(10,170),Vector2(135,310),Vector2(260,430)]:
				m.start_wait();m.S.sp=sp;m.S.len=m.FISH_LEN[sp];m.start_fight();m.S.tut=false;m.S.lesson="";m.S.beh="tell";m.S.bt=.5;m.S.grade=grade;m.S.lf=1.0;m.S.tension=35;m.S.pose={};m.oy=13
				m.fight_telegraph.note_behavior(m)
				var length=m._fight_body_length(sp,1.0,m.S.star)
				var hud=m._fish_tension_position(center,m._fight_fish_scale(1),0,length)
				m.aura_cue_context={"center":center,"group":false,"hud":hud}
				m.ui_commands=[];a.masking_enabled=false
				seed(987);var expected=randf();seed(987)
				m._shadow_fish(center,m.S.star,grade,1830,"tell",false,2.2,{},1.2,sp,1.0,1.0,length)
				var normal=a.last_samples.duplicate(true)
				var state=m.S.duplicate(true)
				m.ui_commands=[];a.masking_enabled=true
				m._shadow_fish(center,m.S.star,grade,1830,"tell",false,2.2,{},1.2,sp,1.0,1.0,length)
				check(a.last_samples==normal,"mask never changes particle positions ages counts")
				check(randf()==expected and m.S==state,"presentation preserves RNG and gameplay state")
				var layout=m.fight_telegraph.layout(m,center,length,false,hud)
				m.S.tensionHud=hud;m.fight_telegraph.draw(m,center,length)
				check(layout.bounds==m.fight_telegraph.icon_bounds,"mask and cue share current layout")
				check(not normal.is_empty(),"all selected grades emit")
				cases+=1
	a.masking_enabled=true;m.audio_feedback.dispose();m.queue_free();await process_frame
	print("FISH_GRADE_AURA_VERIFY failures=",failures," cases=",cases)
	quit(0 if failures.is_empty() else 1)
