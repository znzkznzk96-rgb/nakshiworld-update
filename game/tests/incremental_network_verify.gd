extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var args:=OS.get_cmdline_user_args();var helper=load("res://incremental_update.gd").new()
 var ok:bool=await helper.download(root,args[0],59403488,"cf592988a1e8f372cc37d6ef3a4fe3041b6e92a07b40fce509baeb8a3dcfb2a3","user://reconstructed.pck",args[1])
 print("DOWNLOAD_RESULT",ok," bytes=",helper.received," planned=",helper.planned," error=",helper.error)
 var request:=HTTPRequest.new();root.add_child(request);request.request("http://127.0.0.1:18765/stats");var r:Array=await request.request_completed;var stats=JSON.parse_string(r[3].get_string_from_utf8()) if r[1]==200 else {"bytes":-1,"response":r[1],"result":r[0]}
 var correct:bool=ok and helper.received==helper.planned and helper.received==int(stats.bytes) and helper.received<59403488*.05 and helper.reused>2000
 print("INCREMENTAL_NETWORK_VERIFY failures=",[] if correct else ["network reconstruction"]," received=",helper.received," planned=",helper.planned," server=",stats," reused=",helper.reused," error=",helper.error)
 quit(0 if correct else 1)
