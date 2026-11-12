extends RefCounted
const STONE: = [Color("c2b497"), Color("cbbb9e"), Color("bcad90"), Color("d0c0a2"), Color("c6b99d")]
static func deck_y(x: float) -> float:
	return 22.0
static func draw(m, v, o: Vector2) -> void :
	# The quay turns back into the water at the harbor mouth.
	m.draw_rect(Rect2(o+Vector2(350,-4),Vector2(v.MAP_W-350,75)),Color("897b63"))
	for row in 8:
		var x := 324 + absi(row-3)*3
		var y := -2 + row*9
		m.draw_rect(Rect2(o+Vector2(x,y),Vector2(350-x,9)),Color("515e55"))
		var split := 337 + (row%2)*6
		for span in [[x,split],[split,351]]:
			var width:int=span[1]-span[0]-1
			if width < 2: continue
			var face:Color=STONE[(row+span[0])%STONE.size()].darkened(0.16 if row<6 else 0.4)
			m.draw_rect(Rect2(o+Vector2(span[0],y),Vector2(width,8)),face)
			m.draw_rect(Rect2(o+Vector2(span[0]+1,y),Vector2(width-1,1)),face.lightened(0.22))
			m.draw_rect(Rect2(o+Vector2(span[0],y+6),Vector2(width,2)),face.darkened(0.16))

	for row in 5:
		var y: float = 3 + row * 10
		for col in range(-1, 66):
			var x: float = 350 + col * 20 + (10 if row % 2 else 0)
			if x < 350 or x >= v.MAP_W or not v._visible(x, 35): continue
			var w: = minf(19, v.MAP_W - x)
			var k: = posmod(col * 7 + row * 11, STONE.size())
			var face: = PackedVector2Array([Vector2(x + 1, y), Vector2(x + w - 1, y), Vector2(x + w, y + 1), Vector2(x + w, y + 7), Vector2(x + w - 1, y + 9), Vector2(x + 1, y + 9), Vector2(x, y + 8), Vector2(x, y + 1)])
			for point in face.size(): face[point] += o
			m.draw_colored_polygon(face, STONE[k])
			m.draw_rect(Rect2(o + Vector2(x + 2, y + 1), Vector2(w - 5, 1)), STONE[k].lightened(0.1))
			m.draw_rect(Rect2(o + Vector2(x + 2, y + 8), Vector2(w - 4, 1)), STONE[k].darkened(0.12))
			if posmod(col + row * 3, 7) == 0:
				m.draw_rect(Rect2(o + Vector2(x + 5, y + 3), Vector2(7, 2)), STONE[k].lightened(0.025))

	for b in v.BUILD:
		if b[1] == "harbor": continue
		var x: float = b[2].get_center().x
		if v._visible(x, 35):
			m.draw_rect(Rect2(o + Vector2(x - 19, -1), Vector2(38, 4)), Color("ad9d80"))
			m.draw_rect(Rect2(o + Vector2(x - 18, -1), Vector2(36, 1)), Color("e0cfab"))
	for col in 64:
		var x: float = 350 + col * 20
		if not v._visible(x, 35): continue
		m.draw_rect(Rect2(o + Vector2(x, 54), Vector2(19, 5)), Color("b5aa8e"))
		m.draw_rect(Rect2(o + Vector2(x, 54), Vector2(19, 1)), Color("ddd0af"))
		m.draw_rect(Rect2(o + Vector2(x, 60), Vector2(19, 9)), Color("68746b") if col % 3 else Color("728075"))
		m.draw_rect(Rect2(o + Vector2(x, 60), Vector2(19, 1)), Color("9aa18b"))
	m.draw_rect(Rect2(o + Vector2(350, 70), Vector2(v.MAP_W - 350, 2)), Color("344e4d"))
	for i in 12:
		var x: float = 367 + i * 104
		if v._visible(x, 40):
			m.draw_rect(Rect2(o + Vector2(x, 68), Vector2(9, 2)), Color("78865e"))
			var drift: = sin(v.town_time * 0.8 + i) * 3
			m.draw_line(o + Vector2(x + drift, 73), o + Vector2(x + 18 + drift, 73), Color(0.7, 0.9, 0.84, 0.18), 1)
