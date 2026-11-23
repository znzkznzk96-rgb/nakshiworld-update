class_name PetHutUI
extends Control
# 펫 오두막 창: 기존 상점 틀(panel/header/teal/card)과 같은 구성. 탭 3개.
signal closed
const TABS := [["pets", "내 펫"], ["gacha", "뽑기"], ["plans", "도면"]]
const INK := Color("382619")
const CREAM := Color("fff0d1")
const A := "res://assets/"
var tab := "pets"
var rects := {}
var _tex := {}
var _font: FontFile

func _ready() -> void:
	_font = load(A + "neodgm.ttf")
	_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	_font.hinting = TextServer.HINTING_NONE
	_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	custom_minimum_size = Vector2(270, 420)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _t(n: String) -> Texture2D:
	if not _tex.has(n): _tex[n] = load(A + n + ".png")
	return _tex[n]

# 기존 shop_restyle.draw_art와 같은 9분할
func _art(name: String, r: Rect2) -> void:
	var tex: Texture2D = _t(name)
	var src := tex.get_size()
	var edge := 24.0
	var border := 9.0 if name == "panel" else 8.0
	var xs := [0.0, edge, src.x - edge, src.x]
	var ys := [0.0, edge, src.y - edge, src.y]
	var dx := [r.position.x, r.position.x + border, r.end.x - border, r.end.x]
	var dy := [r.position.y, r.position.y + border, r.end.y - border, r.end.y]
	for iy in 3:
		for ix in 3:
			var d := Rect2(dx[ix], dy[iy], dx[ix + 1] - dx[ix], dy[iy + 1] - dy[iy])
			if d.size.x <= 0 or d.size.y <= 0: continue
			draw_texture_rect_region(tex, d, Rect2(xs[ix], ys[iy], xs[ix + 1] - xs[ix], ys[iy + 1] - ys[iy]))

func _txt(s: String, pos: Vector2, size: int, col: Color, center := false, w := 232.0) -> void:
	var x := roundf(pos.x - w / 2.0) if center else roundf(pos.x)
	draw_string(_font, Vector2(x, roundf(pos.y)), s, HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT, w, size, col)

func panel_rect() -> Rect2:
	return Rect2(8, roundf((size.y - 380.0) / 2.0), 254, 380)

func _draw() -> void:
	rects = {}
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.1, 0.84))
	var r := panel_rect()
	_art("panel", r)
	var header := Rect2(r.position + Vector2(5, 5), Vector2(r.size.x - 10, 39))
	_art("header", header)
	draw_texture(_t("badge"), (header.position + Vector2(5, 6)).round())
	_txt("펫 오두막", Vector2(header.get_center().x, header.position.y + 23), 14, CREAM, true, header.size.x - 82)
	var cr := Rect2(header.end.x - 28, header.position.y + 7, 22, 23)
	_art("button", cr)
	_txt("X", cr.get_center() + Vector2(0, 4), 10, CREAM, true, 20)
	rects["close"] = cr.grow(3)
	_txt("펫이 진주를 캐고 있어요!", Vector2(135, r.position.y + 59), 9, INK, true, 232)
	for i in 3:
		var key: String = TABS[i][0]
		var tr := Rect2(r.position.x + 12 + i * 77, r.position.y + 69, 74, 24)
		_art("teal" if tab == key else "card", tr)
		_txt(TABS[i][1], tr.get_center() + Vector2(0, 4), 9, CREAM if tab == key else INK, true, 68)
		rects["tab:" + key] = tr
	var body := Rect2(r.position.x + 12, r.position.y + 105, r.size.x - 24, r.size.y - 117)
	_art("card", body)
	rects["body"] = body
	_txt({"pets": "내 펫", "gacha": "뽑기", "plans": "도면"}[tab] + " 화면", body.get_center() + Vector2(0, 4), 10, INK, true, body.size.x - 12)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		press(e.position)

func press(p: Vector2) -> void:
	if rects.get("close", Rect2()).has_point(p) or not panel_rect().has_point(p):
		closed.emit(); return
	for t in TABS:
		if rects.get("tab:" + t[0], Rect2()).has_point(p):
			tab = t[0]; queue_redraw(); return
