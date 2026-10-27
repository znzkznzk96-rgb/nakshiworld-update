extends "res://addons/expedition/view.gd"
# Review-only fishing strip. Result dialog now uses production renderer.
var proposal: String=""
func draw(m,h: float) -> void:
	if proposal=="compact": compact(m)
	else: super.draw(m,h)
func compact(m) -> void:
	var r:=Rect2(8,m.top_y+70,254,24)
	m._ui_style_box(m.hud_reference_style,r)
	m._text("탐험 1-3",r.position+Vector2(9,15),9,Color("ffe3a0"),false,65)
	m._ui_rect(Rect2(r.position+Vector2(79,10),Vector2(127,4)),Color("493a2b"))
	m._ui_rect(Rect2(r.position+Vector2(79,10),Vector2(81,4)),Color("30baa8"))
	m._text("64%",r.position+Vector2(233,15),9,Color("85e3d5"),true,36)
