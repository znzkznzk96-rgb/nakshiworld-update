extends RefCounted

const BOARDING_OFFSET := 55.0
const BOARDS := [Color("ac7850"), Color("b67e51"), Color("aa7249"), Color("ba8559")]

static func deck_y(_x: float) -> float:
	return 22.0

static func draw(m, v, o: Vector2) -> void:
	o = o.round()
	var length: int = v.MAP_W
	# Deep pile ends and their reflections sit behind the continuous edge beam.
	for x in range(8, length, 34):
		if not v._visible(x, 44): continue
		m.draw_rect(Rect2(o+Vector2(x,26),Vector2(6,27)),Color("453731"))
		m.draw_rect(Rect2(o+Vector2(x+1,28),Vector2(3,21)),Color("886047"))
		m.draw_rect(Rect2(o+Vector2(x+1,47),Vector2(4,5)),Color("58625a"))
		m.draw_line(o+Vector2(x+5,41),o+Vector2(x+16,28),Color("5f4635"),3)
		m.draw_rect(Rect2(o+Vector2(x-2,54),Vector2(11,1)),Color("83b4af"))
	m.draw_rect(Rect2(o+Vector2(0,-3),Vector2(length,34)),Color("503b30"))
	for row in range(4):
		var y := -2 + row*7
		for x in range(-24 if row%2 else 0,length,48):
			if not v._visible(x,64): continue
			var start := maxi(0,x)
			var width := mini(length,x+48)-start
			var plank: Color = BOARDS[posmod(floori(x/48.0)*7+row*3,4)]
			m.draw_rect(Rect2(o+Vector2(start,y),Vector2(width-1,6)),plank)
			m.draw_rect(Rect2(o+Vector2(start,y),Vector2(width-1,1)),plank.lightened(0.18))
			if width>18:
				m.draw_rect(Rect2(o+Vector2(start+6,y+4),Vector2(10+(row%3)*3,1)),plank.darkened(0.10))
				m.draw_rect(Rect2(o+Vector2(start+2,y+2),Vector2(1,1)),Color("69503e"))
	m.draw_rect(Rect2(o+Vector2(0,25),Vector2(length,2)),Color("d8a775"))
	m.draw_rect(Rect2(o+Vector2(0,27),Vector2(length,3)),Color("896044"))

static func front(_n: Node2D) -> void:
	pass
