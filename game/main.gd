extends Node2D




const VW: = 270
const TOP: = 22
const SURF: = 217
const WATER: = 273
var uw_bot: = 447.0
var oy: = 0.0
var ox: = 0.0
const BG_TOP: = 290
const PX: = 22
const PY: = 179
const CATX: = 0
const CATY: = 204
const LX: = 176


const STAR_P: = [0.62, 0.27, 0.09, 0.018, 0.0]
const GRADE_P: = [0.8653, 0.0661, 0.0628, 0.0042, 0.0016]
const GRADE_N: = ["노멀", "레어", "유니크", "전설", "신화"]
const GRADE_C: = [Color("c9d2d6"), Color("4fa3ff"), Color("b06cff"), Color("ffb340"), Color("ffffff")]
const FISH_NAME: = ["피라미", "붕어", "송사리", "미꾸라지", "블루길", "버들치", "납작붕어", "소금쟁이 피라미", 
	"잉어", "메기", "빠가사리", "향어", "배스", "장어 새끼", "쏘가리", "가물치", "뱀장어", "황금잉어", "달빛붕어", "청룡잉어"]
const FISH_LEN: = [12, 25, 5, 12, 18, 10, 15, 8, 60, 50, 25, 50, 40, 35, 45, 70, 80, 90, 60, 200]
const BY_STAR: = [[0, 1, 2, 3, 4, 5, 6, 7], [8, 9, 10, 11, 12, 13], [14, 15, 16], [17, 18], [19]]


const BITE_WAIT: = [2.5, 5.0]
const BAIT_WAIT_MUL: = 1.5
const BITE_WINDOW: = [1.5, 1.0, 0.7, 0.5, 0.35]

const BAR_SPEED: = [0.72, 0.84, 0.98, 1.12, 1.28]
const BAR_ACC: = [1.1, 1.15, 1.2, 1.25, 1.3]
const BAR_PERF: = [0.06, 0.05, 0.045, 0.035, 0.03]
const BAR_GREAT: = [0.2, 0.18, 0.16, 0.14, 0.12]
const PULL: = [0.9, 1.1, 1.35, 1.6, 1.9]
const SIZE_NAME: = ["소", "중", "대", "특대"]

const TIER_NAME: = ["치어", "소형", "보통", "대형", "월척", "대물", "괴물"]
const TIER_MIN: = [0.0, 0.7, 0.9, 1.1, 1.25, 1.4, 1.55]
const TIER_COL: = [Color("a8a8a8"), Color("9be37a"), Color("f4efe2"), Color("7fd0ff"), Color("ffd24a"), Color("ff9a3c"), Color("ff4a4a")]

func tier_of(lf: float) -> int:
	var k: = 0
	for i in TIER_MIN.size():
		if lf >= TIER_MIN[i]: k = i
	return k

const W_BASE: = [0.08, 0.25, 0.7, 1.8, 4.5]
const W_GRADE: = [1.0, 1.2, 1.5, 2.0, 3.0]

var fonts: = []
const FONT_PX: = [10, 12, 14, 16]
const FONT_SC: = [1.0, 1.0, 1.0, 1.0]
var text_layer: Node2D
var ui_demo: = false
var ui_commands: = []
var text_items: = []
var top_y: = 2.0
var bot_pad: = 0.0
var sb_panel: StyleBoxTexture
var sb_btn: StyleBoxTexture
var sb_primary: StyleBoxTexture
var sb_chip: StyleBox
var sb_gauge: StyleBoxTexture
var sb_meter: StyleBoxTexture
var sb_fill: StyleBoxTexture
var tex_star: Texture2D
var icons: = {}
var gold: = 0

const BAG_NAME: = ["맨손", "꿰미", "양동이", "그물망", "아이스박스 1", "아이스박스 2", "아이스박스 3", "아이스박스 4", "아이스박스 5"]
const BAG_CAP: = [0.5, 1.5, 3.0, 6.0, 12.0, 20.0, 30.0, 45.0, 65.0]
const BAG_PRICE: = [0, 150, 800, 4000, 20000, 80000, 300000, 1200000, 5000000]
const PRICE_BASE: = [[10, 30], [50, 120], [200, 350], [1000, 1500], [8000, 8000]]
const PRICE_GRADE: = [1.0, 1.3, 1.7, 2.2, 3.0]
var bag: = []
var bag_lv: = 0
var tips_seen: = []
var title_open: = true
var title_screen = preload("res://addons/reservoir/title_screen.gd").new()
var market_open: = false
var ui_rects: = {}
var tip_txt: = ""
var tip_t: = 0.0
var tex_sign: Texture2D
var scene: = "fish"
var V = preload("res://village.gd").new()
var region_shop = preload("res://addons/reservoir/region_shop.gd").new()
var guide = preload("res://addons/reservoir/guide.gd").new()
var mailbox = preload("res://addons/reservoir/mailbox.gd").new()
var drag_player: AudioStreamPlayer
var equipment = preload("res://addons/reservoir/equipment.gd").new()
var lesson_clock := 0.0
var inventory = preload("res://addons/reservoir/inventory.gd").new()
var spots = preload("res://addons/reservoir/spot_selection.gd").new()
var catch_counts: = {}
var catch_legacy: = {}
var trans: = {}
var bait: = 0
var souls: = 0
const AQUA_CAP: = [3, 6, 10, 15, 20]
const AQUA_COST: = [300, 900, 2400, 6000]
var aqua_lv: = 0
var aqua: = [null, null, null]
var aqua_acc: = 0.0
var boat_lv: = 0
var town_lv: = 0
const ROD_MAX: = [5, 8, 10, 13, 16, 20]
var rod_enh: Array = [0, 0, 0, 0, 0, 0]
var rod_lv: = 0
var rod_owned: = 0
var forge_lv: int:
	get: return int(rod_enh[clampi(rod_lv, 0, 5)])
	set(value): rod_enh[clampi(rod_lv, 0, 5)] = clampi(value, 0, ROD_MAX[clampi(rod_lv, 0, 5)])
var protection_tickets: = 0
var forge_pending: = {}
var forge_seen: = false
var pond_cap_lv: = 0
var pond_regen_lv: = 0
var pond_stock: = 80.0
var DEX: = {}
var environment = preload("res://addons/reservoir/environment.gd").new()
var bg_node: Sprite2D
var hud_reference_style: StyleBoxTexture
var tex_hud_bar: Texture2D
var tex_hud_gauge: Texture2D
var tex_menu: Texture2D
var tex_round: Texture2D
var e_slots: = {}
var menu_open: = false
var menu_t: = 0.0
var market_sell: = true
var bag_page: = 0
var bag_disp: = 0.0
var parts_owned: = []
var settings_open: = false
var font_license_page: = 0
var set_view: = "main"
var ui_clock: = 0.0
var SET: = {"sfx": 1.0, "vib": true}
var gear_rect: = Rect2()
var set_rects: = {}
var slider_drag: = false
var fish_mouth: = Vector2.ZERO
var ripples: = []
var result_t: = 0.0
var result_rect: = Rect2()
var fclock: = 0.0
var TUT: = {"done": false, "seen": []}
var lesson_open: = false
var lesson_key: = ""
var lesson_after: = ""
const SKIP_RECT: = Rect2(85, 450, 100, 22)
var pearl: = 0
var star_hist: = []
var judge_col: = Color(1, 0.95, 0.6)
var hitstop: = 0.0
var shake_t: = 0.0
var fish_s2: = []
var fish_s3: = []
var tex_bg: Texture2D
var tex_bobber: Texture2D
var fish_tex: = []
var fish_used: = []
var fish_sil: = []
var anims: = {}
var tips: = {}
var sfx: = {}
var players: = []

var S: = {"phase": "idle"}
var holding: = false
var clock: = 0.0
var anim_name: = "idle"
var anim_t: = 0.0
var anim_loop: = true
var anim_speed: = {"idle": 0.2, "reel": 0.11, "cast": 0.09, "net": 0.13, "trophy": 0.14, "miss": 0.15, "cat": 0.22}
var anim_hold: = {"net": {15: 0.6}, "trophy": {9: 0.5, 15: 0.8}, "miss": {3: 0.4, 15: 0.7}}
var cat_t: = 0.0
var vib_queue: = []
var vib_wait: = 0.0
var sfx_acc: = 0.0
var creak_t: = 0.0
var runbuzz_t: = 0.0
var REC: = {}
var ambient: = []
var msg: = ""
var judge_txt: = ""
var judge_t: = 0.0
var toast_txt: = ""
var toast_t: = 0.0
var toast_col: = Color.WHITE
var fx_mat: CanvasItemMaterial
var fx_rid: = []
var aura: = {}
var aura_hist: = []
var aura_hist_t: = 0.0
var water_spawn_acc: = 0.0
var parts: = []
var spawn_acc: = 0.0
var reveal_t: = 0.0
var visibility_flash: = 0.0
var reveal_pending: = false
var reveal_c: = Vector2.INF
var reveal_g: = 0

func _notification(what: int) -> void :
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save_game()

func _ready() -> void :
	randomize()
	_fx_init()
	var neo: FontFile = load("res://font/neodgm.ttf")
	neo.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	neo.hinting = TextServer.HINTING_NONE
	neo.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	neo.oversampling = 1.0
	neo.fallbacks = [load("res://font/galmuri11.fnt")]
	for i in 4: fonts.append(neo)
	sb_panel = _sb("panel", 16, 16, 16, 16, true)
	sb_btn = _sb("btn", 12, 6, 12, 9)
	sb_chip = _sb("chip", 12, 6, 12, 9)
	sb_gauge = _sb("gauge", 12, 5, 12, 5)
	sb_meter = _sb("meter", 12, 3, 12, 3)
	sb_fill = _sb("fill", 2, 1, 2, 1)
	tex_star = load("res://art/ui/star.png")
	for n in ["rod", "float", "hook", "line", "reel", "coin_s", "pearl_s"]:
		icons[n] = load("res://art/icons/%s.png" % n)
	tex_bobber = load("res://art/bobber.png")
	var bg: = Sprite2D.new()
	bg_node = bg
	bg.centered = false;bg.z_index = -10
	var sh: = Shader.new()
	sh.code = BG_SHADER
	var mat: = ShaderMaterial.new();mat.shader = sh
	bg.material = mat
	add_child(bg)
	for i in FISH_NAME.size():
		var t: Texture2D = load("res://art/fish/l0_%02d.png" % i)
		fish_tex.append(t)
		var img: = t.get_image()
		fish_used.append(img.get_used_rect())
		var sil: = Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
		for yy in img.get_height():
			for xx in img.get_width():
				if img.get_pixel(xx, yy).a > 0.5: sil.set_pixel(xx, yy, Color.WHITE)
		fish_sil.append(ImageTexture.create_from_image(sil))
		fish_s2.append(load("res://art/fish/s2/l0_%02d.png" % i))
		fish_s3.append(load("res://art/fish/s3/l0_%02d.png" % i))
	for n in ["idle", "reel", "cast", "net", "trophy", "miss", "cat"]:
		var arr: = []
		for k in 16:
			arr.append(load("res://art/char/anim/%s/%s_%02d.png" % [n, n, k]))
		anims[n] = arr
	var f: = FileAccess.open("res://art/char/tips.json", FileAccess.READ)
	tips = JSON.parse_string(f.get_as_text())
	for n in ["snap", "splash_s", "splash_b", "plop", "catch", "hook", "drag", "reel", "creak", "record", "land", "hammer"]:
		sfx[n] = load("res://sfx/%s.wav" % n)
	for i in 6:
		var p: = AudioStreamPlayer.new();add_child(p);players.append(p)
	drag_player = AudioStreamPlayer.new();add_child(drag_player)
	drag_player.stream = load("res://sfx/drag_recording.ogg")
	drag_player.stream.loop = true
	_load_rec()
	_load_tut()
	_load_set()
	_load_game()
	tex_sign = load("res://art/ui/title_sign.png")
	V.setup()
	spots.setup()
	icons.m_fishing = load("res://art/refresh53/fishing_icon.png")
	var show_title: bool = title_open
	V.enhancement.restore(self)
	title_open = show_title
	tex_hud_bar = load("res://art/ui/hud_bar.png")
	tex_hud_gauge = load("res://art/ui/hud_gauge.png")
	tex_menu = load("res://art/ui/menu_btn.png")
	tex_round = load("res://art/ui/round_btn.png")
	for n in ["village", "bag", "book", "gear"]: icons["m_" + n] = load("res://art/icons/m_%s.png" % n)
	icons["scale"] = load("res://art/icons/scale.png")
	environment.setup(self)
	bag_disp = bag_weight()
	for n in ["gear_s", "knob", "toggle_on", "toggle_off", "close"]:
		icons[n] = load("res://art/icons/%s.png" % n)
	preload("res://addons/reservoir/ui_theme.gd").apply(self)
	msg = "화면을 터치하면 던지기"
	var sa: = DisplayServer.get_display_safe_area()
	var k: = float(get_window().size.x) / get_tree().root.get_visible_rect().size.x
	if OS.has_feature("mobile"):
		top_y = maxf(sa.position.y / k, 26.0) + 2
		bot_pad = maxf(get_window().size.y - sa.end.y, 0.0) / k
	_layout()
	title_screen.setup(self)
	if title_open: bg_node.hide();environment.show_scene(false)
	get_viewport().size_changed.connect(_layout)
	for i in 4:
		var sp: int = BY_STAR[0][randi() % 8]
		ambient.append({"x": randf_range(110, 260), "y": randf_range(WATER + 40, uw_bot - 30), "v": randf_range(6, 14) * (1 if randf() < 0.5 else -1), "sp": sp})
	if "--shot" in OS.get_cmdline_user_args():
		_shot_mode()


func _layout() -> void :
	var vs: = get_viewport_rect().size
	ox = floorf(maxf(0.0, vs.x - VW) / 2.0)

	var extra: = vs.y - bot_pad - 137.0 - 447.0
	var dw: = minf(roundf(extra * 0.3), 36.0) if extra > 0 else maxf(extra, -64.0)
	oy = maxf(0.0, extra - dw)
	uw_bot = 447.0 + dw
	environment.layout(self)
	for r in fx_rid: RenderingServer.canvas_item_set_transform(r, Transform2D(0.0, Vector2(0, oy)))

func _pixel_font(p: String) -> FontFile:
	var fo: FontFile = load(p)
	fo.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	fo.hinting = TextServer.HINTING_NONE
	fo.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return fo


func play(n: String, vol: = 0.0, pitch: = 1.0) -> void :
	if n in ["reel", "drag"]: return
	if SET.sfx <= 0.01: return
	vol += linear_to_db(SET.sfx)
	for p in players:
		if not p.playing:
			p.stream = sfx[n];p.volume_db = vol;p.pitch_scale = pitch;p.play();return

func buzz(pattern) -> void :
	if not SET.vib: return
	if pattern is int: pattern = [pattern]
	vib_queue = pattern.duplicate();vib_wait = 0.0

func _vib_update(dt: float) -> void :
	vib_wait -= dt
	while vib_wait <= 0.0 and vib_queue.size() > 0:
		var on: int = vib_queue.pop_front()
		Input.vibrate_handheld(on)
		var off: int = vib_queue.pop_front() if vib_queue.size() > 0 else 0
		vib_wait += (on + off) / 1000.0


func pick(w: Array) -> int:
	var tot: = 0.0
	for v in w: tot += v
	var r: = randf() * tot
	for i in w.size():
		r -= w[i]
		if r < 0: return i
	return w.size() - 1

func gauss() -> float:
	return sqrt(-2.0 * log(max(1e-09, randf()))) * cos(TAU * randf())


func set_anim(n: String, loop: = true) -> void :
	if anim_name != n: anim_t = 0.0
	anim_name = n;anim_loop = loop


const ANIM_SKIP: = {"reel": [3], "cast": [6], "trophy": [13]}

func anim_frame() -> int:
	var sp: float = anim_speed[anim_name]
	var hold: Dictionary = anim_hold.get(anim_name, {})
	var skip: Array = ANIM_SKIP.get(anim_name, [])
	var t: = anim_t
	var total: = 0.0
	for k in 16: total += 0.0 if k in skip else hold.get(k, sp)
	if anim_loop: t = fmod(t, total)
	for k in 16:
		var d: float = 0.0 if k in skip else hold.get(k, sp)
		if t < d: return k
		t -= d
	return 15

func start_cast() -> void :
	if not equipment.rod_equipped:
		holding = false
		show_tip("", "가방의 인벤토리에서 낚싯대를 장착해 주세요")
		return
	pond_stock = maxf(0.0, pond_stock - 1.0)
	S = {"phase": "cast", "t": 0.0}
	set_anim("cast", false);msg = ""
	_save_game()

func start_wait() -> void :
	var bait_multiplier: float = region_shop.take_bait(self)
	var bare: bool = bait_multiplier < 1.0
	var sp_w: = []
	var nparts: = 0
	for p in ["float", "hook", "line", "reel"]:
		if region_shop.has_active(self, p): nparts += 1
		else: break
	var stock_ratio: float = pond_stock / pond_max()
	for i in 5:
		var stock_weight: float = 1.0 if i == 0 else lerpf(0.04, 1.0, stock_ratio) ** i
		sp_w.append(STAR_P[i] * (0.1 if bare and i > 0 else 1.0) * stock_weight if i <= mini(nparts, 3) else 0.0)
	if pond_stock <= 0.0:
		sp_w = [1.0, 0.0, 0.0, 0.0, 0.0]
	var gp: = []
	for i in 5: gp.append(GRADE_P[i] * pow(bait_multiplier, i))
	S = {"phase": "wait", "star": pick(sp_w), "grade": pick(gp), "fakes": [], "bare": bare}
	S.lf = clampf(1.0 + gauss() * 0.15, 0.5, 1.65)
	S.size = 0 if S.lf < 0.9 else (1 if S.lf < 1.15 else (2 if S.lf < 1.35 else 3))
	var list: Array = BY_STAR[S.star]
	S.sp = list[randi() % list.size()]
	if not TUT.done: S.star = 0;S.grade = 0;S.tutFish = true;S.sp = 1
	S.lf = minf(S.lf, species_max_cm(S.sp) / FISH_LEN[S.sp])
	S.size = 0 if S.lf < 0.9 else (1 if S.lf < 1.15 else (2 if S.lf < 1.35 else 3))
	S.biteAt = clock + randf_range(BITE_WAIT[0], BITE_WAIT[1]) * (BAIT_WAIT_MUL if S.bare else 1.0) * (3.5 if pond_stock <= 0.0 else lerpf(1.0, 1.6, 1.0 - stock_ratio))
	S.fakeI = 0;ripples.clear()
	var t: = clock + randf_range(0.5, 0.9)
	while t < S.biteAt - 0.4:
		if randf() < 0.6: S.fakes.append(t)
		t += randf_range(0.5, 1.1)
	S.realUntil = S.biteAt + BITE_WINDOW[S.star]
	S.biteBuzzed = false
	set_anim("idle")
	msg = ""
	if not TUT.get("bite_hint_seen", TUT.done):
		msg = "찌가 쑥 잠기면 챔질! 톡톡은 가짜"
		TUT["bite_hint_seen"] = true;_save_tut()

func fail(text: String) -> void :
	S.failText = text;S.phase = "fail";S.t = 0.0
	set_anim("miss", false);msg = ""

func start_hook() -> void :
	play("hook");play("splash_s", -4.0 + 3.0 * S.size)
	S.phase = "hook";S.pos = 0.0;S.dir = 1;S.pauseUntil = 0.0
	S.barSp = BAR_SPEED[S.grade];S.zc = 0.5;star_hist.clear()
	msg = "별이 가운데 왔을 때 탭!";buzz(60)

func hook_tap() -> void :
	var d: float = abs(S.pos - S.zc)
	S.baseGrade = S.grade
	if d < BAR_PERF[S.grade]:
		S.judge = "PERFECT"
		if randf() < 0.2 and not S.get("tutFish", false):
			S.grade = min(4, S.grade + 1);show_judge("PERFECT 등급 UP!");buzz([30, 40, 30, 40, 60])
		else:
			show_judge("PERFECT");buzz([30, 40, 30])
	elif d < BAR_GREAT[S.grade]:
		S.judge = "GREAT";show_judge("GREAT");buzz(30)
	else:
		S.judge = "MISS";S.grade = max(0, S.grade - 1);show_judge("MISS")
	if S.get("tutFish", false): S.grade = 0
	S.len = FISH_LEN[S.sp] * S.lf
	S.phase = "pre";S.t = 0.0;msg = ""
	visibility_flash = 0.9 if S.judge != "MISS" else 0.0

func start_fight() -> void :
	S.merge({"phase": "fight", "dist": 0.0, "tension": 30.0, "slack": 0.0, "beh": "swim", "bt": 1.0, "jumpT": 0.0, 
		"jumpUsed": false, "landUntil": 0.0, "fx": 230.0, "fy": WATER + 200.0, "spike": 0.0, "noise": 1.0, 
		"chain": false, "fakeRest": false, "fakeTell": false, "pose": {}, "swimPh": 0.0, "dartV": 0.0, "dartX": 0.0, 
		"dartUntil": 0.0, "dartDir": 1, "dartSp": 1.0, "faceS": 1.0, "dispY": -1.0, "diveOff": 0.0, "diveDX": 0.0, 
		"chargeX": 0.0, "cloneT": 0.0, "cloneSub": "run", "cloneSw": 0.0, "cloneReal": 1, "diveDir": 1}, true)
	S.rod = rod_lv;S.line = 0;S.locMul = 1.0
	S.tensionMul = (1.0 - 0.08 * S.rod) * (1.0 - 0.02 * forge_lv)
	S.reelMul = (1.0 + 0.12 * S.rod) * (1.0 + 0.03 * forge_lv)
	S.chaos = (S.star + S.grade) / 8.0
	var u: = 0.3 if S.get("tutFish", false) else randf()
	S.F = (S.grade + 0.2 + 0.6 * u) / 4.8
	S.persona = "느긋함" if u < 0.34 else ("끈질김" if u < 0.67 else "날쌤")
	S.pSpeed = 0.85 + 0.3 * u;S.pTurn = 1.15 - 0.3 * u;S.pRange = randf_range(0.85, 1.15)
	msg = "누르면 감기, 떼면 풀기"
	parts.clear();aura_hist.clear();reveal_c = Vector2.INF;water_spawn_acc = 0.0;spawn_acc = 0.0
	S.lesson = "";S.tut = false
	if S.get("tutFish", false): S.tut = true;S.tutState = {"i": 0};tut_begin_step()
	if S.grade > 0:
		reveal_t = 1.0;reveal_pending = true
		show_toast(GRADE_N[S.grade] + "!", _aura_col(S.grade, clock * 1000.0, 1.0).lerp(Color.WHITE, 0.25))
		buzz([[0], [40], [40, 40, 60], [60, 40, 60, 40, 90], [80, 40, 80, 40, 80, 40, 160]][S.grade])

