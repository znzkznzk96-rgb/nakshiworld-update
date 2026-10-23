extends RefCounted
# Audio players are children of the game; no reference cycle back to the game.
const ROOT = "res://sfx/refresh65/"
const PATTERNS = {"tell":[45],"run":[100,45,150],"turn":[45],"charge":[100,45,110],"rise":[65],"jump":[95],"land":[170],"nose":[50],"dive":[90,60,100],"thrash":[55,40,75,40,55],"skim":[70,45,70],"spike":[140],"circle":[40],"clone":[50,60,50],"sulk":[65],"swim":[25],"rest":[]}
const SOUNDS = {"tell":"tension","run":"swim","turn":"swim","charge":"swim","rise":"water","jump":"splash","land":"splash","nose":"bubbles","dive":"bubbles","thrash":"water","skim":"swim","spike":"tension","circle":"swim","clone":"bubbles","sulk":"tension","swim":"swim"}
var streams: Dictionary = {}
var pool: Array = []
var village_music: AudioStreamPlayer
var village_fx: AudioStreamPlayer
var village_horn: AudioStreamPlayer
var village_active := false
var village_gain := 0.0
var gull_timer := 7.0
var horn_timer := 4.0
var music: AudioStreamPlayer
var rain: AudioStreamPlayer
var state := ""
var event_age := 0.0
var tension_age := 0.0
var previous_tension := 0.0
var previous_land := 0.0
var previous_spike := 0.0
var thunder_key := ""
var lesson_stage := ""
var click_time := -1000
var suspended := false
var title_gain := 0.0
func setup(m) -> void:
	for name in ["water","swim","bubbles","splash","rain","music","click","hook","catch","record","snap","hammer","reel","thunder","tension","cast"]:
		streams[name] = load(ROOT + name + ".ogg")
	streams["cast"]=load("res://sfx/refine68/cast.ogg")
	for name in ["village","gull1","gull2","horn"]: streams[name]=load("res://sfx/village/"+name+".ogg")
	village_music=AudioStreamPlayer.new();village_fx=AudioStreamPlayer.new();m.add_child(village_music);m.add_child(village_fx)
	village_horn=AudioStreamPlayer.new();m.add_child(village_horn)
	village_music.stream=streams.village.duplicate();village_music.stream.loop=true
	for i in 6:
		var p := AudioStreamPlayer.new();m.add_child(p);pool.append(p)
	music = AudioStreamPlayer.new();rain = AudioStreamPlayer.new();m.add_child(music);m.add_child(rain)
	music.stream = streams.music.duplicate();music.stream.loop = true
	rain.stream = streams.rain.duplicate();rain.stream.loop = true
func stop_all() -> void:
	for p in pool: p.stop()
	if is_instance_valid(music): music.stop();rain.stop()
	if is_instance_valid(village_music): village_music.stop();village_fx.stop();village_horn.stop()
func sound(m, name: String, db: float = -8.0, pitch: float = 1.0) -> void:
	if suspended or m.SET.sfx <= 0.01 or not streams.has(name): return
	if name=="click":
		var now:=Time.get_ticks_msec()
		if now-click_time<70: return
		click_time=now
	for p in pool:
		if not p.playing:
			p.stream=streams[name];p.volume_db=minf(-1.0,db)+linear_to_db(m.SET.sfx)
			p.pitch_scale=clampf(pitch,0.7,1.35);p.play();return
func action(m, key: String, demo: bool = false) -> void:
	var size: float = clampf(float(m.S.get("lf",1.0)),0.6,1.6)
	if SOUNDS.has(key): sound(m,SOUNDS[key],-13.0 if key in ["tell","swim","circle","nose"] else -7.0,1.1-size*0.12+randf_range(-0.04,0.04))
	if PATTERNS.has(key) and not PATTERNS[key].is_empty(): m.buzz(PATTERNS[key])
	event_age=0.0
