extends SceneTree
class Screen extends Node2D:
	var mode: int=0
	var font=load("res://font/Galmuri11.ttf")
	var panel=load("res://art/ui_forest/panel.png")
	var hud=load("res://art/ui_forest/hud.png")
	var button=load("res://art/ui_forest/primary.png")
	var fish=[]
	var ink=Color("392a25")
	var cream=Color("fff1cf")
	var gold=Color("dba74c")
	var teal=Color("3daaa0")
	func _init():
		for i in [1,4,3]: fish.append(load("res://art/fish/l0_%02d.png"%i))
	func box(r:Rect2,texture=panel):
		var st=StyleBoxTexture.new();st.texture=texture
		for side in [0,1,2,3]:st.set_texture_margin(side,8)
		draw_style_box(st,r)
	func text(s:String,x:float,y:float,size:int=10,col=Color("392a25"),center:bool=false):
		var w=font.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
		draw_string(font,Vector2(x-w/2 if center else x,y),s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,col)
	func bar(r:Rect2,value:float,color:Color):
		draw_rect(r,Color("263c3e"));draw_rect(Rect2(r.position,r.size*Vector2(clampf(value,0,1),1)),color)
	func fish_icon(i:int,p:Vector2,w:float=29):
		var tx=fish[i%3];var sz=tx.get_size();draw_texture_rect(tx,Rect2(p,Vector2(w,w*sz.y/sz.x)),false)
	func door(p:Vector2,n:int,open:bool=false):
		draw_rect(Rect2(p-Vector2(2,2),Vector2(28,38)),Color("4b3d2b"))
		draw_rect(Rect2(p,Vector2(24,34)),Color("468b8c") if open else Color("786541"))
		draw_rect(Rect2(p+Vector2(3,3),Vector2(18,25)),Color("123d46") if open else Color("3e392d"))
		draw_rect(Rect2(p+Vector2(18,18),Vector2(2,3)),gold)
		text(str(n),p.x+12,p.y+13,8,cream,true)
	func header(title:String):
		draw_rect(Rect2(0,0,270,540),Color("182f34"))
		box(Rect2(7,7,256,32),hud);text("‹",18,28,16,cream);text(title,135,28,13,cream,true)
		box(Rect2(8,44,254,31));text("저수지",20,64,11);text("계곡  잠김",115,64,9,Color("897d66"));text("1 / 6",242,64,9,ink,true)
	func footer(active:String):
		box(Rect2(7,501,256,32),hud)
		for i in 4:
			var s=["마을","연성","병사","백룸"][i];text(s,39+i*64,522,10,gold if s==active else cream,true)
	func selected():
		box(Rect2(8,389,254,104));text("1-4  꺼지지 않는 복도",28,417,12)
		text("추천 육성  1성 · 레벨 3",28,437,9)
		text("첫 보상  비늘 160 · 인장 2",28,453,9)
		box(Rect2(17,462,236,24),button);text("편성 확인  ·  출발",135,479,11,cream,true)
	func map_a():
		header("백룸 탐사")
		draw_rect(Rect2(9,82,252,298),Color("d4c391"))
		# Reservoir threshold and a chain of ten rooms.
		for x in range(10,260,12):
			draw_rect(Rect2(x,84,8,4),Color("a7b9a0"));draw_rect(Rect2(x,113,6,3),Color("89acb0"))
		text("호숫가에 없는 건물",135,103,11,ink,true)
		var pts=[Vector2(48,147),Vector2(135,147),Vector2(222,147),Vector2(222,207),Vector2(135,207),Vector2(48,207),Vector2(48,267),Vector2(135,267),Vector2(222,267),Vector2(222,337)]
		for i in 9:draw_line(pts[i],pts[i+1],Color("8a7756"),4)
		for i in 10:
			var p=pts[i];var done=i<3;var current=i==3
			draw_rect(Rect2(p-Vector2(19,18),Vector2(38,36)),Color("225858") if done else Color("aa7635") if current else Color("ac9c77"))
			draw_rect(Rect2(p-Vector2(16,15),Vector2(32,30)),Color("3f8f80") if done else Color("f2cb71") if current else Color("c6b68d"))
			text(str(i+1),p.x,p.y+5,12,ink,true)
			text("완료" if done else "도전" if current else "잠김",p.x,p.y+30,8,ink,true)
		text("돌파 3 / 10",54,344,11)
		text("연결된 방을 하나씩 개방",20,367,9)
		selected();footer("백룸")
	func map_b():
		header("문 너머의 저수지")
		draw_rect(Rect2(9,82,252,298),Color("3b443a"))
		for y in range(82,380,12):draw_line(Vector2(9,y),Vector2(261,y),Color("505344"),1)
		draw_rect(Rect2(109,83,52,294),Color("8a8460"))
		for y in range(90,380,20):draw_rect(Rect2(131,y,8,8),Color("a7a07a"))
		var pts=[]
		for i in 10:
			var y=94+(i/2)*55;var x=57 if i%2==0 else 188;pts.append(Vector2(x+12,y+17))
			if i>0:draw_line(pts[i-1],pts[i],Color("c2b06a"),2)
		for i in 10:
			var y=94+(i/2)*55;var x=57 if i%2==0 else 188
			door(Vector2(x,y),i+1,i<4)
			text("완료" if i<3 else "도전" if i==3 else "잠김",x+12,y+46,8,cream,true)
		text("형광등은 네 번째 문까지만 켜져 있다",135,376,8,cream,true)
		selected();footer("백룸")
	func map_c():
		header("탐사 기록부")
		box(Rect2(8,82,254,298));text("저수지 구역  /  돌파 3·10",28,109,11)
		var names=["젖은 현관","비어 있는 탈의실","반복되는 세면대","꺼지지 않는 복도","거울 없는 세면실","잠긴 관리실","물소리 나는 계단","끝없는 여과실","돌아오는 복도","출구를 닮은 문"]
		for i in 10:
			var y=114+i*25
			if i==3:draw_rect(Rect2(16,y,238,24),Color("ebd390"))
			draw_line(Vector2(19,y+24),Vector2(249,y+24),Color("d3c39c"),1)
			text("%02d"%(i+1),24,y+16,10,Color("6b7058"));text(names[i],52,y+16,10)
			text("완료" if i<3 else "도전" if i==3 else "잠김",230,y+16,8,Color("28796d") if i<4 else Color("9b9078"),true)
		selected();footer("백룸")
	func village():
		header("낚시월드")
		draw_rect(Rect2(0,80,270,420),Color("789b6a"))
		for y in range(84,500,10):
			for x in range(0,270,13):
				if (x+y)%5==0:draw_rect(Rect2(x,y,3,2),Color("92ad76"))
		draw_rect(Rect2(119,80,33,420),Color("c4ad7c"));draw_rect(Rect2(0,240,270,29),Color("c4ad7c"))
		for b in [[20,116,"연성소"],[176,125,"수족관"],[20,286,"상점"]]:
			var x=b[0];var y=b[1]
			draw_rect(Rect2(x,y+18,70,60),Color("baa074"));draw_rect(Rect2(x-4,y,78,28),Color("5b7170"));draw_rect(Rect2(x+4,y+5,62,5),Color("77938b"))
			draw_rect(Rect2(x+27,y+47,18,31),Color("4c4437"));draw_rect(Rect2(x+8,y+37,12,13),Color("f7d483"));text(b[2],x+35,y+94,10,ink,true)
		draw_rect(Rect2(176,288,72,81),Color("514d3d"));door(Vector2(200,316),4,true);text("이상한 문",212,387,10,cream,true)
		for i in 3:fish_icon(i,Vector2(126+i*19,278+i*6),20)
		text("저수지 탐험대",135,103,10,cream,true)
	func progress_a():
		village();box(Rect2(7,393,256,101),hud)
		text("탐사 중  ·  1-4 복도",19,414,11,cream)
		text("공략",19,434,9,cream);bar(Rect2(49,424,171,10),.64,teal);text("64%",244,433,9,cream,true)
		text("체력",19,453,9,cream);bar(Rect2(49,443,171,8),.73,Color("88ba71"));text("73%",244,452,9,cream,true)
		text("병사 3마리  ·  공략을 계속하고 있어요",19,476,9,cream);footer("마을")
	func progress_b():
		village();box(Rect2(7,344,256,150),hud)
		text("1-4  꺼지지 않는 복도",19,365,11,cream)
		for i in 3:
			var x=18+i*80;box(Rect2(x,372,74,65));fish_icon(i,Vector2(x+21,383),30)
			text(["방패병","창병","의무병"][i],x+37,412,9,ink,true);text("★1  Lv.3",x+37,425,8,ink,true)
		text("부대 체력 73%",19,451,9,cream);bar(Rect2(103,443,145,8),.73,Color("88ba71"))
		text("공략 64%",19,478,10,cream);bar(Rect2(83,468,165,12),.64,teal);footer("마을")
	func progress_c():
		village();box(Rect2(7,320,256,174),hud)
		text("1-4  복도 탐사",19,342,11,cream)
		draw_rect(Rect2(17,352,236,67),Color("303c39"))
		for x in range(18,250,20):draw_rect(Rect2(x,354,16,3),Color("95936b"))
		draw_line(Vector2(29,403),Vector2(242,403),Color("7c806a"),2)
		for i in 3:fish_icon(i,Vector2(35+i*26,377),25)
		door(Vector2(218,367),4,true)
		text("수색",37,414,8,cream);text("저항 제압 중",162,383,9,cream,true)
		text("공략 64%",20,441,10,cream);bar(Rect2(84,431,162,11),.64,teal)
		text("부대 체력 73%",20,464,9,cream);bar(Rect2(109,455,137,8),.73,Color("88ba71"))
		text("문 너머에서 물소리가 들린다",135,482,8,cream,true);footer("마을")
	func _draw():
		match mode:
			0:map_a()
			1:map_b()
			2:map_c()
			3:progress_a()
			4:progress_b()
			5:progress_c()
func _initialize():call_deferred("run")
func run():
	var out=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size=Vector2i(270,540);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(540,1080)
	var screen=Screen.new();root.add_child(screen)
	for i in 6:
		screen.mode=i;screen.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join(["map-trail","map-doors","map-journal","progress-compact","progress-party","progress-corridor"][i]+".png"))
	print("BACKROOMS_DESIGN_PREVIEW complete 6");quit()
