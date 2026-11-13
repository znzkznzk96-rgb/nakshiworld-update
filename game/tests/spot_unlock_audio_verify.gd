extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false)
 var audio=m.audio_feedback;audio.stop_all();m.SET.sfx=1.0
 for key in ["unlock_chain_pull","unlock_latch","unlock_chain_release"]:
  check(audio.streams.has(key) and audio.streams[key] is AudioStreamWAV,"dedicated metal sample loaded "+key)
  check(audio.streams[key].get_length()>=.3 and audio.streams[key].get_length()<.7,"short nonlooping sample "+key)
  check(audio.streams[key].loop_mode==AudioStreamWAV.LOOP_DISABLED,"one-shot metal sample "+key)
 var fx=m.spots.unlock_fx;fx.start(3)
 fx.update(.47,m);check(audio.pool.filter(func(p):return p.playing).is_empty(),"no early sound")
 fx.update(.02,m);var playing=audio.pool.filter(func(p):return p.playing)
 check(playing.size()==1 and playing[0].stream==audio.streams.unlock_chain_pull,"chain pull at anticipation")
 fx.update(.01,m);check(audio.pool.filter(func(p):return p.playing).size()==1,"cue not repeated between frames")
 fx.update(.34,m);check(audio.pool.filter(func(p):return p.playing and p.stream==audio.streams.unlock_latch).size()==1,"metal latch at shackle opening")
 fx.update(.4,m);check(audio.pool.filter(func(p):return p.playing and p.stream==audio.streams.unlock_chain_release).size()==1,"chain release at burst")
 var count:int=audio.pool.filter(func(p):return p.playing).size();fx.update(2,m)
 check(audio.pool.filter(func(p):return p.playing).size()==count,"no generic success chime remains")
 audio.stop_all();m.SET.sfx=0;fx.start(3);fx.update(4,m)
 check(audio.pool.filter(func(p):return p.playing).is_empty(),"SFX mute honored")
 m.SET.sfx=1;audio.suspended=true;fx.start(3);fx.update(4,m)
 check(audio.pool.filter(func(p):return p.playing).is_empty(),"suspended audio honored")
 playing.clear();audio.dispose();m.queue_free();await process_frame;await create_timer(0.15).timeout
 print("SPOT_UNLOCK_AUDIO_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
