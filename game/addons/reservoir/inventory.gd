extends RefCounted
var tab := "fish"
var tab_rects := {}
var displayed: = false
var opened_at: = 0.0
var selected: = -1
var selected_grade := -1
var list_view = preload("res://addons/reservoir/bag_list.gd").new()
var rects: = {}
func sync(m) -> void :
	if m.market_open and not displayed: displayed = true;opened_at = m.ui_clock;selected = -1;selected_grade=-1;list_view.reset()
	elif not m.market_open: displayed = false
func open_species(sp: int) -> void : selected = sp;selected_grade=-1
func open_group(sp: int, grade: int) -> void:
	selected=sp;selected_grade=grade;list_view.detail_scroll=0
func counts(m, sp: int, where: String) -> Array:
	var result: Array = [0, 0, 0, 0, 0]
	var list: Array = m.bag if where == "bag" else m.aqua
	for f in list:
		if f != null and int(f.sp) == sp: result[clampi(int(f.grade), 0, 4)] += 1
	return result
func label(m, text: String, p: Vector2, width: float, size: int = 9) -> void :
	m._text(m._ui_wrap(text, size, width, 2), p, size, Color("513b29"), true, width)
func draw(m) -> void :
	sync(m)
	if not m.market_sell and tab=="fish": list_view.draw(m);return
	var h: float = m.get_viewport_rect().size.y
	m._ui_rect(Rect2( - m.ox, 0, m.VW + 2 * m.ox, h), Color(0.04, 0.06, 0.1, 0.78))
	var r: = Rect2(15, roundf(h * 0.5) - 185, 240, 370)
	m.text_items = m.text_items.filter( func(it): return it[1].y < r.position.y - 7)
	var k: float = clampf((m.ui_clock - opened_at) / 0.24, 0, 1)
	var ease: float = 1 - pow(1 - k, 3)
	var scale: = Vector2(lerpf(0.88, 1, ease), lerpf(0.06, 1, ease))
	var anchor: = r.get_center()
	var first: int = m.text_items.size()
	m.ui_commands.append(["transform", anchor - anchor * scale, scale])
	m._ui_style_box(m.sb_panel, r)
	preload("res://addons/reservoir/ui_theme.gd").title(m, r, "어시장" if m.market_sell else "가방")
	var close: = Rect2(r.end.x - 31, r.position.y + 9, 22, 23);m._ui_texture(m.icons.close, close.position)
	rects = {"panel": r, "close": close.grow(4), "cells": []}
	if not m.market_sell:
		tab_rects.clear()
		for i in 3:
			var key: String = ["fish", "inventory", "equipment"][i]
			var tr := Rect2(r.position + Vector2(11 + i * 73, 45), Vector2(70, 23))
			m._ui_style_box(m.sb_btn if tab == key else m.sb_chip, tr)
			m._text(["물고기", "인벤토리", "장비"][i], tr.get_center() + Vector2(0, 4), 10, Color("513b29"), true, 66)
			tab_rects[key] = tr
		if tab != "fish":
			m.equipment.draw_inventory(m, r, tab)
			_finish(m, first, anchor, scale, k)
			return
	var grid_offset := 26.0 if not m.market_sell else 0.0
	var items: Array = m.bag_items(); var pages: int = maxi(1, ceili(items.size() / 12.0))
	m.bag_page = clampi(m.bag_page, 0, pages - 1)
	m._text("물고기 %d마리" % items.size(), r.position + Vector2(13, 53 + grid_offset), 10, Color("513b29"))
	rects = {"panel": r, "close": close.grow(4), "cells": []}
	for i in 12:
		var cell: = Rect2(r.position + Vector2(12 + i % 4 * 55, 64 + grid_offset + floori(i / 4.0) * (62 if not m.market_sell else 72)), Vector2(51, 58 if not m.market_sell else 68))
		m._ui_style_box(m.sb_chip, cell)
		var idx: int = m.bag_page * 12 + i
		if idx >= items.size(): continue
		var f: Dictionary = items[idx]; var sp: int = int(f.sp)
		m._ui_fish(sp, Rect2(cell.position + Vector2(5, 5), Vector2(41, 22)))
		label(m, m.FISH_NAME[sp], Vector2(cell.get_center().x, cell.position.y + 40), 45, 9)
		m._text(m._wtxt(float(f.w)), Vector2(cell.get_center().x, cell.position.y + (51 if not m.market_sell else 61)), 8, Color("7c6448"), true, 45)
		var grade: int = int(f.get("grade", 0));m._ui_rect(Rect2(cell.position + Vector2(5, 29), Vector2(41, 1)), m.GRADE_C[grade])
		rects.cells.append([cell, sp])
	var py: float = r.position.y + 290
	var prev: = Rect2(76, py - 8, 24, 24); var next: = Rect2(170, py - 8, 24, 24)
	m._ui_style_box(m.sb_chip, prev);m._ui_style_box(m.sb_chip, next)
	m._text("<", prev.get_center() + Vector2(0, 4), 10, Color("513b29"), true, 20);m._text(">", next.get_center() + Vector2(0, 4), 10, Color("513b29"), true, 20)
	m._text("%d / %d" % [m.bag_page + 1, pages], Vector2(135, py + 9), 10, Color("513b29"), true, 60)
	m._text("%s / %s" % [m._wtxt(m.bag_weight()), m._wtxt(m.bag_cap())], Vector2(135, r.end.y - 42), 10, Color("513b29"), true, 210)
	var sell: = Rect2(40, r.end.y - 33, 190, 25)
	if m.market_sell:
		var total: = 0
		for f in items: total += int(f.price)
		m._ui_style_box(m.sb_btn, sell);m._text("모두 팔기 %d 비늘" % total, sell.get_center() + Vector2(0, 4), 10, Color("513b29"), true, 180)
	else: m._text("물고기를 누르면 등급별 수량을 볼 수 있어요", Vector2(135, r.end.y - 16), 9, Color("7c6448"), true, 218)
	rects.prev = prev.grow(3);rects.next = next.grow(3);rects.sell = sell if m.market_sell else Rect2()
	_finish(m, first, anchor, scale, k)