func show_judge(t: String) -> void :
	judge_txt = t;judge_t = 1.0
	judge_col = Color("ffe066") if t.begins_with("PERFECT") else (Color("8fe36a") if t == "GREAT" else Color("c9c9c9"))
	if t == "GREAT":
		for i in 8:
			var a: = randf() * TAU
			parts.append({"kind": "burst", "p": Vector2(VW / 2.0, WATER - 46), "v": Vector2(cos(a) * randf_range(35, 60), sin(a) * randf_range(15, 30)), "life": 0.45, "max": 0.45, "col": Color("b8f5a0"), "ph": 0.0, "sz": 2})
	if t.begins_with("PERFECT"):
		hitstop = 0.1;shake_t = 0.25
		for i in 18:
			var a: = randf() * TAU
			parts.append({"kind": "burst", "p": Vector2(VW / 2.0, WATER - 46), "v": Vector2(cos(a) * randf_range(50, 90), sin(a) * randf_range(20, 45)), "life": 0.55, "max": 0.55, "col": Color("ffe9a0") if i % 3 else Color.WHITE, "ph": 0.0, "sz": 2})

func show_toast(t: String, col: = Color.WHITE) -> void :
	toast_txt = t;toast_t = 1.2;toast_col = col

func vib_run() -> Array: return [160 + int(140 * S.grade / 4.0)]

func next_behavior() -> void :
	var g: int = S.grade
	var c: float = S.chaos
	var r: = randf()
	var pRun: = 0.25 + 0.05 * g
	var pJump: = 0.12
	var pDive: = 0.08 + 0.02 * g
	var pRest: = 0.25
	var x: = randf()
	var streak: int = S.get("runStreak", 0)
	if streak >= 2: r = pRun + randf() * (1.0 - pRun)
	var last: String = S.get("lastBeh", "")
	if (last == "turn" and x < 0.12) or (last == "clone" and x >= 0.12 and x < 0.22): x = 0.53 + randf() * 0.47
	for zone in [["sulk", 0.22, 0.3], ["circle", 0.3, 0.38], ["thrash", 0.38, 0.46], ["skim", 0.46, 0.53]]:
		if last == zone[0] and x >= zone[1] and x < zone[2]: x = 0.53 + randf() * 0.47
	_next_behavior_pick(g, c, r, x, pRun, pJump, pDive, pRest)
	S.runStreak = streak + 1 if S.beh == "tell" else 0
	if S.beh != "swim": S.lastBeh = S.beh

func _next_behavior_pick(g: int, c: float, r: float, x: float, pRun: float, pJump: float, pDive: float, pRest: float) -> void :
	if g >= 3 and x < 0.12:
		S.beh = "turn";S.bt = 0.45;buzz([220]);return
	if g == 4 and x < 0.22:
		S.beh = "clone";S.bt = 2.4;S.cloneT = 0.0;S.cloneReal = randi() % 3
		S.cloneSub = "run" if randf() < 0.5 else "rest";S.cloneSw = randf_range(0.6, 0.9);buzz([30, 30, 30, 30, 30]);return
	if g >= 1 and x >= 0.22 and x < 0.3:
		S.beh = "sulk";S.bt = randf_range(2.0, 3.0);S.holdT = 0.0;buzz([200, 80, 200]);return
	if g >= 2 and x >= 0.3 and x < 0.38:
		S.beh = "circle";S.bt = randf_range(2.6, 3.4);S.circA = 0.0;buzz([40, 60, 40, 60, 40]);return
	if g >= 2 and x >= 0.38 and x < 0.46:
		S.beh = "thrash";S.bt = randf_range(1.6, 2.4);S.thT = 0.0;buzz([60, 30, 60, 30, 60, 30, 60]);return
	if g >= 3 and x >= 0.46 and x < 0.53:
		S.beh = "skim";S.bt = randf_range(1.0, 1.5);S.skimDir = -1 if randf() < 0.5 else 1;buzz(vib_run());play("splash_s", -4.0);return
	if r < pRun:
		S.beh = "tell";S.bt = max(0.4, (0.4 if g >= 3 else 0.7) * randf_range(1.0 - 0.5 * c, 1.0));S.fakeTell = randf() < 0.35 * c;buzz([25, 45, 25])
	elif r < pRun + pJump:
		S.beh = "rise";S.bt = 0.6;buzz([20, 30, 20, 30, 20])
	elif r < pRun + pJump + pDive:
		S.beh = "nose";S.bt = max(0.4, 0.6 * randf_range(1.0 - 0.4 * c, 1.0));S.diveDir = -1 if randf() < 0.5 else 1;buzz([35, 35, 90])
	elif r < pRun + pJump + pDive + pRest:
		S.beh = "rest";S.fakeRest = randf() < 0.5 * c;S.bt = randf_range(1.0, 1.8) * (randf_range(0.3, 0.6) if S.fakeRest else 1.0)
	else:
		S.beh = "swim";S.bt = randf_range(0.8, 1.8)




const LESSON: = {
	"swim": {"t": "헤엄", "hand": ["hold", "꾹 누르기"], "text": "꼬리를 천천히 흔들 땐 그냥 감으면 돼요.", "anim": [["swim", 1.2]]}, 
	"tell": {"t": "웅크림 → 돌진", "hand": ["rel", "손 떼기"], "text": "몸을 C자로 말면 곧 돌진해요. 웅크리는 순간 미리 손을 떼요.", "anim": [["swim", 0.5], ["tell", 0.9], ["run", 1.1], ["rest", 0.5]]}, 
	"rest": {"t": "축 늘어짐", "hand": ["hold", "꾹 누르기"], "text": "지쳐서 축 늘어지면 기회! 이때 꾹 감아요.", "anim": [["rest", 1.4]]}, 
	"jump": {"t": "솟구침 → 점프", "hand": ["rel", "손 떼기 → 떨어질 때 탭"], "text": "머리를 들고 솟구치면 곧 점프해요. 손을 떼고, 물에 떨어지는 순간 탭!", "anim": [["rise", 0.8], ["jump", 0.9], ["land", 0.4], ["rest", 0.6]]}, 
	"spike": {"t": "급당김", "hand": ["rel", "잠깐 손 떼기"], "text": "예고 없이 머리를 홱 흔들어요. 잠깐 손을 뗐다가 다시 감아요.", "anim": [["swim", 0.7], ["spike", 0.5]]}, 
	"charge": {"t": "몸 돌림 → 역돌진", "hand": ["hold", "꾹 누르기"], "text": "나를 향해 몸을 돌리면 내 쪽으로 돌진해요. 줄이 느슨해지니까 손을 떼지 말고 꾹 감아요.", "anim": [["turn", 0.7], ["charge", 1.0]], "face": -1}, 
	"dive": {"t": "머리 숙임 → 잠수", "hand": ["rel", "짧게 손 떼기"], "text": "머리를 숙이고 꼬리를 치켜들면 곧 아래로 파고들어요. 손을 떼되, 너무 오래 떼면 거리를 잃어요.", "anim": [["nose", 0.7], ["dive", 1.0]]}, 
	"clone": {"t": "분신", "hand": ["look", "줄 따라 보기"], "text": "그림자가 셋으로 갈라져요. 줄이 이어진 놈의 몸짓만 보고 판단해요.", "anim": [["clone", 2.0]]}, 
	"sulk": {"t": "버티기", "hand": ["pump", "짧게 감았다 떼기"], "text": "바닥에 딱 붙어 버텨요. 계속 감으면 텐션만 올라요. 톡톡 짧게 감았다 떼기를 반복해요.", "anim": [["sulk", 2.0]]}, 
	"circle": {"t": "맴돌기", "hand": ["hold", "다가올 때만 감기"], "text": "원을 그리며 돌아요. 나한테 다가올 때 감고, 멀어질 땐 손을 떼요.", "anim": [["circle", 2.4]]}, 
	"thrash": {"t": "몸부림", "hand": ["pump", "출렁일 때 떼기"], "text": "제자리에서 몸을 마구 비틀어요. 크게 비틀 때마다 잠깐 떼고, 사이사이 감아요.", "anim": [["thrash", 1.8]]}, 
	"skim": {"t": "수면 질주", "hand": ["rel", "떼기 → 멈추면 감기"], "text": "수면으로 올라와 물보라를 끌며 달려요. 손을 떼고, 물보라가 멈추는 순간 감으면 보너스!", "anim": [["skim", 1.4], ["rest", 0.4]]}, 
}
const TUT_STEPS: = [
	{"key": "swim", "ask": "헤엄칠 땐 꾹 눌러 감기", "demo": [["swim", 1.8]], "need": 1}, 
	{"key": "tell", "ask": "웅크리면 바로 손 떼기", "demo": [["swim", 0.8], ["tell", 0.8], ["run", 1.0]], "practice": [["swim", [1.0, 2.0]], ["tell", 0.7], ["run", 1.0]], "need": 2}, 
	{"key": "rest", "ask": "늘어지면 꾹 감기", "demo": [["swim", 0.8], ["rest", 1.6]], "practice": [["swim", [0.8, 1.6]], ["rest", 1.6]], "need": 2}, 
]
const LESSON_OF: = {"rise": "jump", "nose": "dive", "turn": "charge", "clone": "clone", "sulk": "sulk", "circle": "circle", "thrash": "thrash", "skim": "skim"}


func _load_set() -> void :
	if FileAccess.file_exists("user://settings.json"):
		var d = JSON.parse_string(FileAccess.open("user://settings.json", FileAccess.READ).get_as_text())
		if d is Dictionary: SET.merge(d, true)

func _save_set() -> void :
	FileAccess.open("user://settings.json", FileAccess.WRITE).store_string(JSON.stringify(SET))

func _draw_settings() -> void :
	text_items.clear()
	if set_view == "license":
		_draw_font_license();return
	if set_view == "book":
		if lesson_open: return
		_draw_book();return
	var h: = get_viewport_rect().size.y
	_ui_rect(Rect2( - ox, 0, VW + 2 * ox, h), Color(0.04, 0.06, 0.1, 0.84))
	var r: = Rect2(25, roundf(h * 0.42) - 112, 220, 224)
	_ui_style_box(sb_panel, r)
	preload("res://addons/reservoir/ui_theme.gd").title(self, r, "설정")
	var cr: = Rect2(r.end.x - 31, r.position.y + 9, 22, 23)
	_ui_texture(icons["close"], cr.position)

	var y1: = r.position.y + 70
	_text("효과음", Vector2(42, y1 + 5), 11, Color("382619"))
	var tr: = Rect2(100, y1 - 7, 125, 14)
	_ui_style_box(sb_meter, tr)
	var fw: = int((tr.size.x - 24) * SET.sfx)
	if fw >= 4:
		_ui_rect(Rect2(tr.position.x + 12, y1 - 4, fw, 8), Color("8ead72"))
	_ui_texture(icons["knob"], Vector2(int(tr.position.x + 12 + (tr.size.x - 24) * SET.sfx) - 6, y1 - 9))

	var y2: = y1 + 40
	_text("진동", Vector2(42, y2 + 5), 11, Color("382619"))
	var tg: Texture2D = icons["toggle_on" if SET.vib else "toggle_off"]
	var gr: = Rect2(100, y2 - 8, tg.get_width(), tg.get_height())
	_ui_texture(tg, gr.position)
	_text("켜짐" if SET.vib else "꺼짐", Vector2(142, y2 + 5), 10, Color("3d2414"))

	var br: = Rect2(45, y2 + 26, 180, 30)
	_ui_style_box(sb_btn, br)
	_text("몸짓 도감", Vector2(VW / 2.0, br.position.y + 19), 11, Color("382619"), true)
	var lr: = Rect2(60, r.end.y - 53, 150, 20)
	_text("글꼴 · 오픈소스 라이선스", Vector2(VW / 2.0, lr.position.y + 14), 9, Color("5a3e28"), true)

	_text("버전 v" + _ver_name(), Vector2(VW / 2.0, r.end.y - 22), 9, Color("5a3e28"), true)
	set_rects = {"close": cr.grow(6), "slider": Rect2(tr.position.x, y1 - 14, tr.size.x, 28), "vib": Rect2(gr.position.x - 6, y2 - 14, 80, 28), "tut": br, "license": lr, "panel": r}

func _draw_font_license() -> void :
	var h: = get_viewport_rect().size.y
	_ui_rect(Rect2( - ox, 0, VW + 2 * ox, h), Color(0.04, 0.06, 0.1, 0.7))
	var r: = Rect2(15, roundf(h / 2) - 170, 240, 340)
	_ui_style_box(sb_panel, r)
	_text("Neo둥근모 · OFL 1.1", Vector2(VW / 2.0, r.position.y + 32), 11, Color("382619"), true, 190)
	var cr: = Rect2(r.end.x - 34, r.position.y + 12, 22, 23)
	_ui_texture(icons.close, cr.position)
	var lines: Array[String] = []
	for paragraph in FileAccess.get_file_as_string("res://font/NEODGM_LICENSE.txt").split("\n"):
		var line: = ""
		for word in paragraph.split(" ", false):
			var trial: = word if line == "" else line + " " + word
			if _text_w(trial, 9) > 208 and line != "": lines.append(line);line = word
			else: line = trial
		lines.append(line)
	var pages: = maxi(1, ceili(lines.size() / 18.0))
	font_license_page = clampi(font_license_page, 0, pages - 1)
	for i in 18:
		var idx: = font_license_page * 18 + i
		if idx < lines.size(): _text(lines[idx], Vector2(31, r.position.y + 58 + i * 12), 9, Color("382619"), false, 208)
	var prev: = Rect2(30, r.end.y - 40, 70, 27)
	var next: = Rect2(170, r.end.y - 40, 70, 27)
	_ui_style_box(sb_btn, prev);_ui_style_box(sb_btn, next)
	_text("이전", prev.get_center() + Vector2(0, 4), 10, Color("382619"), true)
	_text("다음", next.get_center() + Vector2(0, 4), 10, Color("382619"), true)
	_text("%d / %d" % [font_license_page + 1, pages], Vector2(VW / 2.0, r.end.y - 23), 9, Color("382619"), true)
	set_rects = {"close": cr.grow(4), "panel": r, "prev": prev, "next": next, "pages": pages}


func _ver_name() -> String:
	if get_tree().root.has_meta("ver"): return str(get_tree().root.get_meta("ver"))
	if FileAccess.file_exists("user://patch_ver.txt") and FileAccess.file_exists("user://patch.pck"):
		var t: = FileAccess.open("user://patch_ver.txt", FileAccess.READ).get_as_text().strip_edges()
		return t.get_slice("|", 1) if t.contains("|") else "0." + t
	return "0.11"

func _slider_set(x: float) -> void :
	var tr: Rect2 = set_rects.slider
	SET.sfx = clampf((x - tr.position.x - 12) / (tr.size.x - 24), 0.0, 1.0)


const BOOK_KEYS: = ["swim", "tell", "rest", "jump", "spike", "dive", "charge", "clone", "sulk", "circle", "thrash", "skim"]

func _draw_book() -> void :
	var h: = get_viewport_rect().size.y
	_ui_rect(Rect2( - ox, 0, VW + 2 * ox, h), Color(0.04, 0.06, 0.1, 0.6))
	var r: = Rect2(20, roundf(h * 0.42) - 150, 230, 300)
	_ui_style_box(sb_panel, r)
	var n: = 0
	for k in BOOK_KEYS: if k in TUT.seen: n += 1
	preload("res://addons/reservoir/ui_theme.gd").title(self, r, "몸짓 도감 %d/%d" % [n, BOOK_KEYS.size()])
	var cr: = Rect2(r.end.x - 31, r.position.y + 9, 22, 23)
	_ui_texture(icons["close"], cr.position)
	var rects: = {}
	for i in BOOK_KEYS.size():
		var k: String = BOOK_KEYS[i]
		var b: = Rect2(36 + (i % 2) * 102, r.position.y + 50 + int(i / 2) * 34, 96, 30)
		var seen: bool = k in TUT.seen
		if seen: _ui_style_box(sb_btn, b)
		else: _ui_style_box(sb_chip, b)
		_text(LESSON[k].t if seen else "???", Vector2(b.get_center().x, b.position.y + 19), 9, Color("382619") if seen else Color("8a7a66"), true, 88)
		if seen: rects[k] = b
	_text("본 몸짓을 누르면 다시 볼 수 있어요", Vector2(VW / 2.0, r.end.y - 22), 9, Color("5a3e28"), true)
	set_rects = {"close": cr.grow(6), "panel": r, "book": rects}

func _settings_press(pos: Vector2) -> void :
	if set_view == "license":
		if set_rects.close.has_point(pos) or not set_rects.panel.has_point(pos): set_view = "main";return
		if set_rects.prev.has_point(pos): font_license_page = maxi(0, font_license_page - 1)
		if set_rects.next.has_point(pos): font_license_page = mini(set_rects.pages - 1, font_license_page + 1)
		return
	if set_rects.get("license", Rect2()).has_point(pos): set_view = "license";font_license_page = 0;return
	if set_rects.is_empty(): return
	if lesson_open and lesson_after == "book": close_card(true);return
	if set_view == "book":
		if set_rects.close.has_point(pos) or not set_rects.panel.has_point(pos): set_view = "main";return
		for k in set_rects.book:
			if set_rects.book[k].has_point(pos): open_card(k, "book");return
		return
	if set_rects.close.has_point(pos) or not set_rects.panel.has_point(pos):
		settings_open = false;set_view = "main";_save_set();return
	if set_rects.slider.has_point(pos): slider_drag = true;_slider_set(pos.x);return
	if set_rects.vib.has_point(pos):
		SET.vib = not SET.vib;_save_set()
		if SET.vib: buzz(60)
		return
	if set_rects.tut.has_point(pos): set_view = "book"

func _load_tut() -> void :
	if FileAccess.file_exists("user://tut.json"):
		var d = JSON.parse_string(FileAccess.open("user://tut.json", FileAccess.READ).get_as_text())
		if d is Dictionary: TUT = d

func _save_tut() -> void :
	FileAccess.open("user://tut.json", FileAccess.WRITE).store_string(JSON.stringify(TUT))

func _seen(k: String) -> void :
	if not (k in TUT.seen): TUT.seen.append(k)

func tut_step() -> Dictionary: return TUT_STEPS[S.tutState.i]

func tut_begin_step() -> void :
	var T: Dictionary = S.tutState
	T.mode = "demo";T.ok = 0
	msg = "연습용 붕어가 「%s」 몸짓을 보여 줘요" % LESSON[tut_step().key].t
	start_seq(tut_step().demo)

func start_seq(seq: Array) -> void :
	var T: Dictionary = S.tutState
	T.seq = seq;T.si = -1;T.holdAcc = 0.0
	next_seq()

func next_seq() -> void :
	var T: Dictionary = S.tutState
	var st: = tut_step()
	T.si += 1
	if T.si >= T.seq.size(): seq_end();return
	var b: String = T.seq[T.si][0]
	var d = T.seq[T.si][1]
	S.beh = b;T.sbt = randf_range(d[0], d[1]) if d is Array else float(d)
	if b == "tell": buzz([25, 45, 25])
	if b == "run":
		buzz(vib_run())
		if T.mode == "practice" and st.key == "tell":
			if not holding: T.ok += 1;show_toast("좋아요! 미리 손을 뗐어요 (%d/%d)" % [T.ok, st.need])
			else: S.tension += 35;buzz([60, 30, 160]);show_toast("늦었어요! 웅크리는 순간 떼요")

func seq_end() -> void :
	var T: Dictionary = S.tutState
	var st: = tut_step()
	if T.mode == "demo": open_card(st.key, "practice");return
	if st.key == "rest":
		if T.holdAcc >= 1.0: T.ok += 1;show_toast("좋아요! 지쳤을 때 감기 (%d/%d)" % [T.ok, st.need])
		else: show_toast("늘어지면 꾹 감아요!")
	if T.ok >= st.need: step_done();return
	start_practice()

func start_practice() -> void :
	var T: Dictionary = S.tutState
	var st: = tut_step()
	T.mode = "practice"
	msg = "직접 해 보세요 · " + st.ask
	if st.key == "swim": S.beh = "swim";T.seq = [];T.holdAcc = 0.0
	else: start_seq(st.practice)

func step_done() -> void :
	var T: Dictionary = S.tutState
	T.i += 1
	if T.i < TUT_STEPS.size(): show_toast("잘했어요!");tut_begin_step();return
	_tut_finish()
	show_toast("튜토리얼 끝! 이제 실전")
	msg = "이제 실전! 거리를 끝까지 채워 잡아 보세요"

func _tut_finish() -> void :
	TUT.done = true
	for k in ["swim", "tell", "rest"]: _seen(k)
	_save_tut()
	S.tut = false;S.beh = "swim";S.bt = 1.0


func tut_update(dt: float) -> bool:
	var T: Dictionary = S.tutState
	var st: = tut_step()
	if lesson_open: return false
	if T.mode == "practice" and st.key == "swim":
		if holding: T.holdAcc += dt
		if T.holdAcc >= 1.5: show_toast("좋아요!");step_done()
		return true
	if T.mode == "practice" and S.beh == "rest" and holding: T.holdAcc += dt
	T.sbt -= dt
	if T.sbt <= 0: next_seq()
	return T.mode == "practice"

func skip_tut() -> void :
	if S.get("tut", false): _tut_finish();msg = "누르면 감기, 떼면 풀기"
	else:
		TUT.done = true
		for k in ["swim", "tell", "rest"]: _seen(k)
		_save_tut()
	close_card(true)

