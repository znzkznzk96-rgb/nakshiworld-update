extends SceneTree
class Probe extends "res://root.gd":
 func _ready()->void:pass
 func _start()->void:started=true
var failures:Array=[]
func check(ok:bool,label:String)->void:
 if not ok:failures.append(label);push_error(label)
func _put(p:String,b:PackedByteArray)->void:
 var f:=FileAccess.open(p,FileAccess.WRITE);f.store_buffer(b);f=null
func _put_text(p:String,t:String)->void:
 var f:=FileAccess.open(p,FileAccess.WRITE);f.store_string(t);f=null
func _dl(m)->void:
 if m.http==null:
  m.http=HTTPRequest.new();m.add_child(m.http)
 m.http.request_completed.connect(m._on_download)
 await m._on_download(0,200,PackedStringArray(),PackedByteArray())
func _clean(m)->void:
 for p in [m.CUR,m.CUR_VER,m.NEXT,m.NEXT_VER,m.PART,m.NEXT_VER+".tmp"]:
  if FileAccess.file_exists(p):DirAccess.remove_absolute(p)
func _initialize()->void:call_deferred("run")
func run()->void:
 var m=Probe.new();root.add_child(m);m.set_process(false)
 for size in [1000000,59319104,80000000]:
  var d:Dictionary=m.transfer_snapshot(size/2,size,7)
  check(is_equal_approx(d.progress,.5) and d.total==size,"manifest size controls progress not response metadata")
  m.update_phase="download";m.expected_size=size;m.received_bytes=size/2;m.progress=d.progress
  check(m.transfer_detail().contains("%.1f MB"%(size/1000000.0)),"actual decimal MB for each file size")
 check(m.transfer_snapshot(500,-1,-1).progress<0,"unknown total never fabricates percent")
 check(m.transfer_snapshot(200,100).progress==1,"progress caps at100")
 m.update_phase="checking";m.progress=1;check(not m.transfer_detail().contains("%"),"manifest request cannot show download completion")
 var points:Array[Vector2]=m.chase_positions(0,Vector2.ZERO);var later:Array[Vector2]=m.chase_positions(1,Vector2.ZERO);var cycle:Array[Vector2]=m.chase_positions(TAU/1.55,Vector2.ZERO)
 check(points!=later and points[0].distance_to(cycle[0])<.001,"cat follows closed orbit")
 check(points[0].distance_to(points[1])>20,"fish leads cat without overlap")
 for i in 40:
  var time:float=i*.1;var motion:Vector2=m.logo_motion(time)
  check(absf(motion.x)<=deg_to_rad(1.5)+.00001 and absf(motion.y)<=1.201,"logo motion remains small and readable")
  var pair:Array[Vector2]=m.chase_positions(time,Vector2.ZERO)
  check(pair[0].distance_to(pair[1])>58,"large cat and fish retain gap through orbit")
 check(m.logo_motion(0)!=m.logo_motion(.9),"logo sways over time")
 DirAccess.make_dir_recursive_absolute(m.UPD_DIR)
 var good:=PackedByteArray([71,68,80,67,1,2,3,4])
 # 1) 지난번에 받아 둔 새 버전은 켤 때 적용된다 / 더 낮은 버전은 버려진다
 _clean(m);_put(m.NEXT,good);_put_text(m.NEXT_VER,"999|9.99");m._apply_pending()
 check(FileAccess.get_file_as_bytes(m.CUR)==good and m._local_code()==999 and m._local_name()=="9.99" and not FileAccess.file_exists(m.NEXT),"pending update applied at launch")
 _put(m.NEXT,PackedByteArray([71,68,80,67,9]));_put_text(m.NEXT_VER,"5|0.05");m._apply_pending()
 check(FileAccess.get_file_as_bytes(m.CUR)==good and not FileAccess.file_exists(m.NEXT),"older pending is discarded and installed kept")
 # 2) 받기 완료 검사: 머리·크기·sha256 중 하나라도 틀리면 저장하지 않는다
 _clean(m);m.want_code=1000;m.want_name="10.00"
 _put(m.PART,PackedByteArray([0,1,2,3,4]));m.expected_size=5;m.expected_hash=FileAccess.get_sha256(m.PART);await _dl(m)
 check(not FileAccess.file_exists(m.NEXT) and not FileAccess.file_exists(m.CUR) and not FileAccess.file_exists(m.PART),"bad header rejected")
 _put(m.PART,good);m.expected_size=good.size();m.expected_hash="0".repeat(64);m.started=false;await _dl(m)
 check(not FileAccess.file_exists(m.NEXT) and not FileAccess.file_exists(m.CUR) and not FileAccess.file_exists(m.PART),"hash mismatch rejected")
 _put(m.PART,good);m.expected_size=good.size()+1;m.expected_hash=FileAccess.get_sha256(m.PART);m.started=false;await _dl(m)
 check(not FileAccess.file_exists(m.NEXT) and not FileAccess.file_exists(m.CUR),"size mismatch rejected")
 _put(m.PART,good);m.expected_size=good.size();m.expected_hash=FileAccess.get_sha256(m.PART);m.started=false;await _dl(m)
 check(FileAccess.get_file_as_bytes(m.CUR)==good and FileAccess.get_file_as_string(m.CUR_VER)=="1000|10.00","verified download in time is applied at first screen")
 # 3) 게임이 이미 시작된 뒤에 끝나면 적용하지 않고 다음 실행 몫으로 둔다
 var cur_before:PackedByteArray=FileAccess.get_file_as_bytes(m.CUR);m.want_code=1001;m.want_name="10.01"
 var good2:=PackedByteArray([71,68,80,67,7,7,7]);_put(m.PART,good2);m.expected_size=good2.size();m.expected_hash=FileAccess.get_sha256(m.PART);m.started=true;await _dl(m)
 check(FileAccess.get_file_as_bytes(m.CUR)==cur_before and FileAccess.get_file_as_bytes(m.NEXT)==good2 and FileAccess.get_file_as_string(m.NEXT_VER)=="1001|10.01","late download waits for next launch")
 m.started=false;m._apply_pending()
 check(FileAccess.get_file_as_bytes(m.CUR)==good2 and m._local_code()==1001,"next launch applies it")
 # 4) 예전 방식 파일 정리
 _put("user://patch.pck",good);_put_text("user://patch_ver.txt","50|0.50");m._drop_legacy()
 check(not FileAccess.file_exists("user://patch.pck") and not FileAccess.file_exists("user://patch_ver.txt"),"legacy full patch removed")
 _clean(m)
 print("UPDATER_VERIFY failures=",failures);m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
