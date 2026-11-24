extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String):
	if not ok: failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
	var G=load("res://addons/reservoir/mail_gifts.gd");m.pearl=5;m.gold=7;var bag:int=m.bag.size()
	check(G.claim(m,"1.44"),"claim");check(m.pearl==10005 and m.gold==7 and m.bag.size()==bag,"pearl only")
	check(not G.claim(m,"1.44") and m.pearl==10005,"once")
	m._load_game();check(m.pearl==10005 and "pearl-test-144" in m.testing_grants,"persists")
	print("PEARL_GIFT_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