func open_card(key: String, after: String) -> void :
	lesson_open = true;lesson_key = key;lesson_after = after;holding = false;lesson_clock = ui_clock

func close_card(skip_after: = false) -> void :
	if not lesson_open: return
	lesson_open = false
	var a: = lesson_after
	lesson_after = ""
	if not skip_after and a == "practice": start_practice()

func lesson_end() -> void :
	var k: String = S.lesson
	S.lesson = "";_seen(k);_save_tut();open_card(k, "")

func time_scale() -> float:
	if lesson_open: return 0.0
	if S.phase != "fight": return 1.0
	if S.get("tut", false) and S.tutState.mode == "demo" and S.beh != "swim": return 0.35
	match S.get("lesson", ""):
		"jump": return 0.35 if S.beh == "rise" else 0.55
		"charge": return 0.35 if S.beh == "turn" else 0.6
		"dive": return 0.35 if S.beh == "nose" else 0.6
		"clone": return 0.5
		"spike": return 0.3
		"sulk", "circle", "thrash", "skim": return 0.5
	return 1.0


func lesson_step_duration(key: String, step: Array) -> float:
	return float(step[1]) * (8.0 if key == "jump" and step[0] == "land" else 2.0)

func lesson_frame(key: String, elapsed: float) -> Dictionary:
	var sequence: Array = LESSON[key].anim
	var total := 0.0
	for step in sequence: total += lesson_step_duration(key, step)
	var remaining := fposmod(elapsed, total)
	var index := 0
	while index < sequence.size()-1 and remaining >= lesson_step_duration(key, sequence[index]):
		remaining -= lesson_step_duration(key, sequence[index]);index += 1
	var beh: String = sequence[index][0]
	var k: float = remaining / (lesson_step_duration(key, sequence[index]))
	var cue: String = LESSON[key].hand[1]
	if key == "jump": cue = "착수! 지금 탭" if beh == "land" else ("다시 감기" if beh == "rest" else "공중에서는 손 떼기" if beh == "jump" else "전조 · 미리 손 떼기")
	elif key == "tell": cue = "웅크림 · 지금 손 떼기" if beh == "tell" else ("돌진 중 · 손 떼기" if beh == "run" else "꾹 눌러 감기")
	elif key == "skim": cue = "멈춤! 지금 감기" if beh == "rest" else "물보라 동안 손 떼기"
	elif key == "spike": cue = "급당김! 잠깐 떼기" if beh == "spike" else "꾹 눌러 감기"
	elif key == "circle": cue = "다가오는 중 · 감기" if sin(k * TAU) > 0 else "멀어지는 중 · 떼기"
	elif key == "thrash": cue = "크게 비틀 때 · 떼기" if sin(remaining / 2.0 * 9.0) > 0.4 else "사이사이 · 감기"
	elif key == "dive": cue = "머리 숙임 · 미리 떼기" if beh == "nose" else "잠수 중 · 손 떼기"
	elif key == "charge": cue = "몸 돌림 · 계속 감기" if beh == "turn" else "다가오는 중 · 꾹 감기"
	return {"beh": beh, "k": k, "cue": cue, "motion_time": k * float(sequence[index][1])}

func _draw_lesson_card(t: float) -> void :
	ui_demo = true
	var L: Dictionary = LESSON[lesson_key]
	var h: = get_viewport_rect().size.y
	_ui_rect(Rect2( - ox, 0, VW + 2 * ox, h), Color(0.04, 0.06, 0.1, 0.55))
	_ui_style_box(sb_panel, Rect2(20, 150, 230, 330 if lesson_after == "practice" or S.get("tut", false) else 300))

	var bx: = 45.0
	var by: = 166.0
	_ui_rect(Rect2(bx, by, 180, 94), Color("2a5c76"))
	_ui_rect(Rect2(bx, by, 180, 32), Color("3d7d97"))
	_ui_rect(Rect2(bx, by + 32, 180, 1), Color(1, 1, 1, 0.5))
	var frame := lesson_frame(lesson_key, ui_clock - lesson_clock)
	var beh: String = frame.beh
	var k: float = frame.k
	t = frame.motion_time * 1000.0
	var demo_sp: int = int(S.get("sp", 1))
	var x: = bx + 90.0
	var y: = by + 50.0
	if beh == "rise": y = by + 62 - 30 * k * k
	if beh == "jump": y = by + 32 - sin(k * PI) * 19
	if beh == "land":
		y = by + 32 + k * 20
		for j in 5: _ui_rect(Rect2(bx + 70 + j * 10, by + 31 - sin(k * PI) * 5, 3, 2), Color("d9faff"))
	if beh == "run": x = bx + 48 + k * 95
	if beh == "charge": x = bx + 112 - 50 * k
	if beh == "nose": y = by + 42
	if beh == "dive": y = by + 42 + 28 * k;x = bx + 90 + 22 * k
	if beh == "sulk": y = by + 70
	if beh == "circle": x = bx + 90 + cos(k * TAU) * 40;y = by + 48 + sin(k * TAU) * 16
	if beh == "thrash": x = bx + 90 + sin(t / 30.0) * 2
	if beh == "skim":
		y = by + 36;x = bx + 30 + 120 * k
		for j in 4: _ui_rect(Rect2(int(x - 18 - j * 7), by + 30 - (j % 2) * 2, 3, 2), Color(0.9, 0.97, 1, 0.8))
	var face: float = 1.0 if beh in ["run", "skim"] else -1.0
	if beh == "circle": face = -1.0 if sin(k * TAU) > 0 else 1.0
	if beh == "skim": face = 1.0
	if beh == "clone":
		var sp: = minf(1.0, k * 4)
		var pos: = [[bx + 50, by + 36], [bx + 90, by + 54], [bx + 132, by + 42]]
		_line(Vector2(bx + 176, by + 1), Vector2(bx + 90 + 42 * sp, by + 54 - 12 * sp), Color(1, 1, 1, 0.8))
		for j in 3:
			var p: = Vector2(bx + 90 + (pos[j][0] - bx - 90) * sp, by + 54 + (pos[j][1] - by - 54) * sp)
			_shadow_fish(p, 0, 0, t + j * 137, "run" if j == 2 else "rest", false, 2.0, {}, t / 1000.0 * TAU * 2, demo_sp, -1.0, 1.0)
	else:
		_shadow_fish(Vector2(x, y), 0, 0, t, "swim" if beh == "spike" else ("rest" if beh == "land" else beh), beh == "spike", 2.2, {}, t / 1000.0 * TAU * (3.0 if beh == "run" else 1.2), demo_sp, face, 1.0)
	_text(L.t, Vector2(VW / 2.0, 280), 12, Color("382619"), true, 200)
	var hc: = Color("7cc96a") if L.hand[0] == "hold" else (Color("ff9a3c") if L.hand[0] == "rel" else (Color("ffd24a") if L.hand[0] == "pump" else Color("7fb6ff")))
	var hw: = ceilf(_text_w(frame.cue, 9)) + 24
	sb_chip.modulate_color = hc.lerp(Color.WHITE, 0.35)
	_ui_style_box(sb_chip, Rect2(VW / 2.0 - hw / 2, 288, hw, 25))
	sb_chip.modulate_color = Color.WHITE
	_text(frame.cue, Vector2(VW / 2.0, 304), 9, Color("3a2414"), true, hw)
	_text(_ui_wrap(L.text, 11, 196, 3), Vector2(VW / 2.0, 330), 11, Color("382619"), true, 196)
	_text(_ui_wrap(LESSON_EXTRA.get(lesson_key, "몸짓의 예고를 보고 손을 바꿔 보세요."), 10, 198, 3), Vector2(135, 389), 10, Color("68533d"), true, 198)
	_text("아무 곳이나 탭하면 계속", Vector2(VW / 2.0, 432), 9, Color("5a3e28"), true)
	if S.get("tut", false):
		_ui_style_box(sb_btn, SKIP_RECT)
		_text("튜토리얼 건너뛰기", Vector2(VW / 2.0, SKIP_RECT.position.y + 15), 9, Color("3a2414"), true)
	ui_demo = false

func shock_amount(k: float) -> float:
	return k * (20 + 8 * S.star + 4 * S.grade) * S.tensionMul * (1.0 - 0.1 * S.line) * S.locMul

func update_fight(dt: float) -> void :
	if S.tut:
		if not tut_update(dt): return
	else: S.bt -= dt
	if not S.tut and S.bt <= 0:
		var ended: String = S.beh
		if S.beh == "tell":
			if S.fakeTell: S.beh = "swim";S.bt = randf_range(0.6, 1.2)
			else:
				S.beh = "run";S.bt = randf_range(0.6, 1.2) * (1 + 0.08 * S.grade) * (1 + 0.4 * S.chaos * randf());S.chain = randf() < 0.4 * S.chaos;buzz(vib_run())
				if holding: S.tension += shock_amount(1.0);buzz([80, 30, 220]);play("drag", 2.0, 0.6)
		elif S.beh == "turn": S.beh = "charge";S.bt = randf_range(1.0, 1.4);buzz(vib_run())
		elif S.beh == "nose":
			S.beh = "dive";S.bt = randf_range(0.7, 1.1) * (1 + 0.1 * S.grade);buzz([110, 40, 140])
			if holding: S.tension += shock_amount(0.6);buzz([80, 30, 220])
		elif S.beh == "rise": S.beh = "jump";S.bt = 0.9;S.jumpUsed = false;S.jumpT = 0.0;buzz(40);play("splash_s", -6.0)
		elif S.beh == "jump": S.landUntil = clock + 0.4;buzz([70]);play("splash_b", -6.0 + 6.0 * S.star / 4.0);next_behavior()
		elif S.beh == "run" and S.chain and S.get("runStreak", 0) < 2: S.chain = false;S.runStreak = S.get("runStreak", 0) + 1;S.beh = "tell";S.bt = 0.4;S.fakeTell = false;buzz([25, 45, 25])
		elif S.beh == "rest" and S.fakeRest: S.fakeRest = false;S.beh = "tell";S.bt = 0.4;S.fakeTell = false;buzz([25, 45, 25])
		else:
			if S.beh == "skim": S.skimEnd = clock + 0.4;S.skimUsed = holding
			next_behavior()
		if S.lesson != "" and S.lesson == {"jump": "jump", "dive": "dive", "charge": "charge", "clone": "clone", "sulk": "sulk", "circle": "circle", "thrash": "thrash", "skim": "skim"}.get(ended, "?"): lesson_end()
		elif S.lesson == "" and LESSON_OF.has(S.beh) and not (LESSON_OF[S.beh] in TUT.seen): S.lesson = LESSON_OF[S.beh]
	if S.beh == "clone":
		S.cloneT += dt;S.cloneSw -= dt
		if S.cloneSw <= 0: S.cloneSub = "rest" if S.cloneSub == "run" else "run";S.cloneSw = randf_range(0.6, 0.9)
	var c: float = S.chaos
	S.noise = max(0.7, min(1 + 0.6 * c, S.noise + randf_range(-1, 1) * c * 3 * dt))
	if S.spike > 0:
		S.spike -= dt
		if S.spike <= 0 and S.lesson == "spike": lesson_end()
	elif c > 0 and not S.tut and S.lesson == "" and not (S.beh in ["rest", "rise", "jump", "nose", "dive", "turn", "charge", "clone"]) and randf() < c * 0.35 * dt:
		S.spike = 0.25;buzz([40 + int(60 * S.grade / 4.0)])
		if not ("spike" in TUT.seen): S.lesson = "spike"
	var bmt: = {"swim": 1.0, "tell": 1.0, "run": 2.2, "rest": 0.35, "rise": 1.0, "jump": 0.0, "nose": 1.0, "dive": 2.0, "turn": 1.0, "charge": 0.3, 
		"sulk": 3.0, "circle": 1.0, "thrash": 1.0, "skim": 2.4}
	var bm: float = bmt[S.cloneSub if S.beh == "clone" else S.beh]
	S.holdT = S.get("holdT", 0.0) + dt if holding else 0.0
	if S.beh == "circle":
		S.circA += dt * (2.2 + 1.2 * S.F)
		bm = 0.5 if sin(S.circA) > 0 else 2.4
	if S.beh == "thrash":
		S.thT += dt
		var pk: = sin(S.thT * (9.0 + 4.0 * S.F))
		bm = 3.2 if pk > 0.4 else 0.4
		if pk > 0.4 and S.get("thPk", false) == false: buzz([50]);S.thPk = true
		elif pk <= 0.4: S.thPk = false
	var pull: float = PULL[S.star] * S.locMul * (1 + 0.12 * S.grade) * bm * S.noise * (1.8 if S.spike > 0 else 1.0)
	if holding:
		S.tension += (pull * 20 - 12) * S.tensionMul * dt
		S.dist += max(3.0, 16 - pull * 3.5) * S.reelMul * dt
		if S.beh == "sulk" and S.holdT < 0.45:
			S.dist += 11 * S.reelMul * dt;S.tension -= (pull * 10) * S.tensionMul * dt
		if S.beh == "charge": S.dist += 10 * S.reelMul * dt;S.tension -= 20 * dt
		if S.beh == "jump" and S.jumpT > 0.25: S.tension += 90 * S.tensionMul * S.locMul * dt
		S.slack = 0.0
	else:
		S.tension -= 40 * dt
		S.dist -= pull * 2 * dt
		S.slack += dt * (2.5 if S.beh == "charge" else (0.5 if S.beh == "skim" else 1.0))
	if S.get("skimEnd", 0.0) > 0 and clock <= S.skimEnd and holding and not S.get("skimUsed", true):
		S.skimUsed = true;S.dist += 8;show_toast("물보라 멈춤 챔질! +8");buzz([40, 30, 80])
	S.tension = max(0.0, S.tension);S.dist = clamp(S.dist, 0.0, 100.0)
	if S.tut:
		S.tension = minf(S.tension, 95.0);S.dist = minf(S.dist, 90.0)
		if S.slack > 3.5: S.slack = 0.0
	if S.beh == "jump": S.jumpT += dt
	if S.tension >= 100:
		play("snap");buzz([200, 60, 300])
		fail("점프할 때 감고 있어서 바늘이 털렸어요" if S.beh == "jump" else "줄이 끊어졌어요. 돌진할 땐 손을 떼세요")
		return
	if S.slack > 4:
		play("plop")
		fail("나를 향해 돌진할 땐 꾹 감아야 해요" if S.beh == "charge" else "줄이 너무 오래 느슨해서 바늘이 빠졌어요")
		return
	if S.dist >= 100: start_catch()

func sfx_update(dt: float) -> void :
	var active: bool = scene == "fish" and not title_open and S.phase == "fight" and holding and not settings_open and not market_open and not mailbox.opened and not guide.opened and SET.sfx > 0.01
	if not active:
		drag_player.stop();return
	drag_player.volume_db = linear_to_db(SET.sfx) - 5.0
	if not drag_player.playing: drag_player.play()
	if S.tension > 82:
		creak_t -= dt
		if creak_t <= 0: play("creak", -12.0);creak_t = 0.28


func start_catch() -> void :
	holding = false
	if not S.get("capture_logged", false):
		S.capture_logged = true
		var name: String = FISH_NAME[S.sp]
		var counts: Array = catch_counts.get(name, [0, 0, 0, 0, 0])
		counts[int(S.grade)] += 1;catch_counts[name] = counts
	var prev: float = REC.get(FISH_NAME[S.sp], 0.0)
	S.prevRec = prev;S.newRec = S.len > prev
	var seen: Array = DEX.get(FISH_NAME[S.sp], [])
	if not S.grade in seen: seen.append(S.grade)
	DEX[FISH_NAME[S.sp]] = seen
	S.weight = W_BASE[S.star] * pow(S.lf, 3) * W_GRADE[S.grade]
	if S.newRec:
		REC[FISH_NAME[S.sp]] = S.len;_save_rec()
	S.phase = "catch";S.t = 0.0;S.recFx = false
	S.netEnd = 16 * 0.13 + 0.6
	S.catchEnd = S.netEnd + (6.6 - 0.7 if S.newRec else 3.8 - 0.7)
	set_anim("net", false);play("splash_b");buzz([60, 60, 120]);msg = "잡았다!"
	_save_game()
	if S.grade == 4: hitstop = 0.5;shake_t = 0.5;buzz([120, 40, 120, 40, 300])

func update_catch(dt: float) -> void :
	S.t += dt
	var T: float = S.t - S.netEnd + 0.7
	if S.newRec and not S.recFx and T > 3.0:
		S.recFx = true;play("record");buzz([40, 40, 40, 40, 160])
	if S.newRec and T > 4.4 and anim_name != "trophy": set_anim("trophy", false)
	if S.t >= S.catchEnd: show_result(true)

func show_result(ok: bool) -> void :
	S.phase = "result";S.ok = ok;result_t = 0.0
	if ok:
		play("catch");buzz([60, 60, 120]);set_anim("idle")
	msg = "보관통에 넣거나 놓아줘요" if ok else "터치하면 다시 던지기"


func _unhandled_input(e: InputEvent) -> void :
	if title_open:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed: title_screen.press(self, e.position - Vector2(ox, 0))
		return
	if guide.opened:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed: guide.press(self, e.position - Vector2(ox, 0))
		return
	if mailbox.opened:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed: mailbox.press(self, e.position - Vector2(ox, 0))
		return
	if not V.commerce.pending.is_empty() or inventory.selected >= 0:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed: press(e.position - Vector2(ox, 0))
		return
	if scene == "spots" and spots.input_event(self, e): return
	if scene == "village" and V.input_event(self, e): return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed: press(e.position - Vector2(ox, 0))
		else:
			holding = false
			if slider_drag: slider_drag = false;_save_set()
	elif e is InputEventMouseMotion and slider_drag:
		_slider_set(e.position.x - ox)

func press(pos: = Vector2.ZERO) -> void :
	if title_open: title_screen.press(self, pos);return
	if not trans.is_empty(): return
	if guide.opened: guide.press(self, pos);return
	if mailbox.opened: mailbox.press(self, pos);return
	if not equipment.pending_sale.is_empty(): equipment.press_confirmation(self, pos);return
	if scene == "village" and guide.button.has_point(pos) and V.shop == "" and not market_open and not settings_open:
		guide.opened = true;menu_open = false;holding = false;return
	if scene == "village" and mailbox.button.has_point(pos) and V.shop == "" and not market_open and not settings_open:
		mailbox.opened = true;menu_open = false;holding = false;return
	if not V.commerce.pending.is_empty(): V.commerce.press(V, self, pos);return
	if inventory.selected >= 0: inventory.detail_press(pos);return
	if scene == "spots": spots.press(self, pos);return
	if settings_open: _settings_press(pos);return
	if gear_rect.has_point(pos): settings_open = true;holding = false;return

	if not trans.is_empty(): return
	if market_open: _market_press(pos);return
	if V.shop != "": V._shop_press(self, pos);return
	if scene == "village": V.press(self, pos);return
	if market_open: _market_press(pos);return
	if S.phase in ["idle", "result"] and _menu_press(pos): holding = false;return
	if lesson_open:
		if S.get("tut", false) and SKIP_RECT.has_point(pos): skip_tut()
		else: close_card()
		return
	holding = true
	match S.phase:
		"idle", "result":
			if S.phase == "result" and S.get("ok", false):
				holding = false
				if ui_rects.get("keep", Rect2()).has_point(pos): keep_fish()
				elif ui_rects.get("rel", Rect2()).has_point(pos): release_fish()
				return
			if bag_shoulder():
				holding = false;show_tip("", "어깨에 멘 물고기가 있어요. 마을에 가서 팔아요!");return
			start_cast()
		"wait":
			if clock >= S.biteAt and clock <= S.realUntil: start_hook()
			else: holding = false;fail("너무 일찍 챘어요. 물고기가 도망갔어요" if clock < S.biteAt else "")
		"hook":
			hook_tap()
		"catch":
			holding = false
			if S.t > S.netEnd + 2.6: show_result(true)
		"fight":
			if S.landUntil > 0 and clock <= S.landUntil and not S.jumpUsed:
				S.jumpUsed = true;S.dist = min(100.0, S.dist + 12);show_toast("착수 챔질! +12");buzz([40, 30, 80]);play("land")


