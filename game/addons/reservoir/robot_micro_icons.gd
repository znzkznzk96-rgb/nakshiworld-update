extends RefCounted
# Native 28x16 UI glyphs: every pixel is authored at its final logical size.
# No resized textures, interpolation, or large-master downsampling.
const PALETTE={"o":Color("493828"),"g":Color("cd9648"),"h":Color("f2ca73"),"b":Color("447e95"),"w":Color("fff6d8"),"d":Color("244653"),"t":Color("83cbd0")}
func pixel(m,p:Vector2,x:int,y:int,c:String):m._ui_rect(Rect2(p+Vector2(x,y),Vector2.ONE),PALETTE[c])
func block(m,p:Vector2,x:int,y:int,w:int,h:int,c:String):m._ui_rect(Rect2(p+Vector2(x,y),Vector2(w,h)),PALETTE[c])
func stroke(m,p:Vector2,a:Vector2i,b:Vector2i,c:String):
 var n:int=maxi(absi(b.x-a.x),absi(b.y-a.y))
 for i in n+1:
  var q:Vector2i=Vector2i(Vector2(a).lerp(Vector2(b),float(i)/maxi(1,n)).round());pixel(m,p,q.x,q.y,c)
func fish(m,p:Vector2):
 var rows=["...oooo....","..obwwwo...","oobwwwww o.","obwwwwdwwo.","oobwwwww o.","..obttto...","...oooo...."]
 for y in rows.size():
  for x in rows[y].length():
   var c:String=rows[y][x]
   if PALETTE.has(c):pixel(m,p,x,y,c)
func draw(m,key:String,p:Vector2,frame:int=0):
 p=p.round()
 match key:
  "capture":
   stroke(m,p,Vector2i(2,14),Vector2i(6,6),"o");stroke(m,p,Vector2i(3,15),Vector2i(7,7),"o")
   stroke(m,p,Vector2i(3,13),Vector2i(7,5),"g")
   stroke(m,p,Vector2i(7,5),Vector2i(14,1),"o");stroke(m,p,Vector2i(7,6),Vector2i(14,2),"h")
   stroke(m,p,Vector2i(14,1),Vector2i(19,1),"o");stroke(m,p,Vector2i(14,2),Vector2i(18,2),"g")
   stroke(m,p,Vector2i(19,2),Vector2i(21,8),"b")
   block(m,p,7,9,3,3,"o");pixel(m,p,8,10,"h")
   fish(m,p+Vector2(16,8+frame))
  "success":
   fish(m,p+Vector2(8,6))
   stroke(m,p,Vector2i(3,4),Vector2i(3,8),"g");stroke(m,p,Vector2i(1,6),Vector2i(5,6),"g")
   stroke(m,p,Vector2i(23,1+frame),Vector2i(23,5+frame),"g");stroke(m,p,Vector2i(21,3+frame),Vector2i(25,3+frame),"g")
  "full":
   block(m,p,4,4,17,11,"o");block(m,p,5,5,15,9,"g");block(m,p,6,5,13,2,"h")
   block(m,p,5,8,15,2,"o");block(m,p,7,10,2,4,"h");block(m,p,16,10,2,4,"h")
   block(m,p,11,8,3,4,"o");pixel(m,p,12,9,"w")
   block(m,p,24,2+frame,2,7,"o");block(m,p,24,11+frame,2,2,"o")
  "sleep":
   stroke(m,p,Vector2i(1,6),Vector2i(6,6),"b");stroke(m,p,Vector2i(6,6),Vector2i(1,11),"b");stroke(m,p,Vector2i(1,11),Vector2i(6,11),"b")
   stroke(m,p,Vector2i(9,2),Vector2i(12,2),"g");stroke(m,p,Vector2i(12,2),Vector2i(9,5),"g");stroke(m,p,Vector2i(9,5),Vector2i(12,5),"g")
func timer(m,p:Vector2,seconds:int):
 var digits=[['ooo','o.o','o.o','o.o','ooo'],['.o.','oo.','.o.','.o.','ooo'],['ooo','..o','ooo','o..','ooo'],['ooo','..o','ooo','..o','ooo'],['o.o','o.o','ooo','..o','..o'],['ooo','o..','ooo','..o','ooo'],['ooo','o..','ooo','o.o','ooo'],['ooo','..o','..o','..o','..o'],['ooo','o.o','ooo','o.o','ooo'],['ooo','o.o','ooo','..o','ooo']]
 var value:String=str(clampi(seconds,0,999));var x:int=0
 for digit in value:
  var rows:Array=digits[int(digit)]
  for yy in 5:
   for xx in 3:
    if rows[yy][xx]=='o':pixel(m,p,x+xx,yy+2,'o')
  x+=4
 var suffix=['..o..','ooooo','..o..','.o.o.','o...o','..o..','ooooo']
 for yy in 7:
  for xx in 5:
   if suffix[yy][xx]=='o':pixel(m,p,x+xx,yy,'o')