func update(m,dt: float) -> void:
	if suspended: return
	event_age+=dt;tension_age+=dt
	update_village(m,dt)
	var title: bool = m.title_open or m.title_screen.leaving
	title_gain=move_toward(title_gain,1.0 if title else 0.0,dt*1.5)
	if title_gain>0.001:
		music.volume_db=-14.0+linear_to_db(maxf(0.0001,m.SET.music*title_gain))
		rain.volume_db=-19.0+linear_to_db(maxf(0.0001,m.SET.sfx*title_gain))
		if m.SET.music>0.01 and not music.playing: music.play()
		if m.SET.sfx>0.01 and not rain.playing: rain.play()
	else: music.stop();rain.stop()
	if m.SET.music<=0.01: music.stop()
	if m.SET.sfx<=0.01:
		rain.stop()
		for p in pool: p.stop()
	if title:
		var f: Dictionary = m.title_screen.flash_at(m.title_screen.elapsed)
		var key := "%d:%d" % [f.cycle,f.event]
		if f.event>=0 and key!=thunder_key and f.age<0.25:
			thunder_key=key;sound(m,"thunder",-9.0 if f.event==2 else -18.0,0.9 if f.event==2 else 1.1)
		state="";return
	if m.lesson_open:
		var frame: Dictionary=m.lesson_frame(m.lesson_key,m.ui_clock-m.lesson_clock)
		var key: String=m.lesson_key+":"+frame.beh
		if key!=lesson_stage: lesson_stage=key;action(m,frame.beh,true)
		return
	lesson_stage=""
	var active: bool=m.scene=="fish" and m.S.get("phase","")=="fight" and not m.settings_open and not m.market_open and not m.personal_dex.opened and not m.guide.opened and not m.mailbox.opened
	if not active: state="";previous_tension=0;previous_land=0;previous_spike=0;return
	var beh: String=m.S.beh
	if beh!=state: state=beh;action(m,beh)
	elif beh in ["thrash","skim","run","dive","circle"] and event_age> (0.48 if beh=="thrash" else 0.8): action(m,beh)
	var land: float=m.S.get("landUntil",0.0)
	if land>previous_land and land>m.clock: action(m,"land")
	previous_land=land
	var spike: float=m.S.get("spike",0.0)
	if spike>previous_spike+0.05: action(m,"spike")
	previous_spike=spike
	var tension: float=m.S.tension
	var rising: bool=tension>previous_tension+0.015
	if rising and tension>=35 and tension_age>lerpf(1.0,0.28,clampf((tension-35)/65,0,1)) and event_age>0.2:
		sound(m,"tension",lerpf(-22,-10,tension/100.0),lerpf(0.8,1.3,tension/100.0))
		if m.vib_queue.is_empty() and m.vib_wait<=0: m.buzz([18 if tension<75 else 28])
		tension_age=0
	previous_tension=tension

func dispose() -> void:
	stop_all()
	for p in pool:
		if is_instance_valid(p): p.stream=null
	if is_instance_valid(music): music.stream=null;rain.stream=null
	if is_instance_valid(village_music): village_music.stream=null;village_fx.stream=null;village_horn.stream=null
	pool.clear();streams.clear()

func update_village(m,dt: float) -> void:
	var active: bool=m.scene=="village" and not m.title_open and not m.title_screen.leaving
	if active and not village_active:
		horn_timer=4.0;gull_timer=7.0
	village_active=active
	village_gain=move_toward(village_gain,1.0 if active else 0.0,dt*1.25)
	var duck: float=0.5 if m.settings_open or m.lesson_open or m.guide.opened else 1.0
	village_music.volume_db=-17.0+linear_to_db(maxf(0.0001,m.SET.music*village_gain*duck))
	if village_gain>0.001 and m.SET.music>0.01:
		if not village_music.playing: village_music.play()
	else: village_music.stop()
	if not active or m.SET.sfx<=0.01 or m.lesson_open:
		village_fx.stop();village_horn.stop();return
	village_fx.volume_db=-19.0+linear_to_db(m.SET.sfx*duck)
	village_horn.volume_db=-23.0+linear_to_db(m.SET.sfx*duck)
	gull_timer-=dt;horn_timer-=dt
	if horn_timer<=0 and not village_horn.playing:
		village_horn.stream=streams.horn;village_horn.pitch_scale=randf_range(0.93,1.03);village_horn.play();horn_timer=randf_range(40,70)
	if gull_timer<=0 and not village_fx.playing:
		village_fx.stream=streams.gull1 if randf()<0.5 else streams.gull2;village_fx.pitch_scale=randf_range(0.94,1.06);village_fx.play();gull_timer=randf_range(12,24)