func _process(dt: float) -> void :
	dt = min(dt, 0.05)
	if not settings_open and not market_open: visibility_flash = maxf(0, visibility_flash - dt)
	shake_t = maxf(0.0, shake_t - dt)
	position = Vector2(ox, 0) + (Vector2(randi_range(-2, 2), randi_range(-1, 1)) if shake_t > 0 else Vector2.ZERO)
	ui_clock += dt
	sfx_update(dt)
	inventory.sync(self)
	if is_instance_valid(title_screen.root): title_screen.root.visible = title_open or title_screen.leaving
	if title_open:
		title_screen.update(self, dt);queue_redraw();return
	if title_screen.leaving: title_screen.update(self, dt)
	if not settings_open and not market_open and not title_open: environment.update(dt)
	tip_t = maxf(0.0, tip_t - dt)
	bag_disp = move_toward(bag_disp, bag_weight(), dt * maxf(0.5, bag_cap()) * 1.2)
	pond_stock = minf(pond_max(), pond_stock + pond_recovery() * dt / 3600.0)
	if scene != "village": aqua_acc += aqua_rate() / 60.0 * dt
	if aqua_acc >= 1.0: gold += int(aqua_acc);aqua_acc -= int(aqua_acc)
	if not trans.is_empty():
		trans.t += dt
		if not trans.done and trans.t >= TR_CLOSE + 0.1:
			trans.done = true;_switch_scene(trans.to)
		if trans.t >= TR_CLOSE + TR_HOLD + TR_OPEN: trans = {}
	if guide.opened or mailbox.opened or settings_open or market_open or not V.commerce.pending.is_empty() or not equipment.pending_sale.is_empty() or inventory.selected >= 0: queue_redraw();return
	if scene == "spots": spots.process(dt);queue_redraw();return
	if scene == "village":
		toast_t = max(0.0, toast_t - dt);judge_t = max(0.0, judge_t - dt)
		V.process(self, dt);queue_redraw();return
	if hitstop > 0:
		hitstop -= dt;judge_t = minf(1.0, judge_t);queue_redraw();return
	clock += dt;anim_t += dt;cat_t += dt;result_t += dt
	fclock += dt * time_scale()
	judge_t = max(0.0, judge_t - dt);toast_t = max(0.0, toast_t - dt)
	_vib_update(dt)
	match S.phase:
		"cast":
			S.t += dt
			if S.t > 1.45 and not S.get("landed", false):
				S.landed = true;play("plop");start_wait()
		"wait":
			while S.fakeI < S.fakes.size() and clock >= S.fakes[S.fakeI]:
				S.fakeI += 1
				ripples.append({"x": LX, "t0": clock, "w0": 3.0, "spd": 14.0 + 4 * S.size, "a": 0.45 + 0.1 * S.size, "dur": 0.7})
			if not S.biteBuzzed and clock >= S.biteAt:
				for i in 3: ripples.append({"x": LX + (18.0 if S.size == 3 else 0.0), "t0": clock + i * 0.12, "w0": 4.0, "spd": 22.0 + 6 * S.size, "a": 0.8, "dur": 1.0})
				for i in 6 + 3 * S.size:
					parts.append({"kind": "drop", "p": Vector2(LX + randf_range(-3, 3), WATER - 2), "v": Vector2(randf_range(-25, 25), randf_range(-70, -35) * (1 + 0.15 * S.size)), "life": 0.6, "max": 0.6, "col": Color(0.85, 0.95, 1.0), "ph": 0.0, "sz": 1})
				S.biteBuzzed = true;buzz([[40], [80], [150], [220, 60, 220]][S.size]);play("splash_s", -10.0 + 4.0 * S.size)
			if clock > S.realUntil: fail("미끼만 뜯겼어요. 쑥 잠길 때 바로 챔질!")
		"hook":
			if S.grade >= 2 and clock > S.pauseUntil and randf() < 0.006 * S.grade: S.pauseUntil = clock + 0.16
			if S.grade >= 3: S.zc = 0.5 + (0.18 if S.grade == 3 else 0.26) * sin(clock * (0.9 if S.grade == 3 else 1.5))
			if clock > S.pauseUntil:
				var sp: float = _hook_speed_at(S.pos, S.zc, S.barSp) * ((1 + 0.3 * sin(clock / 0.16)) if S.grade == 4 else 1.0)
				S.pos += S.dir * sp * dt
				if S.pos > 1 or S.pos < 0:
					S.pos = clampf(S.pos, 0, 1);S.dir = - S.dir
					S.barSp = minf(S.barSp * BAR_ACC[S.grade], 3.0)
			star_hist.push_front(S.pos)
			if star_hist.size() > 5: star_hist.pop_back()
		"pre":
			S.t += dt
			if S.t > 0.65: start_fight()
		"fight":
			update_fight(dt * time_scale())
			if S.phase == "fight": set_anim("reel" if holding else "idle")
		"catch":
			update_catch(dt)
		"fail":
			S.t += dt
			if S.t > 2.2: S = {"phase": "idle"};set_anim("idle");holding = false;msg = ""
	_fx_update(dt, clock * 1000.0)
	for f in ambient:
		f.x += f.v * dt
		if f.x < 110: f.v = abs(f.v)
		if f.x > 262: f.v = - abs(f.v)
	queue_redraw()


func _draw() -> void :
	var t: = clock * 1000.0
	var h: = get_viewport_rect().size.y
	text_items = []
	ui_commands = []
	aura = {}
	if is_instance_valid(title_screen.root): title_screen.root.visible = title_open or title_screen.leaving
	if title_open or title_screen.leaving:
		title_screen.draw_ui(self, h);_fx_draw(t);_draw_trans(h)
		if text_layer:
			text_layer.position.x = ox;text_layer.items = text_items;text_layer.commands = ui_commands;text_layer.queue_redraw()
		return
	if scene == "spots":
		spots.draw(self, h);_draw_overlays(t, h);return
	if scene == "village":
		V.draw(self, h)
		_draw_ui(t, h)
		_draw_overlays(t, h)
		return
	draw_set_transform(Vector2(0, oy))
	var n0: = text_items.size()

	draw_rect(Rect2(PX + 16, PY + 56, 26, 2), Color(0.1, 0.04, 0.05, 0.35))
	draw_rect(Rect2(PX + 18, PY + 58, 22, 1), Color(0.1, 0.04, 0.05, 0.2))
	draw_rect(Rect2(CATX + 3, CATY + 31, 24, 2), Color(0.1, 0.04, 0.05, 0.35))
	var cf: Array = anims["cat"]
	draw_texture(cf[int(cat_t / anim_speed["cat"]) % 16], Vector2(CATX, CATY + _cat_jump()))
	var fr: = anim_frame()
	# One logical pixel, alpha silhouette; original sprite remains untouched.
	for edge in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		draw_texture(anims[anim_name][fr], Vector2(PX, PY) + edge, Color(0.035, 0.045, 0.065, 0.9))
	draw_texture(anims[anim_name][fr], Vector2(PX, PY))
	_draw_reaction(t)
	var tip: = _rod_tip(fr)
	match S.phase:
		"cast": _draw_cast(t, tip)
		"wait", "hook", "pre": _draw_wait(t, tip)
		"fight": _draw_fight(fclock * 1000.0, tip)
		"catch":
			_draw_landing(t, tip)
		"fail", "result": pass
	if S.phase == "catch" and S.get("newRec", false) and anim_name == "trophy":
		_draw_trophy_fish(t, fr)
	draw_set_transform(Vector2.ZERO)
	for i in range(n0, text_items.size()): text_items[i][1] += Vector2(0, oy)
	_draw_ui(t, h)
	if lesson_open and lesson_after != "book": _draw_lesson_card(t)
	_draw_overlays(t, h)

func _draw_overlays(t: float, h: float) -> void :
	if market_open and scene == "village":

		text_items = text_items.filter( func(it): return it[1].y < top_y + 70)
	V.draw_shop(self, h)
	if market_open: _draw_market()
	if settings_open:
		_draw_settings()
		if lesson_open and lesson_after == "book": _draw_lesson_card(ui_clock * 1000.0)
	inventory.detail(self)
	V.commerce.draw(V, self, h)
	if mailbox.opened: mailbox.draw(self, h)
	if guide.opened: guide.draw(self, h)
	equipment.draw_confirmation(self, h)
	_fx_draw(t)
	_draw_trans(h)
	if text_layer:
		text_layer.position.x = ox
		text_layer.items = text_items
		text_layer.commands = ui_commands
		text_layer.queue_redraw()


const TR_CLOSE: = 0.45
const TR_HOLD: = 0.45
const TR_OPEN: = 0.5
const TR_TIPS: = ["수족관 물고기는 쉬는 동안에도 돈을 벌어요", "파츠를 달수록 귀한 물고기가 물어요", "손질하면 물고기의 혼을 얻어요", "미끼가 없으면 큰 물고기는 잘 안 물어요", "보관통이 차면 마을로!"]
func start_trans(to: String) -> void :
	if not trans.is_empty() or to == scene: return
	trans = {"t": 0.0, "to": to, "done": false, "tip": TR_TIPS[randi() % TR_TIPS.size()]}
	menu_open = false;holding = false;play("plop", -8.0)

func _switch_scene(to: String) -> void :
	title_screen.leaving = false
	if is_instance_valid(title_screen.root): title_screen.root.hide()
	V.visitors.hide_all(V.res + V.locals)
	if is_instance_valid(V.foreground): V.foreground.hide()
	scene = to;V.shop = "";market_open = false
	inventory.selected = -1;V.commerce.pending = {};parts.clear();aura = {};judge_t = 0;toast_t = 0;star_hist.clear()
	bg_node.visible = to == "fish"
	environment.show_scene(to == "fish")
	if to == "village":
		V.enter(self)
		if not forge_pending.is_empty(): V.enhancement.restore(self)
	elif to == "spots": spots.enter();S = {"phase": "idle"}
	else: S = {"phase": "idle"};set_anim("idle");msg = "마을에 가서 팔아요" if bag_shoulder() else "화면을 터치하면 던지기"
	_save_game()

func _draw_trans(h: float) -> void :
	if trans.is_empty(): return
	var t: float = trans.t
	var big: = Vector2(VW, h).length() * 0.6
	var r: = big
	if t < TR_CLOSE: r = big * pow(1.0 - t / TR_CLOSE, 2)
	elif t < TR_CLOSE + TR_HOLD: r = 0.0
	else: r = big * (1.0 - pow(1.0 - (t - TR_CLOSE - TR_HOLD) / TR_OPEN, 3))
	var c: = Vector2(VW / 2.0, h * 0.45)
	if r < 1.0: _ui_rect(Rect2( - ox, 0, VW + 2 * ox, h), Color("10161e"))
	else: _ui_arc(c, (r + big * 1.6) / 2.0, 0, TAU, 72, Color("10161e"), big * 1.6 - r)
	var keep: = []
	for it in text_items:
		if (it[1] - c).length() < r - 6: keep.append(it)
	text_items = keep
	if r < 30.0:
		var b: = absf(sin(ui_clock * 7.0)) * 6.0
		_ui_texture(tex_bobber, (c + Vector2( - tex_bobber.get_width() / 2.0, -14 - b)).round())
		_ui_rect(Rect2(c.x - 14, c.y + 6, 28, 2), Color(0.5, 0.8, 0.9, 0.5))
		var go: = "마을로 가는 중…" if trans.to == "village" else "낚시터로 가는 중…"
		_text(go, Vector2(c.x, c.y + 32), 14, Color("fff3d6"), true, 220)
		_text(trans.tip, Vector2(c.x, c.y + 52), 9, Color("c9d6dd"), true, 240)

func _rod_tip(fr: int) -> Vector2:
	var arr: Array = tips.get(anim_name, [])
	if fr < arr.size() and arr[fr] != null:
		return Vector2(PX + arr[fr][0], PY + arr[fr][1])
	return Vector2(PX + 54, PY + 13)

func _draw_ambience(t: float) -> void :

	var a: = 0.12 + 0.05 * sin(t / 900.0)
	for k in 5:
		var cx: = 40.0 + k * 52
		var d: = (uw_bot - WATER) * 0.95
		var sway: = 6.0 * sin(t / 2200.0 + k)
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 7, WATER), Vector2(cx + 7, WATER), Vector2(cx + 40 + k * 8 + sway, WATER + d), Vector2(cx + 18 + k * 8 + sway, WATER + d)]), Color(0.8, 0.95, 1.0, a))
	var g: = 0.25 + 0.12 * sin(t / 300.0) + 0.05 * sin(t / 71.0)
	draw_circle(Vector2(44, 198), 12, Color(1.0, 0.75, 0.35, g * 0.35))
	draw_circle(Vector2(44, 198), 6, Color(1.0, 0.85, 0.5, g * 0.6))
	for i in 6:
		if sin(t / 500.0 + i * 1.7) > 0.2:
			var fx: = 90.0 + i * 30 + 8 * sin(t / 1000.0 + i)
			var fy: = 185.0 + 10 * sin(t / 700.0 + i * 2)
			draw_rect(Rect2(int(fx), int(fy), 1, 1), Color(1, 0.98, 0.6))

func _line(a: Vector2, b: Vector2, col: Color, sag: = 0.0) -> void :
	var pts: = PackedVector2Array()
	for i in 13:
		var u: = i / 12.0
		var p: = a.lerp(b, u)
		p.y += sag * 4 * u * (1 - u)
		pts.append(p)
	if ui_demo:
		for i in range(1, pts.size()): _ui_line(pts[i - 1], pts[i], col, 1.0)
	else: draw_polyline(pts, col, 1.0)

func _draw_bobber(x: float, y: float) -> void :

	var sz: = tex_bobber.get_size()
	var p: = Vector2(round(x - sz.x / 2), round(y - sz.y + 3))
	var above: = clampf(float(WATER) - p.y, 0.0, sz.y)
	if above > 0: draw_texture_rect_region(tex_bobber, Rect2(p, Vector2(sz.x, above)), Rect2(0, 0, sz.x, above))
	if above < sz.y:
		draw_texture_rect_region(tex_bobber, Rect2(p + Vector2(0, above), Vector2(sz.x, sz.y - above)), Rect2(0, above, sz.x, sz.y - above), Color(0.28, 0.4, 0.55, 0.8))

func _ripple(x: float, w: float, a: float) -> void :
	var pts: = PackedVector2Array()
	for i in 17:
		var ang: = PI + i / 16.0 * PI
		pts.append(Vector2(x + cos(ang) * w, WATER - 1 + sin(ang) * w * 0.18))
	draw_polyline(pts, Color(1, 1, 1, a), 1.0)

func _draw_cast(t: float, tip: Vector2) -> void :
	var k: float = (S.t - 0.75) / 0.6
	if k <= 0: return
	k = min(1.0, k)
	var p: = tip.lerp(Vector2(LX, WATER), k)
	p.y -= sin(k * PI) * 40
	_line(tip, p, Color(1, 1, 1, 0.75))
	_draw_bobber(p.x, p.y)
	if k >= 1: _ripple(LX, 8, 0.6)

func _draw_wait(t: float, tip: Vector2) -> void :
	var lx: = float(LX)
	var dip: = sin(t / 400.0) * 0.6
	var z: int = S.size
	if S.phase == "wait":
		for f in S.fakes:
			if clock >= f and clock < f + 0.22 + 0.12 * z:
				if z == 3: lx += sin((clock - f) * 1000.0 / 60.0) * 2
				else: dip = [1.3, 2.0, 3.0][z] + sin(t / [22.0, 30.0, 45.0][z])
		if clock >= S.biteAt and clock <= S.realUntil:
			var e: float = min(1.0, (clock - S.biteAt) * 1000.0 / [80.0, 120.0, 300.0, 260.0][z])
			dip = [5.0, 7.0, 10.0, 9.0][z] * e + (sin(t / 20.0) if z == 0 else 0.0)
			if z == 3:
				lx += 18 * e
				for i in 2: _ripple(lx, 10 + i * 8 + 6 * e, 0.5 - i * 0.2)
	else:
		dip = [5.0, 7.0, 10.0, 9.0][z]
	_line(tip, Vector2(lx, WATER + dip - 6), Color(1, 1, 1, 0.75))
	_draw_bite_shadow(t, lx, dip)
	_draw_bobber(lx, WATER + dip)
	if dip > 1.5: _ripple(lx, 6 + dip, 0.5)
	for rp in ripples:
		var age: float = clock - rp.t0
		if age >= 0 and age < rp.dur:
			_ripple(rp.x, rp.w0 + age * rp.spd, rp.a * (1.0 - age / rp.dur))
	if S.phase == "hook": _draw_hookbar()



func _bite_circle(tt: float) -> Array:
	var z: int = S.size
	var k: = clampf((tt - (S.biteAt - 2.5)) / 2.5, 0.0, 1.0)
	var a: = tt * 1000.0 / (700.0 + 250 * z)
	var r: = 30.0 - 16 * k
	return [Vector2(LX + cos(a) * r, WATER + 22 + sin(a) * 6 - 8 * k), -1.0 if sin(a) > 0 else 1.0, k]


func _fish_display_length(star: int, scale: float, preview: bool) -> float:
	return maxf(20.0 if preview else 30.0, (16.0 + star * 4.0) * scale)

func _draw_bite_shadow(t: float, lx: float, dip: float) -> void :
	var z: int = S.size
	var scale: float = [0.55, 0.8, 1.15, 1.6][z]
	var L: float = _fish_display_length(S.star, scale, true)
	var biting: bool = S.phase != "wait" or clock >= S.biteAt
	if not biting:
		var c: Array = _bite_circle(clock)
		if c[2] <= 0: return
		var p: Vector2 = c[0]
		var face: float = c[1]
		for f in S.fakes:
			var w: float = 0.34 + 0.12 * z
			if clock >= f - 0.12 and clock < f - 0.12 + w:
				var b: = sin(PI * (clock - (f - 0.12)) / w)
				face = 1.0 if p.x < lx else -1.0
				var bite_c: = Vector2(lx - 0.45 * L * face, WATER + dip + 6)
				p = p.lerp(bite_c, b)
		_shadow_fish(p, S.star, 0, t, "swim", false, scale, {}, t / 1000.0 * TAU * 1.2, S.sp, face, 0.42 + 0.4 * c[2])
		return

	var c0: Array = _bite_circle(S.biteAt)
	var face2: float = 1.0 if (c0[0] as Vector2).x < lx else -1.0
	var mouth: = Vector2(lx, WATER + dip + 1)
	var hold: = mouth - Vector2(0.45 * L * face2, 0)
	var e: = 1.0 if S.phase != "wait" else clampf((clock - S.biteAt) / 0.12, 0.0, 1.0)
	var p2: Vector2 = (c0[0] as Vector2).lerp(hold, e)
	var tilt: = -1.1 * e
	var shake: = Vector2(sin(t / 35.0), cos(t / 50.0)) * (1.0 + 0.5 * z) if e >= 1.0 else Vector2.ZERO
	var pose: = {"freq": 3.0, "amp": 0.08, "curl": 0.0, "tilt": tilt, "stretch": 1.0, "tailAmp": 1.4}
	_shadow_fish(p2 + shake, S.star, 0, t, "swim", false, scale, pose, t / 1000.0 * TAU * 3.0, S.sp, face2, 0.8)

func _draw_hookbar() -> void :
	var x0: = 25.0
	var w: = 220.0
	var y: = WATER + 84.0
	draw_style_box(sb_meter, Rect2(x0, y - 7, w, 14))
	var ix: = x0 + 12.0
	var iw: = w - 24.0
	var zc: float = S.get("zc", 0.5)
	var gw: float = BAR_GREAT[S.grade]
	var pw: float = BAR_PERF[S.grade]
	sb_fill.modulate_color = Color("8fd36a") * Color(1.7, 1.7, 1.7, 1)
	draw_style_box(sb_fill, Rect2(int(ix + iw * (zc - gw)), y - 4, int(iw * gw * 2), 8))
	sb_fill.modulate_color = Color("eb82df") * Color(1.4, 1.4, 1.4, 1)
	var pr: = Rect2(int(ix + iw * (zc - pw)), y - 4, maxi(4, int(iw * pw * 2)), 8)
	draw_style_box(sb_fill, pr)
	draw_rect(Rect2(roundf(ix + iw * zc), y - 5, 1, 10), Color("fff4fb"))
	var sh: = int(fmod(clock * 40.0, pr.size.x + 12)) - 6
	if sh >= 0 and sh < pr.size.x: draw_rect(Rect2(pr.position.x + sh, y - 3, 1, 6), Color(1, 1, 1, 0.8))
	sb_fill.modulate_color = Color.WHITE

	for k in range(star_hist.size() - 1, 0, -1):
		draw_texture_rect(tex_star, Rect2(int(ix + iw * star_hist[k]) - 7, int(y) - 7, 14, 14), false, Color(1, 0.9, 0.5, 0.08 * (5 - k)))
	draw_texture_rect(tex_star, Rect2(int(ix + iw * S.pos) - 7, int(y) - 7, 14, 14), false)


func _ease(r: float, dtd: float) -> float: return 1.0 - exp( - r * dtd)

func pose_for(beh: String, star: int, fz: float) -> Dictionary:
	var p: = {"freq": 1.0, "amp": 0.08, "curl": 0.0, "tilt": 0.0, "stretch": 1.0, "tailAmp": 1.0}
	match beh:
		"tell", "turn": p.merge({"freq": 5.0, "amp": 0.03, "curl": -0.55, "tailAmp": 0.5}, true)
		"run", "charge": p.merge({"freq": 4.2, "amp": 0.11 * (1 + 0.3 * fz), "stretch": 1.25, "tailAmp": 1.8}, true)
		"rest": p.merge({"freq": 0.3, "amp": 0.02, "curl": 0.4, "tailAmp": 0.3}, true)
		"jump": p.merge({"freq": 1.8 + 1.5 * fz, "amp": 0.1, "tilt": -0.5}, true)
		"rise": p.merge({"freq": 3.4, "amp": 0.1, "tilt": -0.55, "tailAmp": 1.5}, true)
		"nose": p.merge({"freq": 3.0, "amp": 0.06, "tilt": 0.55, "curl": 0.15, "tailAmp": 1.3}, true)
		"dive": p.merge({"freq": 4.4, "amp": 0.1, "tilt": 0.75, "stretch": 1.15, "tailAmp": 1.7}, true)
		"sulk": p.merge({"freq": 0.6, "amp": 0.04, "tilt": 0.15, "tailAmp": 0.6}, true)
		"circle": p.merge({"freq": 3.2, "amp": 0.09, "curl": 0.25, "tailAmp": 1.3}, true)
		"thrash": p.merge({"freq": 7.0, "amp": 0.16, "curl": 0.0, "tailAmp": 2.0}, true)
		"skim": p.merge({"freq": 5.0, "amp": 0.12, "stretch": 1.2, "tailAmp": 1.9}, true)
	if beh != "rest": p.freq *= (1 + 0.4 * fz) * (1 - 0.25 * star / 4.0)
	return p

