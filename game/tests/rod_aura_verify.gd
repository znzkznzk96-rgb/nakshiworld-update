extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok:failures.append(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;m.development_preview=true;root.add_child(m);await process_frame;m.set_process(false)
	var a=m.angler_scene.rod_aura
	check(m.ROD_MAX==[5,8,10,13,16,20],"existing six enhancement caps retained")
	for rod in 6:
		m.rod_lv=rod;m.forge_lv=99
		check(m.forge_lv==m.ROD_MAX[rod],"real selected rod enhancement cap")
		check(a.tier(m.forge_lv)==int(m.ROD_MAX[rod]/2),"aura uses actual enhancement with odd levels retained")
	for level in 21:
		m.rod_lv=5;m.forge_lv=level
		check(a.tier(m.forge_lv)==int(level/2),"all absolute tiers through20")
	check(a.COLORS[1].r>a.COLORS[1].b and a.COLORS[2].b>a.COLORS[2].r+.5,"warm silver and saturated blue separated")
	check(a.tier(0)==0 and a.tier(1)==0,"unupgraded and plus1 have no aura")
	for i in range(1,11):check(a.WIDTHS[i]>a.WIDTHS[i-1] and a.COUNTS[i]>a.COUNTS[i-1],"progressive tier budget")
	seed(456);var expected: float=randf();seed(456)
	for i in 11:a.color_at(i,.5,2.0)
	check(randf()==expected,"aura palette preserves fishing RNG")
	check(a.trail.is_empty(),"new rig starts without old trail")
	m.audio_feedback.dispose();print("ROD_AURA_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
