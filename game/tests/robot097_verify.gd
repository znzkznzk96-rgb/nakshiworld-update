extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String):
 if not ok: failures.append(label);push_error(label)
func _initialize(): call_deferred('run')
func run():
 var m=load('res://main.gd').new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.development_preview=true
 var b=m.capture_robot;b.owned=true;b.enabled=true;m.scene='fish';m.S.phase='idle';m.market_open=false;m.menu_open=false;m.settings_open=false
 var old=b.serialize();var min_gap=100.0;var max_gap=0.0;var ys=[]
 for i in 64:
  b.visual_time=i*.05
  var q=b.surface_layout(m)
  var gap: float=q.robot.position.y-q.bubble.end.y
  min_gap=minf(min_gap,gap);max_gap=maxf(max_gap,gap);ys.append(q.robot.position.y)
  check(is_equal_approx(q.water,m.WATER+m.oy),'waterline fixed')
 check(max_gap-min_gap<.4 and min_gap>0,'bubble follows hull without overlap or drift')
 check(ys.max()-ys.min()>2.9,'robot floats through full cycle')
 check(b.serialize()==old,'animation does not modify saved economy')
 check(b.ART.get_size()==Vector2(1440,240),'three approved nine frame motions')
 for tex in [b.ART,b.SLEEP,b.CAPTURE,b.SUCCESS,b.FULL]:
  check(tex.get_image().get_pixel(0,0).a==0,'atlas and icon background transparent')
 for h in [480,540,660]:
  var r=Rect2(8,110,254,h-122)
  for tab in 3:
   b.shop_tab=tab;m.V.rects.rows=[];b.draw_shop(m,r,r.position.y+81)
   for key in b.visual_bounds: check(r.encloses(b.visual_bounds[key]),'shop area fits '+str(h)+' '+key)
   for row in m.V.rects.rows: check(r.encloses(row[0]),'touch target fits')
   check(b.visual_bounds.detail.end.y<=b.visual_bounds.storage.position.y,'detail storage separated')
 m.S.phase='fight';b.draw_surface(m);check(b.button.size==Vector2.ZERO,'fight unobstructed')
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print('ROBOT097_VERIFY failures=',failures);quit(0 if failures.is_empty() else 1)