var _last_draw_t: = -1.0
func _draw_fight(t: float, tip: Vector2) -> void :
	var dtd: float = 0.0 if _last_draw_t < 0 else clampf((t - _last_draw_t) / 1000.0, 0.0, 0.05)
	_last_draw_t = t
	var run: bool = S.beh == "run"
	var wig: = sin(t / (60.0 if run else 180.0)) * (6.0 if run else 3.0)
	var F: float = S.F
	var tx: float = 190.0 - S.dist * 1.0 + wig
	var ty: float = WATER + (125.0 - S.dist * 1.05) * 1.3
	var near: = smoothstep(70.0, 100.0, S.dist)
	tx = lerpf(tx, 108.0, near);ty = lerpf(ty, WATER + 14.0, near)
	S.fx += (tx - S.fx) * (0.08 + 0.1 * near);S.fy += (ty - S.fy) * (0.08 + 0.1 * near)
	if run:
		var heavy: float = S.star / 4.0
		var A: float = (18 + 45 * F + 15 * heavy) * S.pRange * 1.5


		if S.dartUntil == 0.0 or t > S.dartUntil:
			S.dartDir = -1 if S.dartDir > 0 else 1
			S.dartUntil = t + randf_range(350, 750) * (1 - 0.45 * F) * (1 + 0.35 * heavy) * S.pTurn
			S.dartSp = (1.5 + 2.4 * F) * (1 - 0.25 * heavy) * S.pSpeed * randf_range(0.85, 1.15) * 1.5
			S.dartStart = t;S.glide = (220.0 - 150.0 * F) * (1 + 0.4 * heavy)
		var since: float = t - S.get("dartStart", t)
		var glide: float = S.get("glide", 0.0)
		var tv: = 0.0
		if since >= glide:
			var acc_ms: = (520.0 - 330.0 * F) * (1 + 0.3 * heavy)
			var ramp: = smoothstep(0.0, acc_ms, since - glide)
			var beat: = maxf(0.0, sin((since - glide) / (70.0 - 30.0 * F)))
			tv = S.dartDir * S.dartSp * ramp * (0.8 + 0.35 * beat)
		var rate: = (3.0 + 5.0 * F) if absf(tv) > absf(S.dartV) else (1.6 + 2.4 * F)
		S.dartV += (tv - S.dartV) * _ease(rate, dtd)
		S.turnK = 1.0 - clampf(since / maxf(glide, 1.0), 0.0, 1.0) if glide > 0 else 0.0
		S.dartX = clamp(S.dartX + S.dartV * dtd * 60, - A, A)
	else:
		S.dartV += ( - S.dartX * 0.05 - S.dartV) * _ease(2.5, dtd)
		S.dartX += S.dartV * dtd * 60;S.dartUntil = 0.0;S.turnK = 0.0
	S.dartX = clamp(S.dartX, 33 - S.fx, 252 - S.fx)
	S.chargeX = max(-100.0, S.chargeX - 2.4) if S.beh == "charge" else S.chargeX * 0.95
	var fx: float = clamp(S.fx + S.dartX + S.chargeX, 33, 252)
	var cl: bool = S.beh == "clone"
	var spread: float = min(1.0, S.cloneT / 0.3) if cl else 0.0
	var CX: = [-45.0, 0.0, 45.0]
	var CY: = [-36.0, 0.0, 36.0]
	if cl: fx = clamp(fx, 95, 175) + CX[S.cloneReal] * spread
	var fy: float = S.fy + (CY[S.cloneReal] * spread if cl else 0.0)
	if S.beh == "rise":
		var k: float = min(1.0, 1 - S.bt / 0.6)
		fy = fy + (WATER + 16 - fy) * k * k
		_ripple(S.fx + S.dartX, 4 + 14 * k, 0.25 + 0.5 * k)
		for i in 4: draw_rect(Rect2(int(S.fx + S.dartX - 6 + i * 4), int(fy - 10 - fmod(t / 30 + i * 7, 16)), 2, 2), Color(0.8, 0.92, 1, 0.8))
	S.diveOff += ((27 + 42 * F if S.beh == "dive" else (6.0 if S.beh == "nose" else (60.0 if S.beh == "sulk" else 0.0))) - S.diveOff) * _ease(3 + 4 * F if S.beh == "dive" else 2.5, dtd)
	S.diveDX += (((S.diveDir) * (15 + 22 * F) if S.beh == "dive" else 0.0) - S.diveDX) * _ease(2.5 + 3 * F, dtd)
	fx = clamp(fx + S.diveDX, 33, 252);fy = min(uw_bot - 10, fy + S.diveOff)
	if S.beh == "jump": fy = WATER - sin(min(1.0, S.jumpT / 0.9) * PI) * (24 + 15 * S.star / 4.0 + 36 * F)
	if S.beh == "circle":
		var R: = 30.0 + 30.0 * F
		fx = clamp(fx + cos(S.circA) * R, 33, 252);fy += sin(S.circA) * R * 0.45
	if S.beh == "skim":
		S.dartX = clamp(S.dartX + S.skimDir * (2.2 + 2.0 * F) * dtd * 60, 33 - S.fx, 252 - S.fx)
		fx = clamp(S.fx + S.dartX, 33, 252);fy = WATER + 12
		if parts.size() < 90 and randf() < 0.7: parts.append({"kind": "drop", "p": Vector2(fx - S.skimDir * 10, WATER - 1), "v": Vector2( - S.skimDir * randf_range(10, 40), randf_range(-60, -25)), "life": 0.5, "max": 0.5, "col": Color(0.9, 0.97, 1.0), "ph": 0.0, "sz": 1})
		_ripple(fx - S.skimDir * 6, 8, 0.5)
	if run: fy -= sin(S.get("turnK", 0.0) * PI) * (5.0 - 2.0 * F)
	if near > 0 and S.beh != "jump":
		fx = lerpf(fx, S.fx, near);fy = lerpf(fy, S.fy, near)
	if S.beh == "jump" or S.dispY < 0: S.dispY = fy
	else: S.dispY += (fy - S.dispY) * _ease(6 + 6 * F, dtd)
	fy = S.dispY
	var tens: float = min(1.0, S.tension / 100.0)
	var sag: = 60.0 if (S.beh == "charge" and not holding) else 0.0
	var line_col: = Color(1, 1 - tens * 0.67, 1 - tens * 0.78)

	if S.has("mouth"): _line(tip, S.mouth, line_col, sag)
	var dx: = fx
	var dy: = fy
	if S.beh == "tell": dx += sin(t / 25.0) * 1.5
	if S.beh == "thrash": dx += sin(t / 28.0) * 2.5;dy += cos(t / 37.0) * 1.5
	if S.spike > 0: dx += sin(t / 12.0) * 3;dy += cos(t / 15.0) * 2
	var scale: float = _fight_fish_scale(S.lf)
	if cl:
		for k in 3:
			if k != S.cloneReal:
				_shadow_fish(Vector2(dx + (CX[k] - CX[S.cloneReal]) * spread, dy + (CY[k] - CY[S.cloneReal]) * spread + sin(t / 300.0 + k) * 3), 
					S.star, S.grade, t + k * 137, "rest" if S.cloneSub == "run" else "run", false, scale, {}, t / 1000.0 * TAU * 2, S.sp, 1.0, 1.0)
	var face: float = float(S.dartDir) if run else (float(S.diveDir) if S.beh == "dive" else (-1.0 if S.beh in ["turn", "charge"] else 1.0))
	if S.beh == "circle": face = -1.0 if sin(S.circA) > 0 else 1.0
	if S.beh == "skim": face = float(S.skimDir)

	face = - face
	S.faceS += (face - S.faceS) * _ease(7 + 12 * F, dtd)
	var fs: float = -1.0 if S.faceS < 0 else 1.0
	var tgt: = pose_for(S.cloneSub if cl else S.beh, S.star, F)
	if run:
		var spd: = clampf(absf(S.dartV) / maxf(S.dartSp, 0.1), 0.0, 1.0)
		tgt.freq *= 0.55 + 0.6 * spd;tgt.stretch = 1.0 + 0.25 * spd;tgt.tailAmp *= 0.7 + 0.5 * spd
		tgt.curl += 0.5 * S.get("turnK", 0.0)
	if S.pose.is_empty(): S.pose = tgt.duplicate()
	var bl: = _ease(4 + 10 * F, dtd)
	for key in tgt: S.pose[key] += (tgt[key] - S.pose[key]) * bl
	S.swimPh += dtd * TAU * S.pose.freq
	var shake: = Vector2.ZERO
	if S.spike > 0 and S.grade >= 3: shake = Vector2(randi_range(-1, 1) * (S.grade - 2), randi_range(-1, 1))
	_shadow_fish(Vector2(dx, dy) + shake, S.star, S.grade, t, S.cloneSub if cl else S.beh, S.spike > 0, scale, S.pose, S.swimPh, S.sp, fs, 1.0)
	S.mouth = fish_mouth
	if not S.has("mouthOk"): S.mouthOk = true;_line(tip, fish_mouth, line_col, sag)
	S.lastF = {"p": Vector2(dx, dy) + shake, "scale": scale, "face": fs, "pose": S.pose.duplicate(), "phase": S.swimPh}
	_draw_fish_tension(Vector2(dx, dy), scale, dtd)
	if S.beh == "jump": _ripple(S.fx, 14, 0.6)
	if S.landUntil > 0 and clock <= S.landUntil and not S.jumpUsed:
		var k2: float = 1 - (S.landUntil - clock) / 0.4
		_ripple(S.fx, 12 + 20 * k2, 0.9 - 0.6 * k2)
		for i in range(-2, 3): draw_rect(Rect2(int(S.fx + i * 7), int(WATER - 4 - (4 - abs(i)) * 4 * (1 - k2)), 2, 2), Color.WHITE)


func _shadow_fish(c: Vector2, star: int, grade: int, t: float, beh: String, spike: bool, scale: float, pose: Dictionary, phase: float, sp: int, face: float, alpha: float) -> void :
	var revealed: bool = alpha >= 1.0 or (S.phase == "pre" and S.get("judge", "MISS") != "MISS")
	var L: = _fish_display_length(star, scale, alpha < 1.0)
	var N: = 12
	var fz: float = grade / 4.0
	var p: = pose if not pose.is_empty() else pose_for(beh, star, fz)
	if ui_demo:
		p = p.duplicate()
		if beh == "tell": p.curl=-0.28;p.amp=0.015
		if beh == "thrash": p.curl=sin(t / 1000.0 * 9.0)*0.95;p.amp=0.04
		if beh == "nose": p.tilt=0.9
	var amp: float = p.amp
	var curl: float = p.curl
	var tilt: float = p.tilt
	var stretch: float = 1.0 if revealed else p.stretch
	if revealed and not ui_demo:
		amp *= 0.55;curl *= 0.2
	var tailAmp: float = p.tailAmp
	if beh == "tell" or beh == "turn": curl += sin(t / 30.0) * 0.05
	if beh == "rest": tilt += sin(t / 700.0) * 0.08
	if beh == "jump" and grade >= 3: tilt += sin(t / 70.0) * 0.5 * (grade - 2)
	if spike: tilt += sin(t / 18.0) * (0.2 + 0.35 * fz)
	var hx: = c.x + L * 0.45
	var hy: = c.y
	var ct: = cos(tilt)
	var st: = sin(tilt)
	var pts: = []
	for i in N + 1:
		var u: = float(i) / N
		var ax: = - u * L * stretch
		var lat: = amp * L * sin(phase - u * 4.2) * pow(u, 1.4) * tailAmp + curl * L * (4 * (u - 0.5) * (u - 0.5) - 1) * 0.3
		var q: = Vector2(hx + ax * ct - lat * st, hy + ax * st + lat * ct)
		q.x = c.x + (q.x - c.x) * face
		pts.append(q)
	var tex: Texture2D = fish_sil[sp]
	var used: Rect2i = fish_used[sp]
	var tsz: = tex.get_size()
	var hw: = maxf(2.5 if alpha < 1.0 else 3.5, L * stretch * used.size.y / float(used.size.x) * 0.5)
	var nrms: = []
	for i in N + 1:
		var d: Vector2 = pts[min(i + 1, N)] - pts[max(i - 1, 0)]
		var nn: = d.normalized().orthogonal()
		nrms.append( - nn if face < 0 else nn)
	var quads: = []
	for i in N:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var na: Vector2 = nrms[i]
		var nb: Vector2 = nrms[i + 1]
		var u0: = (used.end.x - used.size.x * float(i) / N) / tsz.x
		var u1: = (used.end.x - used.size.x * float(i + 1) / N) / tsz.x
		var v0: = used.position.y / tsz.y
		var v1: = used.end.y / tsz.y
		quads.append([PackedVector2Array([a - na * hw, b - nb * hw, b + nb * hw, a + na * hw]), 
			PackedVector2Array([Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)])])
	if alpha >= 1.0: fish_mouth = (pts[0] as Vector2).lerp(pts[1], 0.35)
	if alpha >= 1.0 and not ui_demo:
		aura = {"quads": quads, "pts": pts, "L": L, "g": grade, "tex": tex, "face": face, "c": pts[5], "nrms": nrms, "hw": hw}

	if alpha >= 1.0:
		_draw_pixel_halo(quads, tex, grade, t)
		_draw_action_wake(c, L, hw, face, beh, t)
	if revealed:
		var flash: float = visibility_flash / 0.9
		if flash > 0: _fish_effect_circle(c, maxf(16, L), Color(0.3, 0.85, 0.9, flash * 0.02))
	else:

		for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			for qd in quads:
				var pp: = PackedVector2Array()
				for q in qd[0]: pp.append(q + d)
				_fish_quad([pp, qd[1]], Color(0.78, 0.88, 0.96, clampf(alpha, 0.6, 0.88)), tex)
	var col: = Color(1, 1, 1, alpha) if revealed else Color(0.025, 0.055, 0.09, maxf(0.86, alpha))
	var body: Texture2D = fish_tex[sp] if revealed else tex
	for qd in quads: _fish_quad(qd, col, body)
	if alpha >= 1.0 and (beh == "run" or beh == "charge"):
		var tp: Vector2 = pts[N]
		for i in 4: _fish_effect_rect(Rect2(int(tp.x - face * (6 + i * 6 + fmod(t / 20.0, 6))), int(tp.y - 6 + i * 4), 5, 1), Color(0.86, 0.94, 1, 0.55))
	if alpha >= 1.0 and beh == "rest":
		for i in 3: _fish_effect_rect(Rect2(int(hx + 2 + i * 2), int(hy - 6 - fmod(t / 40.0 + i * 9, 22)), 2, 2), Color(0.75, 0.9, 1, 0.7))


func _fish_quad(qd: Array, color: Color, tex: Texture2D) -> void :
	for ids in [[0, 1, 2], [0, 2, 3]]:
		var pp: = PackedVector2Array([qd[0][ids[0]], qd[0][ids[1]], qd[0][ids[2]]])
		if absf((pp[1] - pp[0]).cross(pp[2] - pp[0])) < 0.001: continue
		var uv: = PackedVector2Array([qd[1][ids[0]], qd[1][ids[1]], qd[1][ids[2]]])
		if ui_demo: _ui_polygon(pp, PackedColorArray([color, color, color]), uv, tex)
		else: draw_polygon(pp, PackedColorArray([color, color, color]), uv, tex)

# Offset the animated alpha silhouette: each layer follows fins and tail, not an ellipse.
# Body is drawn last; no colored overlay obscures the fish.
func _draw_pixel_halo(quads: Array, tex: Texture2D, grade: int, t: float) -> void:
	if grade <= 0: return
	for layer in range(3, 0, -1):
		var pulse: float = fposmod(t / 1500.0, 1.0)
		var radius: float = roundf(1.0 + (layer - 1 + pulse) * (1.0 + grade * 0.45))
		var opacity: float = (0.22 if layer == 1 else 0.085 if layer == 2 else 0.025) * (1.0 - pulse * 0.35)
		for i in 8:
			var offset := Vector2(cos(i * TAU / 8), sin(i * TAU / 8)).round() * radius
			var color := _aura_col(grade, t, opacity, i)
			for qd in quads:
				var vertices := PackedVector2Array()
				for point in qd[0]: vertices.append(point + offset)
				_fish_quad([vertices, qd[1]], color, tex)

func _draw_action_wake(c: Vector2, length: float, hw: float, face: float, beh: String, t: float) -> void:
	var force: float = _water_force(beh)
	if beh == "rest" or beh == "sulk": return
	# Short broken arcs remain outside the silhouette, never a solid glowing disc.
	var arcs: int = 3 if force >= 2.0 else 2
	for j in arcs:
		var phase: float = fmod(t / (380.0 if force >= 2.0 else 700.0) + j / float(arcs), 1.0)
		var radius: float = 4.0 + phase * (9.0 + force * 3.0)
		var center: = c - Vector2(face * length * 0.46, 0)
		if beh in ["circle", "thrash", "turn"]: center = c
		for k in 9:
			var angle: float = (k / 8.0 - 0.5) * PI
			var point: = center + Vector2(-face * cos(angle) * radius, sin(angle) * (hw + radius * 0.65))
			if absf(point.x - c.x) < length * 0.55 and absf(point.y - c.y) < hw + 3: continue
			_fish_effect_rect(Rect2(point.round(), Vector2(2, 1)), Color(0.61, 0.89, 1.0, (1.0 - phase) * 0.38))

func _water_force(beh: String) -> float:
	return float({"rest": 0.25, "sulk": 0.35, "tell": 0.6, "rise": 0.8, "nose": 0.8, "turn": 1.1, "circle": 1.5, "dive": 2.0, "run": 2.2, "charge": 2.4, "thrash": 2.8, "skim": 2.0, "jump": 0.0}.get(beh, 0.7))

func _spawn_action_water(dt: float) -> void:
	var beh: String = S.get("cloneSub", "swim") if S.beh == "clone" else S.beh
	var force: float = _water_force(beh)
	water_spawn_acc = minf(3.0, water_spawn_acc + dt * (3.0 + force * 8.0))
	if force == 0.0: water_spawn_acc = 0.0;return
	while water_spawn_acc >= 1.0 and parts.size() < 90:
		water_spawn_acc -= 1.0
		var side: float = -1.0 if randf() < 0.5 else 1.0
		var tail: Vector2 = aura.pts[-1]
		var p: Vector2 = tail + Vector2(-aura.face * randf_range(2, 9), side * (aura.hw + randf_range(3, 7)))
		var velocity: = Vector2(-aura.face * force * randf_range(5, 12), -randf_range(9, 20))
		if beh in ["circle", "thrash", "turn"]:
			var angle: float = randf() * TAU
			p = aura.c + Vector2(cos(angle) * (aura.L * 0.65 + 4), sin(angle) * (aura.hw + 9))
			velocity = Vector2(cos(angle) * force * 8.0, sin(angle) * force * 5.0 - 12)
		if beh == "dive": velocity.y = -randf_range(26, 40)
		var life: float = randf_range(0.45, 0.85)
		parts.append({"kind": "bubble", "p": p, "v": velocity, "life": life, "max": life, "col": Color("b9eeff"), "ph": randf() * TAU, "sz": 3 if randf() < 0.45 else 1})


func _aura_col(g: int, t: float, a: float, k: = 0) -> Color:
	if g == 4: return Color.from_hsv(fmod(t * 0.25 + k * 45, 360) / 360.0, 0.65, 1.0, a)
	var cc: Color = GRADE_C[g];cc.a = a;return cc



func _exit_tree() -> void :
	title_screen.dispose()
	if environment.layer:
		environment.layer.environment = null
		environment.layer.game = null
	for water in environment.water_layers:
		water.environment = null;water.game = null
	for animated in environment.atmosphere_layers:
		animated.environment = null;animated.game = null
	if environment.light_layer:
		environment.light_layer.environment = null;environment.light_layer.game = null
	for r in fx_rid: RenderingServer.free_rid(r)

func _fx_init() -> void :
	fx_mat = CanvasItemMaterial.new()
	fx_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for i in 2:
		var r: = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(r, get_canvas_item())
		RenderingServer.canvas_item_set_material(r, fx_mat.get_rid())
		RenderingServer.canvas_item_set_default_texture_filter(r, RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST)
		fx_rid.append(r)
	RenderingServer.canvas_item_set_draw_behind_parent(fx_rid[0], true)

func _fx_px(rid: RID, x: float, y: float, w: int, h: int, col: Color) -> void :
	if S.phase == "fight" and S.has("tensionHud") and Rect2(S.tensionHud, Vector2(44, 8)).grow(4).intersects(Rect2(x, y, w, h)): return
	RenderingServer.canvas_item_add_rect(rid, Rect2(int(x), int(y), w, h), col)

func _fight_particle_visible(pt: Dictionary) -> bool:
	# Airborne splash droplets must remain visible; only underwater bubbles are clipped at the surface.
	if pt.kind != "drop" and pt.p.y < WATER: return false
	if pt.p.y + oy > get_viewport_rect().size.y - 100: return false
	if not aura.is_empty():
		var delta: Vector2 = pt.p - aura.c
		if pow(delta.x / (aura.L * 0.62 + 4), 2) + pow(delta.y / (aura.hw + 5), 2) < 1.0: return false
	return true

func _fx_draw(t: float) -> void :
	var back: RID = fx_rid[0]
	var front: RID = fx_rid[1]
	RenderingServer.canvas_item_clear(back)
	RenderingServer.canvas_item_clear(front)
	var fx_shift: = Transform2D(0.0, Vector2(0, oy if scene == "fish" else 0.0))
	RenderingServer.canvas_item_set_transform(front, fx_shift)
	RenderingServer.canvas_item_set_transform(back, fx_shift)
	if title_open or title_screen.leaving or market_open or settings_open or inventory.selected >= 0 or not V.commerce.pending.is_empty(): return

	if reveal_t > 0 and reveal_c != Vector2.INF and S.phase == "fight":
		var k: = 1.0 - reveal_t
		var r: = 6.0 + k * 46.0
		var col: = _aura_col(reveal_g, t, reveal_t * 0.9)
		var n: = 28
		for i in n:
			var a: = i * TAU / n
			_fx_px(front, reveal_c.x + cos(a) * r, reveal_c.y + sin(a) * r * 0.7, 2, 2, col)

	if S.phase == "result" and S.get("ok", false) and S.get("newRec", false) and result_rect.size.x > 0:
		var c: = result_rect.get_center()
		var ka: = minf(1.0, result_t / 0.4)
		for i in 12:
			var a: = t / 2600.0 + i * TAU / 12
			var w: = 0.09 + 0.03 * sin(t / 500.0 + i)
			var L: = 320.0
			var col: = _rec_col(t, i)
			col.a = 0.4 * ka
			var tip: = Color(col, 0.07 * ka)
			var pts: = PackedVector2Array([c, c + Vector2(cos(a - w), sin(a - w)) * L, c + Vector2(cos(a + w), sin(a + w)) * L])
			RenderingServer.canvas_item_add_polygon(back, pts, PackedColorArray([col, tip, tip]))
	for pt in parts:
		# Fight particles are visible over scenery, excluded from the fish body and HUD.
		var pr: RID = front if S.phase == "fight" or pt.kind == "burst" or pt.kind == "drop" else back
		if S.phase == "fight" and not _fight_particle_visible(pt): continue
		var a: float = clampf(pt.life / pt.max, 0, 1)
		var col: Color = pt.col
		match pt.kind:
			"bubble":
				col.a = 0.75 * a
				if pt.sz >= 3:
					_fx_px(pr, pt.p.x, pt.p.y - 1, 2, 1, col);_fx_px(pr, pt.p.x, pt.p.y + 2, 2, 1, col)
					_fx_px(pr, pt.p.x - 1, pt.p.y, 1, 2, col);_fx_px(pr, pt.p.x + 2, pt.p.y, 1, 2, col)
				else: _fx_px(pr, pt.p.x, pt.p.y, 1, 1, col)
			"spark":
				col.a = a * (0.55 + 0.45 * sin(t / 60.0 + pt.ph))
				_fx_px(pr, pt.p.x, pt.p.y, 1, 1, col)
				if a > 0.4: _fx_px(pr, pt.p.x - 1, pt.p.y, 3, 1, col * Color(1, 1, 1, 0.6));_fx_px(pr, pt.p.x, pt.p.y - 1, 1, 3, col * Color(1, 1, 1, 0.6))
			"ember":
				col = col.lerp(Color(1, 0.35, 0.1), 1 - a);col.a = a
				_fx_px(pr, pt.p.x, pt.p.y, 1 if a < 0.5 else 2, 1, col)
			"smoke":
				var base_a: = 0.16 * a * minf(1.0, (1.0 - a) * 6.0 + 0.3)
				var cpos: = Vector2(int(pt.p.x), int(pt.p.y))
				for ring in [[1.0, 1.0], [0.7, 1.3], [0.4, 1.6]]:
					col.a = base_a * ring[1]
					RenderingServer.canvas_item_add_circle(pr, cpos, maxf(1.0, int(pt.sz * ring[0])), col)
			"drop":
				if pt.p.y < WATER: _fx_px(front, pt.p.x, pt.p.y, 1, 1 if pt.v.y > 0 else 2, Color(col, 0.9 * a))
			"burst":
				col.a = a
				_fx_px(pr, pt.p.x, pt.p.y, 2 if a > 0.5 else 1, 2 if a > 0.5 else 1, col)