static func bridge(m, o: Vector2) -> void:
	# One continuous timber deck with a wider passenger platform at the left.
	var dark:=Color("49342b")
	var timber:=Color("946043")
	var light:=Color("ce9861")
	for x in range(8,337,28):
		var foot:=o+Vector2(x,32)
		m.draw_rect(Rect2(foot,Vector2(6,18)),dark)
		m.draw_rect(Rect2(foot+Vector2(1,0),Vector2(3,15)),timber)
		m.draw_rect(Rect2(foot+Vector2(1,15),Vector2(4,3)),Color("515950"))
		m.draw_line(foot+Vector2(5,10),foot+Vector2(16,0),dark,2)
		m.draw_rect(Rect2(foot+Vector2(-2,19),Vector2(11,1)),Color("76b2b0"))
	m.draw_rect(Rect2(o+Vector2(5,20),Vector2(336,15)),dark)
	for x in range(6,340,8):
		var board:=light.darkened(0.045*((x/8)%3))
		m.draw_rect(Rect2(o+Vector2(x,21),Vector2(mini(7,340-x),8)),board)
		m.draw_rect(Rect2(o+Vector2(x+1,22),Vector2(1,5)),board.lightened(0.12))
	m.draw_rect(Rect2(o+Vector2(5,30),Vector2(336,3)),timber)
	m.draw_rect(Rect2(o+Vector2(5,30),Vector2(336,1)),light)
	# Rounded end pile and rope bands mark the free end of the passenger pier.
	m.draw_rect(Rect2(o+Vector2(5,14),Vector2(7,24)),dark)
	m.draw_rect(Rect2(o+Vector2(6,13),Vector2(5,23)),timber)
	m.draw_rect(Rect2(o+Vector2(5,13),Vector2(7,2)),light)
	for band in [18,21]:
		m.draw_rect(Rect2(o+Vector2(4,band),Vector2(9,2)),Color("d5b985"))
	# Low rear rail leaves the walking surface visible under passengers.
	for y in [10,15]:
		m.draw_rect(Rect2(o+Vector2(212,y),Vector2(121,2)),dark)
		m.draw_rect(Rect2(o+Vector2(212,y),Vector2(121,1)),light)
	for x in range(212,334,24):
		m.draw_rect(Rect2(o+Vector2(x,7),Vector2(4,14)),dark)
		m.draw_rect(Rect2(o+Vector2(x+1,7),Vector2(2,12)),timber)
		m.draw_rect(Rect2(o+Vector2(x-1,6),Vector2(6,2)),light)
	for step in 3:
		var pos:=o+Vector2(336+step*5,21-step*2)
		m.draw_rect(Rect2(pos,Vector2(6,10)),Color("887d69"))
		m.draw_rect(Rect2(pos,Vector2(6,2)),Color("d8c7a6"))
static func front(_n: Node2D) -> void :
	pass


const BOARDING_OFFSET := 55.0

static func boarding_y(x: float) -> float:
	return 62.0 - 4.0 * clampi(floori((x-161.0)/6.0)+1,0,10)

static func boarding(m, o: Vector2, docked: bool) -> void:
	o.x += BOARDING_OFFSET
	var wood:=Color("835035")
	var edge:=Color("453029")
	var lit:=Color("dca46a")
	# Lower landing alongside the bow, with a short removable boarding plank.
	for x in [151,175,199,217]:
		var y:=boarding_y(x)
		m.draw_rect(Rect2(o+Vector2(x,y+3),Vector2(5,75-y)),edge)
		m.draw_rect(Rect2(o+Vector2(x+1,y+4),Vector2(2,72-y)),wood)
	for x in range(146,221):
		var y:=boarding_y(x)
		m.draw_rect(Rect2(o+Vector2(x,y),Vector2(1,6)),edge)
		m.draw_rect(Rect2(o+Vector2(x,y+1),Vector2(1,3)),wood)
		m.draw_rect(Rect2(o+Vector2(x,y),Vector2(1,1)),lit)
	for x in [157,181,205,219]:
		var y:=boarding_y(x)
		m.draw_rect(Rect2(o+Vector2(x,y-9),Vector2(3,9)),wood)
		m.draw_rect(Rect2(o+Vector2(x-1,y-10),Vector2(5,2)),lit)
	for pair in [[157,181],[181,205],[205,219]]:
		var a:=Vector2(pair[0]+1,boarding_y(pair[0])-8)
		var b:=Vector2(pair[1]+1,boarding_y(pair[1])-8)
		m.draw_line(o+a,o+b,edge,2)
	if docked:
		m.draw_rect(Rect2(o+Vector2(135,62),Vector2(18,3)),wood)
		m.draw_rect(Rect2(o+Vector2(135,62),Vector2(18,1)),lit)
