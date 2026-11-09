extends SceneTree
class Monitor extends Node:
 var helper:RefCounted
 var samples:=0
 var bad:=false
 func _process(_dt:float)->void:
  var s:Dictionary=helper.snapshot();samples+=1
  if s.total>0 and (s.received>s.total or s.progress<0 or s.progress>1):bad=true
func _initialize()->void:call_deferred("run")
func run()->void:
 var args:=OS.get_cmdline_user_args();var helper=load("res://incremental_update.gd").new()
 var monitor:=Monitor.new();monitor.helper=helper;root.add_child(monitor)
 var ok:bool=await helper.download(root,args[0],59403488,"cf592988a1e8f372cc37d6ef3a4fe3041b6e92a07b40fce509baeb8a3dcfb2a3","user://reconstructed.pck",args[1])
 print("DOWNLOAD_RESULT",ok," bytes=",helper.received," planned=",helper.planned," error=",helper.error)
 var request:=HTTPRequest.new();root.add_child(request);request.request("http://127.0.0.1:18765/stats");var r:Array=await request.request_completed;var stats=JSON.parse_string(r[3].get_string_from_utf8()) if r[1]==200 else {"bytes":-1,"response":r[1],"result":r[0]}
 var correct:bool=ok and not monitor.bad and monitor.samples>0 and helper.received==helper.planned and helper.received==int(stats.bytes) and helper.received<59403488*.05 and helper.reused>2000
 print("INCREMENTAL_NETWORK_VERIFY failures=",[] if correct else ["network reconstruction"]," received=",helper.received," planned=",helper.planned," server=",stats," reused=",helper.reused," error=",helper.error," gauge_samples=",monitor.samples," gauge_bad=",monitor.bad)
 quit(0 if correct else 1)