func _rec_col(t: float, k: int) -> Color:
	var g: int = S.get("grade", 0)
	if g == 4: return Color.from_hsv(fmod(t / 4000.0 + k * 0.13, 1.0), 0.6, 1.0)
	var base: Color = Color("ffc94a") if g == 0 else GRADE_C[g]
	var h: = base.h + 0.12 * sin(t / 600.0 + k * 1.3)
	return Color.from_hsv(fmod(h + 1.0, 1.0), clampf(base.s, 0.45, 0.8), 1.0)

func _fx_update(dt: float, t: float) -> void :
	reveal_t = maxf(0.0, reveal_t - dt * 1.4)
	for pt in parts:
		pt.life -= dt
		pt.p += pt.v * dt
		if pt.kind == "bubble": pt.p.x += sin(t / 150.0 + pt.ph) * 0.15
		if pt.kind == "burst": pt.v *= 0.9
		if pt.kind == "ember": pt.v.y -= 6 * dt
		if pt.kind == "drop": pt.v.y += 220 * dt
		if pt.kind == "smoke": pt.v *= 0.965;pt.sz += dt * 14.0
	parts = parts.filter( func(q): return q.life > 0)

	if S.phase == "result" and S.get("ok", false) and S.get("newRec", false) and result_rect.size.x > 0:
		spawn_acc += (110.0 if result_t < 0.6 else 36.0) * dt
		while spawn_acc >= 1.0:
			spawn_acc -= 1.0
			var r: = result_rect
			var side: = randi() % 4
			var p: = Vector2.ZERO
			var nv: = Vector2.ZERO
			match side:
				0: p = Vector2(randf_range(r.position.x, r.end.x), r.position.y);nv = Vector2(0, -1)
				1: p = Vector2(randf_range(r.position.x, r.end.x), r.end.y);nv = Vector2(0, 1)
				2: p = Vector2(r.position.x, randf_range(r.position.y, r.end.y));nv = Vector2(-1, 0)
				3: p = Vector2(r.end.x, randf_range(r.position.y, r.end.y));nv = Vector2(1, 0)
			var v: = (nv + Vector2(randf_range(-0.6, 0.6), randf_range(-0.6, 0.6))).normalized() * randf_range(18, 55) * (1.6 if result_t < 0.6 else 1.0)
			parts.append({"kind": "smoke", "p": p, "v": v, "life": 1.6, "max": 1.6, "col": _rec_col(t, randi() % 6), "ph": randf() * 9, "sz": 4.0})
			if randf() < 0.3:
				parts.append({"kind": "spark", "p": p + nv * 4, "v": v * 1.3, "life": 0.9, "max": 0.9, "col": Color(1, 1, 0.85), "ph": randf() * 9, "sz": 1})
	if aura.is_empty() or S.phase != "fight": return
	var g: int = aura.g
	var pts: Array = aura.pts
	if reveal_pending and g > 0:
		reveal_pending = false;reveal_c = aura.c;reveal_g = g
		for i in mini(10 + g * 5, maxi(0, 90 - parts.size())):
			var a: = randf() * TAU
			parts.append({"kind": "burst", "p": aura.c, "v": Vector2(cos(a), sin(a) * 0.7) * randf_range(40, 80), "life": 0.6, "max": 0.6, "col": _aura_col(g, t, 1, i), "ph": 0.0, "sz": 2})
	_spawn_action_water(dt)
	var rate: float = [0, 9, 13, 18, 23][g]
	var fast: bool = S.beh == "run" or S.beh == "charge" or S.beh == "jump"
	if fast: rate *= 1.6
	spawn_acc = minf(3.0, spawn_acc + rate * dt)
	while spawn_acc >= 1.0 and parts.size() < 90:
		spawn_acc -= 1.0
		var k: = randi() % pts.size()
		var nv: Vector2 = aura.nrms[k]
		var p: Vector2 = pts[k] + nv * (aura.hw + 7) * (1.0 if randf() < 0.5 else -1.0)
		if g == 1: p = pts[k] + Vector2(0, - absf(nv.y) * aura.hw - 2)
		var col: = _aura_col(g, t, 1, randi() % 8)
		match g:
			1: parts.append({"kind": "bubble", "p": p, "v": Vector2(randf_range(-2, 2), randf_range(-22, -12)), "life": 1.3, "max": 1.3, "col": col.lerp(Color.WHITE, 0.4), "ph": randf() * 9, "sz": 3 if randf() < 0.35 else 1})
			2: parts.append({"kind": "spark", "p": pts[pts.size() - 1] + Vector2(randf_range(-3, 3), randf_range(-4, 4)), "v": Vector2( - aura.face * randf_range(4, 12), randf_range(-6, 6)), "life": 0.9, "max": 0.9, "col": col.lerp(Color.WHITE, 0.3), "ph": randf() * 9, "sz": 1})
			3: parts.append({"kind": "ember", "p": p, "v": Vector2(randf_range(-6, 6) - (aura.face * 25 if fast else 0.0), randf_range(-30, -14)), "life": 0.9, "max": 0.9, "col": Color(1, 0.85, 0.4), "ph": 0.0, "sz": 1})
			4: parts.append({"kind": "spark", "p": p, "v": Vector2(randf_range(-8, 8), randf_range(-10, 4)), "life": 1.0, "max": 1.0, "col": col, "ph": randf() * 9, "sz": 1})



func _draw_fish_sprite(sp: int, pos: Vector2, k: = 1) -> int:
	var tex: Texture2D = [fish_tex, fish_tex, fish_s2, fish_s3][k][sp]
	var u: Rect2i = fish_used[sp]
	var src: = Rect2i(u.position / k, u.size / k)
	draw_texture_rect_region(tex, Rect2(int(pos.x), int(pos.y) - src.size.y / 2, src.size.x, src.size.y), Rect2(src))
	return src.size.x



func _react_level() -> int:
	if not (S.phase == "catch" or (S.phase == "result" and S.get("ok", false))): return 0
	if S.get("grade", 0) == 4: return 3
	if S.get("newRec", false) or tier_of(S.get("lf", 1.0)) >= 4: return 2
	return 1

func _cat_jump() -> float:
	if _react_level() < 2 or S.phase != "catch": return 0.0
	var T: float = S.t - S.netEnd + 0.7
	if T < 3.0 or T > 3.9: return 0.0
	return - roundf(absf(sin((T - 3.0) * PI / 0.45)) * 7.0)

func _draw_reaction(t: float) -> void :
	if S.phase == "result": return
	if S.phase == "catch" and S.t >= S.netEnd and not (S.newRec and S.t - S.netEnd + 0.7 > 4.4): return
	var lv: = _react_level()
	if lv == 0 or (S.phase == "catch" and S.t < S.netEnd - 0.6): return
	var hx: = PX + 44.0
	var hy: = PY - 4.0 + roundf(sin(t / 200.0) * 1.5)
	_outline_text("♪", Vector2(hx, hy), Color("fff3b0"), Color("2a1608"), 0.75)
	if lv >= 2:
		for i in 3:
			var ph: = fmod(t / 500.0 + i * 0.33, 1.0)
			var a: = sin(ph * PI)
			var sx: float = PX + [16.0, 52.0, 34.0][i]
			var sy: float = PY + [4.0, 8.0, -8.0][i]
			var col: = Color(1, 0.95, 0.6, a)
			var r: = 1 + int(a * 2.0)
			draw_rect(Rect2(int(sx) - r, int(sy), r * 2 + 1, 1), col)
			draw_rect(Rect2(int(sx), int(sy) - r, 1, r * 2 + 1), col)
			draw_rect(Rect2(int(sx), int(sy), 1, 1), Color(1, 1, 1, a))
	if lv >= 3:
		var k: = minf(1.0, (S.t if S.phase == "catch" else 3.0) / 1.0)
		var cols: = [Color("ff5a5a"), Color("ffa04a"), Color("ffe25a"), Color("7ee07a"), Color("5ac8ff"), Color("6a7bff"), Color("b26aff")]
		for i in 7:
			draw_arc(Vector2(VW / 2.0, 250), 170.0 - i * 4, PI * 1.08, PI * 1.92, 48, Color(cols[i], 0.32 * k), 4.0)

func _fight_fish_scale(length_factor: float) -> float:
	return 2.2 * (0.8 + 0.4 * (length_factor - 0.75))

const SCOOP_T: = 1.15
func _draw_landing(t: float, tip: Vector2) -> void :
	if not S.has("lastF") or S.t >= SCOOP_T: return
	var lf: Dictionary = S.lastF
	var k: float = clampf(S.t / 0.35, 0.0, 1.0)
	var e: = 1.0 - pow(1.0 - k, 3)
	var dst: = Vector2(104, WATER + 9)
	var p: Vector2 = (lf.p as Vector2).lerp(dst, e)
	if k >= 1.0: p += Vector2(sin(t / 40.0) * 2, cos(t / 55.0))
	_shadow_fish(p, S.star, S.grade, t, "run" if k >= 1.0 else "swim", false, lf.scale, lf.get("pose", {}), float(lf.get("phase", 0.0)) + S.t * TAU * 1.2, S.sp, float(lf.get("face", -1.0)), 1.0)
	_line(tip, fish_mouth, Color(1, 1, 1, 0.8), 0.0)
	if k >= 1.0:
		_ripple(p.x, 8 + 4 * sin(t / 90.0), 0.6)
		if randf() < 0.4: parts.append({"kind": "drop", "p": Vector2(p.x + randf_range(-8, 8), WATER - 1), "v": Vector2(randf_range(-20, 20), randf_range(-50, -25)), "life": 0.4, "max": 0.4, "col": Color(0.9, 0.97, 1.0), "ph": 0.0, "sz": 1})

# Current playable reservoir. Locked future grounds have no invented limits.
const RESERVOIR_MAX_CM := 150.0
func species_max_cm(sp: int) -> float:
	return minf(RESERVOIR_MAX_CM, FISH_LEN[clampi(sp, 0, FISH_LEN.size()-1)] * 1.65)
func measurement_max_cm(sp: int) -> float:
	for cap in [10.0, 20.0, 30.0, 50.0, 100.0, 150.0]:
		if species_max_cm(sp) <= cap: return cap
	return RESERVOIR_MAX_CM
func measurement_width(sp: int) -> float:
	var used: Rect2 = Rect2(fish_used[sp])
	return minf(200.0, 130.0 * used.size.x / used.size.y)
func measurement_tick(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else "%.1f" % value
func measurement_x(length_cm: float) -> float:
	return 35.0 + measurement_width(int(S.get("sp", 0))) * clampf(length_cm / measurement_max_cm(int(S.get("sp", 0))), 0, 1)
func _hook_speed_at(pos: float, center: float, base: float) -> float:
	return base * (1.0 + 0.55 * pow(clampf(1 - absf(pos - center) / 0.32, 0, 1), 2))
func _draw_catch(t: float) -> void :
	if S.t < S.netEnd: return
	var elapsed: float = S.t - S.netEnd + 0.7
	if S.newRec and elapsed > 4.4: return
	var h: float = get_viewport_rect().size.y
	var r: = Rect2(15, maxf(100, roundf(h * 0.46) - 150), 240, 300)
	_ui_style_box(sb_panel, r)
	var success_banner := Rect2(r.position.x, r.end.y + 7, r.size.x, 24)
	_ui_style_box(sb_chip, success_banner)
	_text("잡았다!", success_banner.get_center() + Vector2(0, 4), 12, Color("513b29"), true, 220)
	var header: = Rect2(r.position + Vector2(9, 8), Vector2(222, 29))
	_ui_style_box(hud_reference_style, header)
	_text(FISH_NAME[S.sp], header.get_center() + Vector2(0, 5), 14, Color("fff0d1"), true, 208)
	var progress: float = clampf((elapsed - 0.7) / 2.2, 0, 1)
	var yy: float = r.position.y + 185
	var measured: float = float(S.len) * progress
	var mx: float = measurement_x(measured)
	_ui_rect(Rect2(35, yy - 5, measurement_width(S.sp), 18), Color("e6d5b2"))

	var used: Rect2 = Rect2(fish_used[int(S.sp)])
	var fw: float = measurement_x(float(S.len)) - 35
	var fh: float = fw * used.size.y / used.size.x
	_ui_texture_rect_region(fish_tex[int(S.sp)], Rect2(35, yy - 5 - fh, fw, fh), used)
	for i in 21:
		var xx: float = 35 + i * measurement_width(S.sp) / 20.0
		_ui_rect(Rect2(roundf(xx), yy, 1, 8 if i % 5 == 0 else 4), Color("765638"))
		if i % 5 == 0: _text(measurement_tick(measurement_max_cm(S.sp) * i / 20.0), Vector2(xx, yy + 22), 8, Color("765638"), true, 30)
	_ui_rect(Rect2(roundf(mx), yy - 8 - fh, 1, fh + 20), Color("b15336"))
	_text(("어종 눈금 0–%d cm" % int(measurement_max_cm(S.sp))) + (" · 이전 기록 초과" if S.len > measurement_max_cm(S.sp) else ""), Vector2(135, yy + 38), 9, Color("7c6448"), true, 216)
	_text("%.1fcm · %s" % [measured, _wtxt(S.weight)], Vector2(135, r.position.y + 244), 14, Color("513b29"), true, 210)
	_text("★%d · %s · %s" % [S.star + 1, GRADE_N[S.grade], TIER_NAME[tier_of(S.lf)]], Vector2(135, r.position.y + 264), 11, Color("66553f"), true, 210)
	_text("새 기록!" if progress >= 1 and S.newRec else ("터치하면 결과 보기" if progress >= 1 else "물고기를 재고 있어요"), Vector2(135, r.end.y - 14), 10, Color("537455"), true, 210)


func _draw_trophy_fish(t: float, fr: int) -> void :

	if fr < 3: return
	var w2: int = fish_used[S.sp].size.x / 2
	_draw_fish_sprite(S.sp, Vector2(PX + 32 - w2 / 2, PY + 4 + roundf(sin(t / 120.0))), 2)
	_text("최대어! %s %.1fcm" % [FISH_NAME[S.sp], S.len], Vector2(VW / 2.0, 120), 14, Color("f2c14e"), true, VW - 16, true)
	for i in 12:
		var a: = t / 260.0 + i * 0.52
		var r: = 58.0 + 8 * sin(t / 140.0 + i)
		draw_rect(Rect2(int(PX + 32 + cos(a) * r), int(PY + 20 + sin(a) * r * 0.6), 2, 2), Color("f2c14e") if i % 3 else Color("fff8ec"))



func _font_idx(size: int) -> int:
	return 0 if size <= 10 else (1 if size <= 13 else (2 if size <= 15 else 3))

func _text_w(s: String, size: int) -> float:
	var i: = _font_idx(size)
	return fonts[i].get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_PX[i]).x * FONT_SC[i]

func _text(s: String, pos: Vector2, size: int, col: Color, center: = false, maxw: = 0.0, shadow: = false) -> void :
	var i: = _font_idx(size)
	var lim: = maxw if maxw > 0 else (VW - 8.0)
	while i > 0 and fonts[i].get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_PX[i]).x * FONT_SC[i] > lim:
		i -= 1
	var f: Font = fonts[i]
	var px: int = FONT_PX[i]
	var sc: float = FONT_SC[i]
	var al: = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	var x: = roundf(pos.x - lim / 2) if center else roundf(pos.x)
	var y: = roundf(pos.y)
	if shadow or col.get_luminance() > 0.55:
		var oc: = Color(0.12, 0.07, 0.04, col.a * 0.9)
		for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			text_items.append([f, Vector2(x, y) + d * 0.4, s, al, lim / sc, px, oc, sc])
	text_items.append([f, Vector2(x, y), s, al, lim / sc, px, col, sc])




func _judge_text(s: String, pos: Vector2, col: Color, pop: float = -1.0) -> void :
	if pop < 0:
		var y: float = clampf(pos.y, top_y + 88, get_viewport_rect().size.y - 130)
		_text(s, Vector2(pos.x, y), 20, col, true, 242, true)
	else:
		var body: String = _ui_wrap(s, 12, 210, 2)
		var height: float = 32.0 if body.split("\n").size() == 1 else 48.0
		var y: float = clampf(pos.y - 23, top_y + 73, get_viewport_rect().size.y - 135 - height)
		var card: = Rect2(14, y, 242, height)
		_ui_style_box(hud_reference_style, card)
		_text(body, card.position + Vector2(121, 20), 12, Color("fff0d1"), true, 214)


func _sb(n: String, l: int, t: int, r: int, b: int, tile: = false) -> StyleBoxTexture:
	var sb: = StyleBoxTexture.new()
	sb.texture = load("res://art/ui/%s.png" % n)
	sb.texture_margin_left = l;sb.texture_margin_top = t;sb.texture_margin_right = r;sb.texture_margin_bottom = b
	if tile:
		sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	return sb

func _chip_icon(x: float, y: float, ic: String, s: String, w: float) -> void :
	_ui_style_box(sb_chip, Rect2(x, y, w, 25))
	var t: Texture2D = icons[ic]
	_ui_texture(t, Vector2(x + 9, y + 7))
	_text(s, Vector2(x + 22, y + 16), 9, Color("382619"))


func _draw_slots(y: float) -> void :
	var names: = ["rod", "float", "hook", "line", "reel"]
	for i in 5:
		var x: = 32 + i * 42
		_ui_texture(e_slots.selected if i == 0 else e_slots.slot, Vector2(x, y))
		var t: Texture2D = V.rods[rod_lv] if i == 0 else icons[names[i]]
		var owned: bool = equipment.rod_equipped if i == 0 else region_shop.has_active(self, names[i])
		var regional := false
		if i>0:
			for key in equipment.active_parts:
				if region_shop.slot_key(key)==names[i] and region_shop.part_region(key)>0:
					t=region_shop.icon(self,region_shop.part_region(key),i-1);regional=true;break
		if regional: _ui_texture_rect(t,Rect2(x+3,y+3,30,30))
		else: _ui_texture(t, Vector2(x + 3, y + 3), Color.WHITE if owned else Color(0.55, 0.55, 0.55, 0.24))


func _chip(x: float, y: float, s: String) -> float:
	var w: = ceilf(_text_w(s, 9)) + 19
	_ui_style_box(sb_chip, Rect2(x, y, w, 25))
	_text(s, Vector2(x + 9, y + 16), 9, Color("382619"))
	return w

func _draw_ui(t: float, h: float) -> void :
	if title_open: _draw_title(t, h);return

	gear_rect = Rect2()
	var bx: = 8.0
	_ui_style_box(hud_reference_style, Rect2(bx, top_y, 254, 30))
	var ty: = top_y + 19
	var hc: = Color("fff0d1")
	var right: = bx + 230.0
	var ps: = str(pearl)
	right -= _text_w(ps, 14);_text(ps, Vector2(right, ty), 14, hc)
	right -= 13;_ui_texture(icons["pearl_s"], Vector2(right, ty - 9))
	var gs: = str(gold)
	right -= 6 + _text_w(gs, 14);_text(gs, Vector2(right, ty), 14, hc)
	right -= 14;_ui_texture(icons["coin_s"], Vector2(right, ty - 10))
	_text(environment.clock_label(), Vector2(bx + 10, ty), 10 if scene == "village" else 12, hc, false, 96 if scene == "village" else right - bx - 34)
	_draw_weight(top_y + tex_hud_bar.get_height() + 1)
	if scene == "village":
		V.draw_bottom(self, h)
		if V.shop == "" and not market_open and not settings_open:
			mailbox.draw_button(self);guide.draw_button(self)
		_draw_notes()
		return


	var y0: float = maxf(uw_bot + oy + 29.0, h - 108 - bot_pad)
	var slots_y: = y0 + 40
	_draw_slots(slots_y)
	if S.phase in ["idle", "result"] and not title_open: _draw_menu(y0)
	if S.phase == "fight":

		if msg != "":
			_ui_style_box(sb_chip, Rect2(8, y0 - 31, 254, 25))
			_text(msg, Vector2(VW / 2.0, y0 - 14), 9, Color("382619"), true, 238)
	elif S.phase == "idle" and not menu_open:
		var alpha := 0.5 - 0.5 * cos(ui_clock * TAU / 3.2)
		var prompt_y := clampf(oy + 150.0, top_y + 125.0, h * 0.41)
		_text("탭해서 캐스팅 하기", Vector2(135, prompt_y), 14, Color(1.0, 0.96, 0.83, alpha), true, 246, true)
	elif S.phase in ["wait", "hook", "pre"] and msg != "" and not menu_open:
		_text(msg, Vector2(135, top_y + 112), 11, Color("fff3d7"), true, 246, true)
	if S.phase == "catch": _draw_catch(t)
	if S.phase == "result":
		_draw_result(t)
	if S.phase == "fail": _draw_failure()
	_draw_notes()