func press(m, p: Vector2) -> void :
	if not m.market_sell and tab=="fish": list_view.press(m,p);return
	if m.ui_clock - opened_at < 0.2: return
	if rects.get("close", Rect2()).has_point(p) or not rects.get("panel", Rect2()).has_point(p):
		m.market_open = false;displayed = false;return
	if not m.market_sell:
		for key in tab_rects:
			if tab_rects[key].has_point(p): tab = key;m.equipment.page = 0;return
		if tab != "fish": m.equipment.press_inventory(m, p);return
	for cell in rects.get("cells", []):
		if cell[0].has_point(p): open_species(cell[1]);return
	if rects.get("prev", Rect2()).has_point(p): m.bag_page = maxi(0, m.bag_page - 1);return
	if rects.get("next", Rect2()).has_point(p): m.bag_page = mini(maxi(0, ceili(m.bag.size() / 12.0) - 1), m.bag_page + 1);return
	if rects.get("sell", Rect2()).has_point(p): m.sell_all();m.market_open = false;return
	if rects.get("close", Rect2()).has_point(p) or not rects.get("panel", Rect2()).has_point(p): m.market_open = false;displayed = false
func detail(m) -> void :
	if selected < 0: return
	if selected_grade>=0: list_view.draw_detail(m);return
	var sp: int = selected; var h: float = m.get_viewport_rect().size.y
	m.text_items = m.text_items.filter( func(it): return it[1].y < m.top_y + 70)
	m._ui_rect(Rect2( - m.ox, 0, m.VW + 2 * m.ox, h), Color(0.025, 0.04, 0.07, 0.82))
	var r: = Rect2(20, roundf(h * 0.5) - 164, 230, 328)
	m._ui_style_box(m.sb_panel, r)
	label(m, m.FISH_NAME[sp], Vector2(135, r.position.y + 31), 194, 14)
	m._ui_fish(sp, Rect2(75, r.position.y + 49, 120, 58))
	m._text("개인 최대어 %.1fcm" % float(m.fish_record_cm(sp)),Vector2(135,r.position.y+111),9,Color("537455"),true,208)
	var bag: Array = counts(m, sp, "bag"); var aqua: Array = counts(m, sp, "aqua")
	var history: Array = m.fish_counts(sp)
	m._text("등급       보관   전시   누적", Vector2(135, r.position.y + 125), 9, Color("7c6448"), true, 208)
	for g in 5:
		var yy: float = r.position.y + 148 + g * 25
		m._ui_rect(Rect2(35, yy - 10, 3, 15), m._aura_col(g, m.ui_clock * 1000, 1))
		m._text(m.GRADE_N[g], Vector2(44, yy), 10, Color("513b29"), false, 59)
		for j in 3:
			var value: String = str([bag[g], aqua[g], history[g]][j])
			if j == 2 and g in m.fish_legacy(sp): value = "≥" + value
			m._text(value, Vector2(125 + j * 46, yy), 10, Color("513b29"), true, 40)
	var legacy: bool = not m.fish_legacy(sp).is_empty()
	m._text("≥ 이전 버전 누적은 최소 확인 수량이에요" if legacy else "누적 수량은 포획 성공 시 기록돼요", Vector2(135, r.end.y - 41), 8, Color("7c6448"), true, 212)
	var close: = Rect2(84, r.end.y - 31, 102, 24);m._ui_style_box(m.sb_btn, close);m._text("닫기", close.get_center() + Vector2(0, 4), 11, Color("513b29"), true, 90)
	rects.detail = r;rects.detail_close = close
func detail_press(p: Vector2) -> void :
	if selected_grade>=0: list_view.detail_press(self,p);return
	if rects.get("detail_close", Rect2()).has_point(p) or not rects.get("detail", Rect2()).has_point(p): selected = -1

func _finish(m, first: int, anchor: Vector2, scale: Vector2, k: float) -> void:
	m.ui_commands.append(["reset_transform"])
	for i in range(first, m.text_items.size()):
		var it: Array = m.text_items[i];it[1] = anchor + (it[1] - anchor) * scale;it[7] *= scale.x
		var col: Color = it[6];col.a *= smoothstep(0.35, 0.85, k);it[6] = col


