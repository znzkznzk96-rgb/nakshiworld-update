extends RefCounted
# Final-size bitmap silhouettes. Filled bodies and dark continuous outlines.
const PALETTE={"o":Color("352d2c"),"g":Color("bc7836"),"h":Color("f2bf62"),"b":Color("29879b"),"w":Color("fff6d8"),"d":Color("244653"),"t":Color("78d5d2")}
func pixel(m,p:Vector2,x:int,y:int,c:String):m._ui_rect(Rect2(p+Vector2(x,y),Vector2.ONE),PALETTE[c])
func bitmap(m,p:Vector2,rows:Array):
 for y in rows.size():
  for x in rows[y].length():
   var c:String=rows[y][x]
   if PALETTE.has(c):pixel(m,p,x,y,c)
func fish(m,p:Vector2):
 bitmap(m,p,[".....oooo...","....ottbbo..","oo.ottwwbbo.","oboottwwobo.","obbbtttbbbo.","oboobbbbbo..","oo..ooooo..."])
func draw(m,key:String,p:Vector2,frame:int=0):
 p=p.round()
 match key:
  "capture":
   bitmap(m,p+Vector2(1,0),["..........ooooooo....","........oohhhhhhoo...","......oohhooooo.oo...",".....ohhoo.......o...","....ohho.........o...","...ohho..........o...","..ohho...........o...","..oggo...........o...",".oggooo..........o...",".oggohho.........o...","oggoohho.........o...","oggoooo..............","oooo................."])
   fish(m,p+Vector2(15,9+frame))
  "success":
   fish(m,p+Vector2(8,6))
   bitmap(m,p+Vector2(1,3),["..o..",".oho.","ohhho",".oho.","..o.."])
   bitmap(m,p+Vector2(22,1+frame),["..o..",".oho.","ohhho",".oho.","..o.."])
  "full":
   bitmap(m,p+Vector2(3,3),["..oooooooooooooo..",".ohhhhhhhhhhhhhho.","oggggggggggggggggo","oghooooooooooohggo","oghohhhhhhhhoohggo","oooooooooooooooooo","oggggggohogggggggo","oghhgggooogggghhgo","oghhgggggggggghhgo","oghhgggggggggghhgo",".oooooooooooooooo."])
   bitmap(m,p+Vector2(23,2+frame),["oooo","ohho","ohho","ohho","ohho","oooo","....","oooo","ohho","oooo"])
  "sleep":
   bitmap(m,p+Vector2(0,6),["oooooooo","otttttto","oooootto","...otto.","..otto..",".ottoooo","otttttto","oooooooo"])
   bitmap(m,p+Vector2(8,1),["ooooo","ohhho","oohoo",".oho.","ohhoo","ooooo"])
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