func _draw_notes() -> void :

	if S.phase in ["fail", "result"]: return
	if tip_t > 0:
		var tip_y: = top_y + 164.0 if scene == "village" else (top_y + 150.0 if S.phase == "fight" else top_y + 74.0)
		var body: = _ui_wrap(tip_txt, 12, 218, 2)
		var lines: = body.split("\n").size()
		_ui_style_box(sb_chip, Rect2(12, tip_y, 246, 34 if lines == 1 else 50))
		_text(body, Vector2(135, tip_y + 21 if lines == 1 else tip_y + 19), 12, Color("513b29"), true, 218)
	if judge_t > 0 and not lesson_open:
		_judge_text(judge_txt, Vector2(VW / 2.0, WATER - 40 + oy), judge_col)
	if toast_t > 0 and not lesson_open and S.phase != "catch":
		_judge_text(toast_txt, Vector2(VW / 2.0, WATER - 62 + oy), Color(toast_col.r, toast_col.g, toast_col.b, min(1.0, toast_t * 2)), toast_t / 1.2)

func _tension_anchor(fish_pos: Vector2, scale: float) -> Vector2:
	var offset: = maxf(20.0, _fish_display_length(S.star, scale, false) * 0.66 + 9.0)
	return Vector2(clampf(fish_pos.x - 22.0, 4.0, VW - 48.0), maxf(top_y + 66.0 - oy, fish_pos.y - offset))

func _draw_fish_tension(fish_pos: Vector2, scale: float, dt: float) -> void :
	var target: = _tension_anchor(fish_pos, scale)
	var previous: Vector2 = S.get("tensionHud", target)
	var p: = previous.lerp(target, 1.0 - exp(-12.0 * dt)) if dt > 0 else target

	p.y = minf(p.y, target.y)
	p.x = clampf(p.x, 4, VW - 48)
	S.tensionHud = p
	p = p.round()
	var v: = clampf(S.tension / 100.0, 0, 1)
	var col: = Color("e65c48") if v > 0.85 else (Color("f2c14e") if v > 0.6 else Color("8ed274"))
	var r: = Rect2(p, Vector2(44, 8))
	draw_rect(r.grow(1), Color("101c1e"))
	draw_rect(r, Color("d9cca6"))
	draw_rect(Rect2(p + Vector2(1, 1), Vector2(42, 6)), Color("263c39"))
	var fill: = roundf(42 * v)
	if fill > 0:
		draw_rect(Rect2(p + Vector2(1, 1), Vector2(fill, 6)), col)
		draw_rect(Rect2(p + Vector2(1, 1), Vector2(fill, 1)), col.lightened(0.25))
	for threshold in [0.6, 0.85]:
		var x: = p.x + 1 + roundf(42 * threshold)
		draw_rect(Rect2(x, p.y + 5, 1, 2), Color("172724"))
	if v > 0.85:
		draw_rect(r.grow(1), Color(1, 0.28, 0.18, 0.65 + 0.3 * sin(anim_t * 9)), false, 1)
		draw_rect(Rect2(p.x + clampf(fill, 1, 42), p.y - 1, 1, 10), Color("fff0ce"))

func _draw_result(t: float) -> void :
	var h: = get_viewport_rect().size.y
	var cy: = roundf(h * 0.42)
	if not S.get("ok", false):
		_draw_failure()
		return

	var pop: = int(maxf(0.0, 1.0 - result_t / 0.18) * 10)
	result_rect = Rect2(15, cy - 92 + pop, 240, 186)
	var r: = result_rect
	_ui_style_box(sb_panel, r)
	_text(FISH_NAME[S.sp], Vector2(VW / 2.0, r.position.y + 32), 14, Color("382619"), true, 200)
	_ui_fish(S.sp, Rect2(r.position + Vector2(24, 44), Vector2(192, 43)))

	var gy: = r.position.y + 112
	var stars: = "★".repeat(S.star + 1)
	var gc: = _aura_col(S.grade, t, 1.0) if S.grade > 0 else Color("e8e2d0")
	if S.grade == 1: gc = Color("4fa3ff")
	_outline_text(stars + " " + GRADE_N[S.grade], Vector2(VW / 2.0, gy), gc, Color("3a2414"), 1.0)
	var wt: float = S.weight
	var wtxt: = ("%dg" % int(wt * 1000)) if wt < 1 else ("%.2fkg" % wt)
	var tr: = tier_of(S.lf)
	_outline_text(TIER_NAME[tr], Vector2(VW / 2.0, gy + 21), TIER_COL[tr], Color("1e120a"), 0.75)
	_text("%s · %s" % [S.persona, S.judge], Vector2(VW / 2.0, gy + 36), 10, Color("382619"), true, 206)
	_text("%.1fcm · %s" % [S.len, wtxt], Vector2(VW / 2.0, gy + 50), 10, Color("3d2414"), true, 206)

	var sh: bool = S.weight > bag_cap() - bag_weight()

	var wx: = roundf((VW - tex_hud_gauge.get_width()) / 2.0)
	var wy: = r.end.y + 4
	_ui_texture(tex_hud_gauge, Vector2(wx, wy))
	var r0: = bag_weight() / bag_cap()
	var r1: = (bag_weight() + float(S.weight)) / bag_cap()
	_gauge_fill(wx, wy, 0, r0, _wcol(r0))
	var blink: = 0.55 + 0.45 * sin(t / 140.0)
	_gauge_fill(wx, wy, r0, r1, (Color("e0503c") if sh else Color("b8f5a8")) * Color(1, 1, 1, blink))
	var by: = wy + 28
	ui_rects.keep = Rect2(15, by, 118, 32);ui_rects.rel = Rect2(137, by, 118, 32)
	_ui_style_box(sb_btn, ui_rects.keep);_ui_style_box(sb_btn, ui_rects.rel)
	_text("어깨에 메기" if sh else "보관통에 넣기", Vector2(74, by + 20), 11, Color("382619"), true)
	_text("놓아주기", Vector2(196, by + 20), 11, Color("382619"), true)
	if S.newRec:
		var bob: = int(sin(t / 120.0) * 1.5)
		_outline_text("최대어 갱신!", Vector2(VW / 2.0, r.position.y - 9 + bob), Color("ffe066"), Color("3a2414"), 1.0)


func _outline_text(s: String, pos: Vector2, col: Color, oc: Color, sc: float) -> void :
	var f: Font = fonts[3]
	var w: float = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x * sc
	var x: = roundf(pos.x - w / 2)
	var y: = roundf(pos.y)
	for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		text_items.append([f, Vector2(x, y) + d * 0.4, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, oc, sc])
	text_items.append([f, Vector2(x, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col, sc])



func bag_items() -> Array: return bag
func bag_cap() -> float: return BAG_CAP[bag_lv]
func bag_weight() -> float:
	var w: = 0.0
	for f in bag_items(): w += float(f.w)
	return w
func bag_shoulder() -> bool:
	for f in bag_items():
		if f.get("shoulder", false): return true
	return false

func fish_price(sp: int, star: int, grade: int, lf: float) -> int:
	var list: Array = BY_STAR[star]
	var b: Array = PRICE_BASE[star]
	var base: = lerpf(b[0], b[1], float(list.find(sp)) / maxf(1.0, list.size() - 1.0))
	return int(round(base * PRICE_GRADE[grade] * minf(lf * lf, 2.5) * (1.0 + 0.05 * forge_lv)))

func keep_fish() -> void :
	var sh: bool = S.weight > bag_cap() - bag_weight()
	bag.append({"sp": S.sp, "star": S.star, "grade": S.grade, "len": S.len, "w": S.weight, "price": fish_price(S.sp, S.star, S.grade, S.lf), "shoulder": sh})
	if sh: show_tip("shoulder", "너무 커서 어깨에 멨어요. 이제 마을로!")
	elif bag_cap() - bag_weight() < 0.1 * bag_cap(): show_tip("full", "보관통이 가득! 마을에 가서 팔거나 수족관에 넣어요")
	play("plop");_save_game();_after_choice()

func release_fish() -> void :
	play("splash_s", -6.0);_after_choice()

func _after_choice() -> void :
	S = {"phase": "idle"}
	msg = "마을에 가서 팔아요" if bag_shoulder() else "화면을 터치하면 던지기"

func sell_all() -> void :
	var g: = 0
	for f in bag_items(): g += int(f.price)
	if g == 0: return
	gold += g;bag.clear();_save_game()
	play("catch");buzz([40, 40, 80]);show_toast("+%d 비늘" % g, Color("ffd24a"))
	msg = "화면을 터치하면 던지기"

func show_tip(key: String, txt: String) -> void :
	if key != "":
		if key in tips_seen: return
		tips_seen.append(key);_save_game()
	tip_txt = txt;tip_t = 4.0

func _wtxt(w: float) -> String: return ("%dg" % int(w * 1000)) if w < 1 else ("%.1fkg" % w)


func _gauge_fill(x: float, y: float, a: float, b: float, col: Color) -> void :
	var x0: = x + 9 + roundf(82 * clampf(a, 0, 1))
	var x1: = x + 9 + roundf(82 * clampf(b, 0, 1))
	if x1 <= x0: return
	_ui_rect(Rect2(x0, y + 8, x1 - x0, 6), col)
	_ui_rect(Rect2(x0, y + 8, x1 - x0, 1), col.lightened(0.3))

func _wcol(r: float) -> Color: return Color("e0503c") if r >= 0.999 else (Color("f2c14e") if r > 0.8 else Color("7cc96a"))

func _draw_weight(y: float) -> void :
	var show_pond: bool = scene in ["fish", "village"]
	var gap: float = 3.0
	var w: float = 124.0 if show_pond else 155.0
	var x0: float = (VW - (w * (2 if show_pond else 1) + (gap if show_pond else 0))) * 0.5
	var cards: int = 2 if show_pond else 1
	for i in cards:
		var x: float = x0 + i * (w + gap)
		_ui_style_box(hud_reference_style, Rect2(x, y, w, 36))
		if i == 0:
			var ratio: float = clampf(bag_weight() / bag_cap(), 0.0, 1.0)
			_ui_texture(V.art.weight, Vector2(x + 1, y + 2))
			var label: String = "%s/%s" % [_wtxt(bag_weight()), _wtxt(bag_cap())]
			if bag_shoulder(): label = "어깨 보관"
			_text(label, Vector2(x + 79, y + 14), 8, Color("fff0d1"), true, 83)
			_ui_rect(Rect2(x + 36, y + 24, w - 42, 5), Color("27342f"))
			_ui_rect(Rect2(x + 37, y + 25, (w - 44) * ratio, 3), _wcol(ratio))
		else:
			_ui_texture(V.art.stock, Vector2(x + 1, y + 2))
			var max_stock: float = pond_max()
			var stock_ratio: float = clampf(pond_stock / max_stock, 0.0, 1.0)
			_text("%d/%d" % [roundi(pond_stock), roundi(max_stock)], Vector2(x + 79, y + 14), 8, Color("fff0d1"), true, 80)
			_ui_rect(Rect2(x + 36, y + 24, w - 42, 5), Color("27342f"))
			_ui_rect(Rect2(x + 37, y + 25, (w - 44) * stock_ratio, 3), Color("68c5d3") if stock_ratio > 0.25 else Color("e3a64d"))

func pond_max() -> float: return 80.0 + pond_cap_lv * 20.0
func pond_recovery() -> float: return 30.0 + pond_regen_lv * 10.0


const MENU: = [["village", "마을"], ["bag", "가방"], ["book", "도감"], ["gear", "설정"]]
func _draw_menu(y0: float) -> void :
	var mr: = Rect2(6, y0, 38, 38)
	_ui_texture(tex_menu, mr.position)

	ui_rects.menu = mr.grow(3)
	ui_rects.erase("m_items")
	if not menu_open: return
	var items: = []
	var panel: = Rect2(6, y0 - 94, 218, 72)
	_ui_style_box(hud_reference_style, panel)
	for i in MENU.size():
		var p: = Vector2(12 + i * 52, panel.position.y + 5)
		var k: = clampf((ui_clock - menu_t) / 0.12 - i * 0.4, 0, 1)
		if k <= 0: continue
		var py: = p.y + roundf((1 - k) * 8)
		var ic: Texture2D = icons["m_fishing" if i == 0 and scene == "village" else "m_" + MENU[i][0]]
		_ui_texture(ic, Vector2(p.x + 5, py))
		_text("낚시터" if i == 0 and scene == "village" else MENU[i][1], Vector2(p.x + 25, py + 52), 10, Color("fff0d1"), true, 50)
		items.append(Rect2(p.x, p.y, 50, 57))
	ui_rects.m_items = items

func _menu_press(pos: Vector2) -> bool:
	if ui_rects.get("menu", Rect2()).has_point(pos):
		menu_open = not menu_open;menu_t = ui_clock;play("plop", -12.0);return true
	if not menu_open: return false
	menu_open = false
	var items: Array = ui_rects.get("m_items", [])
	for i in items.size():
		if items[i].has_point(pos):
			match MENU[i][0]:
				"village": start_trans("village" if scene == "fish" else "spots")
				"bag": market_open = true;market_sell = false
				"book": V.open_shop(self, "museum")
				"gear": settings_open = true
			return true
	return true


func _draw_market() -> void :
	inventory.draw(self)

func _market_press(pos: Vector2) -> void :
	inventory.press(self, pos)


func _draw_title(_t: float, h: float) -> void :
	title_screen.draw_ui(self, h)

const SAVE_VER: = 1
func _save_game() -> void :
	var f: = FileAccess.open("user://save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"region_shop": region_shop.serialize(), "equipment": equipment.serialize(), "mail_read": mailbox.read_ids, "mail_deleted": mailbox.deleted_ids, "v": SAVE_VER, "gold": gold, "pearl": pearl, "bag": bag_items(), "bag_lv": bag_lv, "parts": parts_owned, "tips": tips_seen, 
		"town_zoom": V.zoom, "boat_lv": boat_lv, "town_lv": town_lv, "forge_lv": forge_lv, "rod_lv": rod_lv, "rod_owned": rod_owned, "rod_enh": rod_enh, "protection_tickets": protection_tickets, "forge_pending": forge_pending, "forge_seen": forge_seen, 
		"pond_cap_lv": pond_cap_lv, "pond_regen_lv": pond_regen_lv, "pond_stock": pond_stock, 
		"bait": bait, "souls": souls, "aqua_lv": aqua_lv, "aqua": aqua, "dex": DEX, "catch_counts": catch_counts, "catch_legacy": catch_legacy, "world_time": environment.day_seconds, "time": Time.get_unix_time_from_system()}))

func aqua_rate() -> float:
	var r: = 0.0
	for f in aqua:
		if f != null: r += float(f.price) / 300.0
	return r * V.multiplier(self)

func _load_game() -> void :
	if not FileAccess.file_exists("user://save.json"): return
	var d = JSON.parse_string(FileAccess.open("user://save.json", FileAccess.READ).get_as_text())
	if not d is Dictionary: return
	mailbox.read_ids = d.get("mail_read", []);mailbox.deleted_ids = d.get("mail_deleted", [])
	environment.day_seconds = maxf(0.0, float(d.get("world_time", 0.0)))
	gold = int(d.get("gold", 0));pearl = int(d.get("pearl", 0));bag_lv = int(d.get("bag_lv", 0))
	region_shop.restore(d.get("region_shop", {}))
	bag = d.get("bag", []);parts_owned = d.get("parts", []);tips_seen = d.get("tips", [])
	bait = int(d.get("bait", 0));souls = int(d.get("souls", 0))
	V.zoom = clampf(float(d.get("town_zoom", 1.0)), 0.65, 1.6)
	boat_lv = clampi(int(d.get("boat_lv", 0)), 0, 5);town_lv = clampi(int(d.get("town_lv", 0)), 0, 5)
	rod_lv = clampi(int(d.get("rod_lv", 0)), 0, 5)
	rod_owned = clampi(int(d.get("rod_owned", rod_lv)), rod_lv, 5)
	rod_enh = [0, 0, 0, 0, 0, 0]
	var levels: Array = d.get("rod_enh", [])
	for i in mini(levels.size(), 6): rod_enh[i] = clampi(int(levels[i]), 0, ROD_MAX[i])
	if levels.is_empty(): forge_lv = clampi(int(d.get("forge_lv", 0)), 0, ROD_MAX[rod_lv])
	protection_tickets = maxi(0, int(d.get("protection_tickets", 0)))
	forge_pending = d.get("forge_pending", {})
	forge_seen = bool(d.get("forge_seen", false))
	equipment.restore(self, d.get("equipment", {}))
	pond_cap_lv = clampi(int(d.get("pond_cap_lv", 0)), 0, 5);pond_regen_lv = clampi(int(d.get("pond_regen_lv", 0)), 0, 5)
	pond_stock = clampf(float(d.get("pond_stock", 80.0)), 0.0, pond_max())
	var dx: Dictionary = d.get("dex", {})
	for k in dx: DEX[k] = (dx[k] as Array).map( func(g): return int(g))
	var aq: Array = d.get("aqua", [null, null, null])
	aqua_lv = clampi(int(d.get("aqua_lv", 0)), 0, 4)
	while aqua_lv < 4 and AQUA_CAP[aqua_lv] < mini(aq.size(), 20): aqua_lv += 1
	aqua.resize(aqua_capacity())
	for i in aqua.size(): aqua[i] = aq[i] if i < aq.size() else null
	_load_catch_counts(d)
	var away: = clampf(Time.get_unix_time_from_system() - float(d.get("time", 0)), 0, 8 * 3600)
	pond_stock = minf(pond_max(), pond_stock + pond_recovery() * away / 3600.0)
	var earn: = int(aqua_rate() * away / 60.0)
	if earn > 0 and d.has("time"):
		gold += earn;tip_txt = "쉬는 동안 수족관에서 %d 비늘을 벌었어요!" % earn;tip_t = 5.0


func _load_rec() -> void :
	if FileAccess.file_exists("user://rec.json"):
		var f: = FileAccess.open("user://rec.json", FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary: REC = d

func _save_rec() -> void :
	var f: = FileAccess.open("user://rec.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(REC))


func _shot_mode() -> void :
	var args: = OS.get_cmdline_user_args()
	if "--scenery-before" in args: environment.scenery_softness = 0.0;environment.update(0)
	if "--hour" in args: environment.set_hour(float(args[args.find("--hour") + 1]))
	var out: = args[args.find("--shot") + 1]
	var state: = args[args.find("--shot") + 2] if args.size() > args.find("--shot") + 2 else "wait"
	title_open = state == "title"
	bg_node.visible = not title_open;environment.show_scene(not title_open)
	if state == "menu": menu_open = true;menu_t = -1.0
	if state.begins_with("village") or state.begins_with("shop_") or state.begins_with("trans"):
		gold = 1240;bait = 7;souls = 36;parts_owned = ["float"]
		bag = [{"sp": 1, "star": 0, "grade": 0, "len": 24.0, "w": 0.08, "price": 13, "shoulder": false}, {"sp": 9, "star": 1, "grade": 1, "len": 52.0, "w": 0.3, "price": 128, "shoulder": false}, {"sp": 14, "star": 2, "grade": 2, "len": 47.0, "w": 1.0, "price": 520, "shoulder": true}]
		aqua = [{"sp": 8, "star": 1, "grade": 1, "len": 63.0, "w": 0.3, "price": 160}, null, null]
		DEX = {"피라미": [0], "붕어": [0, 1], "잉어": [1], "메기": [0], "쏘가리": [2]}
		_switch_scene("village")
		if state.begins_with("shop_"): V.open_shop(self, state.substr(5).replace("_sell", "").replace("_clean", "").replace("_pick", ""))
		if state.ends_with("_clean"): V.tab = "clean"
		if state.ends_with("_pick"): V.pick_slot = 1
		if state == "trans": trans = {"t": 0.6, "to": "fish", "done": true, "tip": TR_TIPS[0]};set_process(false)
		if state == "trans2": trans = {"t": 0.2, "to": "fish", "done": false, "tip": TR_TIPS[0]};set_process(false)
		if state == "village_guide": guide.opened = true
		if state == "village_baitbuy": V.open_shop(self,"up");V.tab="bait";V.commerce.request(V,self,"bait:0:5")
		if state == "village_mail": mailbox.opened = true
		if state == "village_income":
			tip_txt = "쉬는 동안 수족관에서 12345 비늘을 벌었어요!";tip_t = 20.0
		if state == "village_tap":
			var o: Vector2 = V.map_origin(self, get_viewport_rect().size.y)
			o.y = V.map_y - 1
			for b in V.BUILD:
				V.shop = "";V.press(self, o + b[3]);print("TAP ", b[0], " -> ", V.shop)
			get_tree().quit();return
		if state == "village_logic":
			V._act(self, "part:1");V._act(self, "bag");V._act(self, "worm:10")
			V.pick_slot = 1;V._act(self, "put:0");V._act(self, "clean:0");V._act(self, "sellall")
			var nparts: = parts_owned.size()
			print("LOGIC gold=", gold, " parts=", parts_owned, " bag_lv=", bag_lv, " bait=", bait, " souls=", souls, " aqua1=", aqua[1] != null, " bag=", bag.size())
			_save_game();gold = 0;bait = 0;souls = 0;aqua = [null, null, null];parts_owned = [];DEX = {}
			_load_game()
			print("RELOAD gold=", gold, " parts=", parts_owned, " bait=", bait, " souls=", souls, " aqua=", aqua.map( func(f): return f != null), " dex=", DEX.size(), " n=", nparts)
			TUT.done = true
			var cnt: = [0, 0, 0, 0, 0]
			bait = 100000;parts_owned = []
			for i in 2000: start_wait();cnt[S.star] += 1
			print("STARS no-parts ", cnt)
			parts_owned = ["float", "hook", "line", "reel"];cnt = [0, 0, 0, 0, 0]
			for i in 2000: start_wait();cnt[S.star] += 1
			print("STARS full ", cnt)
			bait = 0;cnt = [0, 0, 0, 0, 0]
			for i in 2000: bait = 0;start_wait();cnt[S.star] += 1
			print("STARS bare ", cnt)
			get_tree().quit();return
		if state in ["village_shops", "village_forge", "village_aqua", "village_hall", "village_museum"]:
			V.camera_x = {"village_shops": 355.0, "village_forge": 650.0, "village_aqua": 890.0, "village_hall": 1150.0, "village_museum": 1360.0}[state]
			V.ferry_clock = 12;V.process(self, 0.1)
		if state == "village_talk": V.chief_say = V.CHIEF_TALK[0];V.chief_t = 0.0
	if state == "small_wait":
		TUT.done = true;start_wait();S.star = 0;S.size = 0;S.sp = 2;S.biteAt = clock + 0.7;S.realUntil = clock + 9;S.fakes = []
	if state == "normal_fight":
		TUT.done = true;start_wait();S.sp = 2;S.star = 0;S.grade = 0;S.lf = 0.8;S.size = 0;S.judge = "GREAT";S.len = 4.0;start_fight();S.dist = 35.0;S.faceS = -1.0;S.fx = 156.0;S.fy = WATER + 95;S.dispY = WATER + 95
	if "--env-time" in args: environment.elapsed = float(args[args.find("--env-time") + 1]);environment.update(0)
	if state == "market":
		market_sell = false
		bag = [{"sp": 1, "star": 0, "grade": 0, "len": 24.0, "w": 0.3, "price": 13, "shoulder": false}, {"sp": 9, "star": 1, "grade": 1, "len": 52.0, "w": 1.4, "price": 128, "shoulder": true}]
		market_open = true
	TUT = {"done": not state.begins_with("tut"), "seen": []}
	match state:
		"tut_demo":
			start_wait();start_hook();S.pos = 0.5;hook_tap();start_fight();S.dist = 30.0
		"tut_card":
			start_wait();start_hook();S.pos = 0.5;hook_tap();start_fight();S.dist = 30.0;S.tutState.i = 1;tut_begin_step();open_card("tell", "practice")
		"lesson_jump":
			start_wait();S.sp = 9;S.star = 1;S.grade = 2;S.lf = 1.1;S.size = 1;S.judge = "GREAT";S.len = 52.0;start_fight();S.dist = 35.0;open_card("jump", "")
		"license":
			start_wait();settings_open = true;set_view = "license"
		"settings":
			start_wait();settings_open = true
		"book":
			start_wait();settings_open = true;set_view = "book";TUT.seen = ["swim", "tell", "rest", "jump"]
		"book_card":
			start_wait();settings_open = true;set_view = "book";TUT.seen = ["swim", "tell", "rest", "jump"];open_card("jump", "book")
		"react1", "react2", "react3":
			start_wait();S.sp = 8;S.star = 1;S.grade = 4 if state == "react3" else 1;S.lf = 1.0;S.size = 1;S.judge = "GREAT";S.len = 50.0;start_fight();start_catch();hitstop = 0.0
			S.newRec = state != "react1";S.t = S.netEnd + 2.65;anim_name = "net";anim_t = 16 * 0.13
		"measure", "measure_crucian":
			start_wait();S.sp = 8;S.star = 1;S.grade = 1;S.lf = 1.1;S.size = 1;S.judge = "GREAT";S.len = 63.0;start_fight();start_catch();S.t = S.netEnd + 1.3
		"landing":
			start_wait();S.sp = 14;S.star = 2;S.grade = 2;S.lf = 1.1;S.size = 1;S.judge = "GREAT";S.len = 40.0;start_fight();S.dist = 95.0
			S.lastF = {"p": Vector2(200, 380), "scale": 2.2, "face": -1.0};start_catch();S.t = 0.5
		"near":
			start_wait();S.sp = 14;S.star = 2;S.grade = 2;S.lf = 1.1;S.size = 1;S.judge = "GREAT";S.len = 40.0;start_fight();S.dist = 96.0;holding = true
		"bite2":
			start_wait();S.star = 2;S.size = 2;S.sp = 15;S.biteAt = clock + 0.05;S.realUntil = clock + 9.0;S.fakes = []
		"nibble":
			start_wait();S.star = 2;S.size = 2;S.sp = 15;S.biteAt = clock + 2.0;S.realUntil = clock + 9.0;S.fakes = [clock + 0.08]
		"bite":
			start_wait();S.star = 2;S.size = 2;S.sp = 15;S.biteAt = clock + 0.02;S.realUntil = clock + 9.0;S.fakes = []
		"wait":
			start_wait();S.star = 2;S.size = 2;S.sp = 15;S.biteAt = clock + 1.0;S.realUntil = clock + 9.0
		"hook":
			start_wait();S.sp = 9;start_hook();S.pos = 0.4
		"perfect":
			start_wait();S.star = 2;S.grade = 3;S.sp = 15;start_hook();S.pos = 0.5;hook_tap();S.grade = 3
			await get_tree().process_frame
			hitstop = 0.0;judge_t = 0.6
		"beh_sulk", "beh_circle", "beh_thrash", "beh_skim", "beh_run", "beh_dive", "beh_swim":
			start_wait();S.sp = 14;S.star = 2;S.grade = 3;S.lf = 1.1;S.size = 1;S.judge = "GREAT";S.len = 40.0;start_fight();S.dist = 30.0
			TUT.seen = BOOK_KEYS.duplicate()
			S.beh = state.substr(4);S.bt = 99.0;S.circA = PI / 2;S.thT = 0.0;S.skimDir = -1;S.holdT = 0.0;S.dartDir = -1
		"fight1", "fight2", "fight3", "fight4":
			start_wait();S.sp = 14;S.star = 2;S.grade = int(state.right(1))
			S.lf = 1.1;S.size = 1;S.judge = "GREAT";S.len = 40.0;start_fight();S.dist = 35.0
			holding = true
		"fight", "fight_myth", "fight_run":
			start_wait();S.sp = 9 if state == "fight" else 19;S.star = 1 if state == "fight" else 4;S.grade = 2 if state == "fight" else 4
			S.lf = 1.1;S.size = 1;S.judge = "GREAT";S.len = 52.0;start_fight();S.dist = 35.0
			if state == "fight_run": S.beh = "run";S.bt = 5.0
			holding = true
		"catch":
			start_wait();S.sp = 8;S.star = 1;S.grade = 1;S.lf = 1.1;S.size = 1;S.judge = "GREAT";S.len = 63.0;start_fight();start_catch();S.t = S.netEnd + 2.4
		"fail":
			start_wait();S.sp = 9;S.star = 1;S.grade = 2;S.lf = 1.1;S.size = 1;S.judge = "GREAT";S.len = 52.0;start_fight();S.beh = "charge";fail("줄이 너무 오래 느슨해서 바늘이 빠졌어요")
		"result_rec", "result":
			start_wait();S.sp = 8;S.star = 1;S.grade = 1;S.lf = 1.1;S.size = 1;S.judge = "GREAT";S.len = 63.0;start_fight();start_catch();S.phase = "result";S.ok = true;S.newRec = true;S.persona = "성실";msg = "터치하면 다시 던지기";result_t = 0.0
	if "--danger" in args and S.phase == "fight": S.tension = 93.0;holding = false
	if "--town-zoom" in args: V.set_zoom(self, float(args[args.find("--town-zoom") + 1]))
	if state == "village_refresh_motion":
		set_process(false)
		V.camera_x = 200;V.ferry_clock = 6.9;V.arrived = false;V.res = [];V.town_time = 0
		for n in 144:
			ui_clock += 1.0 / 12;V.process(self, 1.0 / 12)
			V.set_zoom(self, lerpf(0.7, 1.45, clampf((n / 12.0 - 3.0) / 3.0, 0, 1)))
			V.camera_x = clampf(200 + (n / 12.0 - 4) * 15, 0, 700);V.clamp_camera(self)
			queue_redraw(); await get_tree().process_frame; await RenderingServer.frame_post_draw
			get_tree().root.get_texture().get_image().save_png(out.replace(".png", "_%03d.png" % n))
		get_tree().quit();return
	if state == "village_motion":
		set_process(false)
		V.camera_x = 0;V.ferry_clock = 0;V.arrived = false;V.res = [];V.town_time = 0
		for n in 384:
			var seconds: = n / 12.0
			ui_clock += 1.0 / 12;V.process(self, 1.0 / 12)
			V.camera_x = clampf((seconds - 8.0) * 46.0, 0, 1030.0)
			queue_redraw(); await get_tree().process_frame; await RenderingServer.frame_post_draw
			get_tree().root.get_texture().get_image().save_png(out.replace(".png", "_%03d.png" % n))
		get_tree().quit();return
	if state == "trace":
		Engine.time_scale = 1.0
		start_wait();S.sp = 14;S.star = 1;S.grade = int(OS.get_environment("G")) if OS.get_environment("G") != "" else 2;S.lf = 1.0;S.size = 1;S.judge = "GREAT";S.len = 40.0;start_fight();S.dist = 30.0
		S.beh = "run";S.bt = 99.0
		var xs: = []
		var tt: = 0.0
		while tt < 4.0:
			await get_tree().process_frame
			tt += get_process_delta_time()
			if xs.size() < int(tt / 0.05): xs.append(int(fish_mouth.x))
		print("TRACE ", xs)
		get_tree().quit();return
	if state == "auto":
		Engine.time_scale = 1.0
		start_wait();S.biteAt = clock + 0.5;S.realUntil = clock + 9.0;S.fakes = [];S.star = 0;S.grade = 0;S.sp = 1
		var n: = 0
		var last_cap: = -1.0
		while n < 200 and S.phase != "result":
			if S.phase == "wait" and clock > S.biteAt + 0.1: press()
			elif S.phase == "hook" and abs(S.pos - S.zc) < 0.03: press()
			elif S.phase == "fight":
				holding = S.tension < 70 and not (S.beh in ["run", "dive", "jump", "skim"])
				S.dist = minf(100.0, S.dist + 0.6)
			if clock - last_cap >= 0.25 and S.phase in ["fight", "catch", "pre"]:
				last_cap = clock
				await RenderingServer.frame_post_draw
				get_tree().root.get_texture().get_image().save_png(out.replace(".png", "_%03d.png" % n));n += 1
			await get_tree().process_frame
		get_tree().quit();return
	if state == "light_off": environment.light_layer.enabled = false
	if state in ["water_motion", "light_check", "living_motion"]:
		set_process(false)
		for n in (96 if state == "living_motion" else (72 if state == "light_check" else 48)):
			if state == "light_check":
				environment.light_layer.enabled = n >= 12
				tip_txt = "빛 레이어 OFF · 고정 줄기 없음" if n < 12 else "빛 레이어 ON · 줄기 자체가 움직임"
				tip_t = 1.0
			environment.elapsed = n / 12.0;anim_t = n / 12.0;cat_t = n / 12.0;environment.update(0);queue_redraw()
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_tree().root.get_texture().get_image().save_png(out.replace(".png", "_%03d.png" % n))
		get_tree().quit();return
	if state == "idle_prompt": S = {"phase": "idle"};msg = "";ui_clock = 1.6
	if state == "village_settings":
		_switch_scene("village");settings_open = true;set_view = "main"
	if state in ["bag_inventory", "bag_equipment", "gear_sales"]:
		bag = [];gold = 5000;bait = 18;rod_lv = 1;rod_owned = 2;bag_lv = 1
		parts_owned = ["float", "hook", "line", "reel"]
		equipment.restore(self, {})
		equipment.active_parts = ["float", "hook"]
		if state == "gear_sales": _switch_scene("village");V.open_shop(self, "up");V.tab = "gear_sell"
		else:
			market_open = true;market_sell = false;inventory.tab = "inventory" if state == "bag_inventory" else "equipment"
	if state == "village_lockedshop": V.open_shop(self,"up");region_shop.region=1
	if state == "village_museum": V.open_shop(self,"museum")
	if state == "measure_crucian": S.sp=1;S.len=25.9;S.weight=0.088;S.newRec=false;S.grade=0;S.t=S.netEnd+2.3;tip_t=0.0
	if state.begins_with("lesson_book_"):
		_switch_scene("village");S = {"phase": "idle"};settings_open = true;set_view = "book"
		open_card(state.trim_prefix("lesson_book_"), "book");lesson_clock = ui_clock - (4.4 if state == "lesson_book_jump" else 1.6)
	if state == "forge_clean":
		_switch_scene("village");V.open_shop(self, "forge");V.forge_tab = "upgrade"
		gold = 50000;souls = 500;V.enhancement.start(self, 0.0);V.enhancement.elapsed = 0.3
	Engine.time_scale = 1.0 if state == "result_rec" else 0.15
	if "--vfx-check" in args:
		Engine.time_scale = 1.0;TUT.done = true;tip_t = 0.0;toast_t = 0.0;judge_t = 0.0;reveal_pending = false;reveal_t = 0.0
		S.fx = 160.0;S.fy = WATER + 95.0;S.dispY = WATER + 95.0;S.bt = 99.0
	for i in (120 if "--vfx-check" in args else 40): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png(out)
	get_tree().quit()

const BG_SHADER: = "\nshader_type canvas_item;\nuniform float xoff = 0.0;\nuniform float uw = 447.0;\nuniform float oy = 0.0;\nvoid fragment() {\n\tvec2 uv = UV;\n\tfloat py = uv.y / TEXTURE_PIXEL_SIZE.y - oy;\n\tfloat px = uv.x / TEXTURE_PIXEL_SIZE.x;\n\tif (py >= 217.0 && py < 273.0 && px - xoff > 104.0) {\n\t\tuv.x += round(1.5 * sin(TIME * 2.6 + py * 0.35)) * TEXTURE_PIXEL_SIZE.x;\n\t} else if (py >= 274.0 && py < uw) {\n\t\tuv.x += round(1.0 * sin(TIME * 3.4 + py * 0.22)) * TEXTURE_PIXEL_SIZE.x;\n\t}\n\tCOLOR = texture(TEXTURE, uv);\n}\n"

func aqua_capacity() -> int: return AQUA_CAP[aqua_lv]
func aqua_count() -> int:
	var count: = 0
	for f in aqua:
		if f != null: count += 1
	return count
func aqua_expand() -> bool:
	if aqua_lv >= 4 or gold < AQUA_COST[aqua_lv]: return false
	gold -= AQUA_COST[aqua_lv]
	aqua_lv += 1
	aqua.resize(aqua_capacity())
	_save_game()
	return true
func _ui_texture(t: Texture2D, p: Vector2, c: Color = Color.WHITE) -> void :
	_ui_texture_rect(t, Rect2(p, t.get_size()), false, c)
func _ui_texture_rect(t: Texture2D, r: Rect2, tile: bool = false, c: Color = Color.WHITE, transpose: bool = false) -> void :
	if t.has_meta("master"):
		var master: Texture2D = t.get_meta("master")
		var region: Rect2 = t.get_meta("region")
		var sz: Vector2 = region.size * minf(r.size.x / region.size.x, r.size.y / region.size.y)
		ui_commands.append(["region", master, Rect2(r.get_center() - sz / 2, sz), region, c, transpose])
	else: ui_commands.append(["texture", t, r, tile, c, transpose])
func _ui_texture_rect_region(t: Texture2D, r: Rect2, region: Rect2, c: Color = Color.WHITE, transpose: bool = false, clip_uv: bool = true) -> void :
	ui_commands.append(["region", t, r, region, c, transpose])
func _ui_style_box(style: StyleBox, r: Rect2) -> void : ui_commands.append(["style", style.duplicate(), r])
func _ui_rect(r: Rect2, c: Color, filled: bool = true, width: float = -1.0, antialiased: bool = false) -> void : ui_commands.append(["rect", r, c, filled, width])
func _ui_circle(p: Vector2, r: float, c: Color, filled: bool = true, width: float = -1.0, antialiased: bool = false) -> void : ui_commands.append(["circle", p, r, c, filled, width])
func _ui_line(a: Vector2, b: Vector2, c: Color, width: float = -1.0, antialiased: bool = false) -> void : ui_commands.append(["line", a, b, c, width])
func _ui_polygon(points: PackedVector2Array, colors: PackedColorArray, uvs: PackedVector2Array = PackedVector2Array(), texture: Texture2D = null) -> void : ui_commands.append(["polygon", points, colors, uvs, texture])
func _ui_arc(p: Vector2, r: float, a: float, b: float, n: int, c: Color, w: float = -1.0, aa: bool = false) -> void : ui_commands.append(["arc", p, r, a, b, n, c, w])

func _ui_wrap(value: String, size: int, width: float, max_lines: int = 2) -> String:
	var lines: Array[String] = []
	for paragraph in value.split("\n"):
		var line: = ""
		for word in paragraph.split(" ", false):
			var trial: = word if line.is_empty() else line + " " + word
			if _text_w(trial, size) > width and not line.is_empty():
				lines.append(line);line = ""
			if _text_w(word, size) > width:
				for ch in word:
					if _text_w(line + ch, size) > width and not line.is_empty(): lines.append(line);line = ""
					line += ch
			else: line = word if line.is_empty() else line + " " + word
		if not line.is_empty(): lines.append(line)
	if lines.size() > max_lines:
		lines.resize(max_lines)
		var last: = lines[max_lines - 1]
		while _text_w(last + "..", size) > width and not last.is_empty(): last = last.left(-1)
		lines[max_lines - 1] = last + ".."
	return "\n".join(lines)

func _draw_failure() -> void :
	var first_command := ui_commands.size()
	var first_text := text_items.size()
	var cy: = roundf(get_viewport_rect().size.y * 0.42)
	result_rect = Rect2(20, cy - 62, 230, 128)
	_ui_style_box(sb_panel, result_rect)
	var header: = Rect2(result_rect.position + Vector2(9, 8), Vector2(212, 31))
	_ui_style_box(hud_reference_style, header)
	_ui_texture_rect(icons.hook, Rect2(header.position + Vector2(8, 3), Vector2(25, 25)))
	_text("놓쳤어!", header.position + Vector2(111, 22), 16, Color("f1c298"), true, 158)
	var reason: String = S.get("failText", "")
	if reason.is_empty(): reason = "물고기가 빠져나갔어요."
	_text(_ui_wrap(reason, 12, 200, 2), Vector2(135, result_rect.position.y + 60), 12, Color("513b29"), true, 200)
	_text("잠시 후 대기 상태로 돌아가요", Vector2(135, result_rect.end.y - 18), 10, Color("77644d"), true, 205)
	var age: float = float(S.get("t", 0.5))
	_fade_ui(first_command, first_text, minf(1.0, age / 0.15) * clampf((2.2 - age) / 0.5, 0.0, 1.0))

func _ui_fish(sp: int, box: Rect2) -> Rect2:
	var source: Rect2 = Rect2(fish_used[sp])
	var size: Vector2 = source.size * minf(box.size.x / source.size.x, box.size.y / source.size.y)
	var r: = Rect2(box.get_center() - size / 2, size)
	_ui_texture_rect_region(fish_tex[sp], r, source)
	return r

func _fish_effect_rect(r: Rect2, c: Color) -> void :
	if ui_demo: _ui_rect(r, c)
	else: draw_rect(r, c)
func _fish_effect_circle(p: Vector2, r: float, c: Color) -> void :
	if ui_demo: _ui_circle(p, r, c)
	else: draw_circle(p, r, c)

func _load_catch_counts(d: Dictionary) -> void :
	catch_counts = {};catch_legacy = {}
	if d.has("catch_counts"):
		for name in d.catch_counts:
			var src: Array = d.catch_counts[name]; var values: Array = [0, 0, 0, 0, 0]
			for g in mini(5, src.size()): values[g] = maxi(0, int(src[g]))
			catch_counts[name] = values
		for name in d.get("catch_legacy", {}): catch_legacy[name] = d.catch_legacy[name].map( func(g): return int(g))
		return
	for name in DEX:
		var values: Array = [0, 0, 0, 0, 0]
		for g in DEX[name]: values[int(g)] = 1
		catch_counts[name] = values;catch_legacy[name] = DEX[name].duplicate()
	var confirmed: Dictionary = {}
	for f in bag + aqua:
		if f == null: continue
		var name: String = FISH_NAME[int(f.sp)]
		if not confirmed.has(name): confirmed[name] = [0, 0, 0, 0, 0]
		confirmed[name][clampi(int(f.grade), 0, 4)] += 1
	for name in confirmed:
		var values: Array = catch_counts.get(name, [0, 0, 0, 0, 0])
		for g in 5: values[g] = maxi(values[g], confirmed[name][g])
		catch_counts[name] = values

const LESSON_EXTRA := {
 "swim": "물고기가 평범하게 헤엄칠 때 감으면 거리를 줄일 수 있어요.",
 "tell": "몸짓 전의 작은 변화를 보세요. 다음 움직임을 예고해요.",
 "rest": "쉬는 동안이 기회예요. 누르고 감아 거리를 줄여요.",
 "jump": "수면으로 오르면 손을 떼세요. 착수 순간의 탭을 노려요.",
 "spike": "느낌표 순간에 장력이 튀어요. 손을 떼 줄을 풀어 주세요.",
 "dive": "머리를 숙이면 잠수 예고예요. 장력이 높으면 즉시 풀어요.",
 "charge": "나를 향해 돌진하면 줄이 느슨해져요. 꾹 눌러 감아 주세요.",
 "clone": "여럿처럼 보여도 낚싯줄이 이어진 물고기가 진짜예요.",
 "sulk": "바닥에서 버티면 조급하게 감지 말고 장력을 살펴요.",
 "circle": "원을 도는 동안 장력이 오르내려요. 짧게 감고 풀어요.",
 "thrash": "몸을 세게 털 때는 손을 떼고, 멎은 뒤 다시 감아요.",
 "skim": "수면을 빠르게 가로지르면 장력부터 확인하고 대응해요."
}

func _fade_ui(first_command: int, first_text: int, alpha: float) -> void:
	for i in range(first_text, text_items.size()): text_items[i][6].a *= alpha
	for i in range(first_command, ui_commands.size()):
		var c: Array = ui_commands[i]
		match c[0]:
			"style":
				if c[1] is StyleBoxTexture: c[1].modulate_color.a *= alpha
			"texture": c[4].a *= alpha
			"region": c[4].a *= alpha
			"rect": c[2].a *= alpha
