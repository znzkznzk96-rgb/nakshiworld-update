extends SceneTree
class Uri extends RefCounted:
 pass
class Values extends RefCounted:
 var data:Dictionary={}
 func put(key,value):data[key]=value
 func clear():data={}
class Version extends RefCounted:
 var SDK_INT:=35
class Media extends RefCounted:
 var EXTERNAL_CONTENT_URI:="content://media/external/images/media"
class Factory extends RefCounted:
 func ContentValues():return Values.new()
class Stream extends RefCounted:
 var owner_wrapper
 func write(_data):
  owner_wrapper.calls.append("write")
  if owner_wrapper.fail_write:owner_wrapper.exception="write failed"
 func flush():owner_wrapper.calls.append("flush")
 func close():owner_wrapper.calls.append("close")
class Descriptor extends RefCounted:
 var owner_wrapper
 func getStatSize():return 2 if owner_wrapper.fail_size else 3
 func close():owner_wrapper.calls.append("verify_close")
class Resolver extends RefCounted:
 var owner_wrapper
 func insert(_uri,values):
  owner_wrapper.calls.append("insert");owner_wrapper.inserted=values.data.duplicate();return Uri.new()
 func openOutputStream(_uri,_mode):
  owner_wrapper.calls.append("open")
  var stream:=Stream.new();stream.owner_wrapper=owner_wrapper;return stream
 func openFileDescriptor(_uri,_mode):
  owner_wrapper.calls.append("verify_size")
  var descriptor:=Descriptor.new();descriptor.owner_wrapper=owner_wrapper;return descriptor
 func update(_uri,values,_selection:String,_args:PackedStringArray):
  owner_wrapper.calls.append("publish");owner_wrapper.published=values.data.duplicate();return 1
 func delete(_uri,_selection:String,_args:PackedStringArray):owner_wrapper.calls.append("delete");return 1
class Context extends RefCounted:
 var owner_wrapper
 func getContentResolver():
  var resolver:=Resolver.new();resolver.owner_wrapper=owner_wrapper;return resolver
class Runtime extends RefCounted:
 var owner_wrapper
 func getApplicationContext():
  var context:=Context.new();context.owner_wrapper=owner_wrapper;return context
class Wrapper extends RefCounted:
 var fail_size:=false
 var fail_write:=false
 var exception=null
 var calls:Array=[]
 var inserted:Dictionary={}
 var published:Dictionary={}
 func wrap(name):
  if name=="android.os.Build$VERSION":return Version.new()
  if name=="android.content.ContentValues":return Factory.new()
  if name=="android.provider.MediaStore$Images$Media":return Media.new()
  return null
 func get_exception():
  var result=exception;exception=null;return result
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label);push_error(label)
func _initialize():
 var gallery=load("res://addons/reservoir/record_gallery.gd").new()
 for mode in ["success","write_failure","size_failure"]:
  var fail_write:bool=mode=="write_failure"
  var wrapper:=Wrapper.new();wrapper.fail_write=fail_write;wrapper.fail_size=mode=="size_failure"
  var runtime:=Runtime.new();runtime.owner_wrapper=wrapper
  var result:Dictionary=gallery.android_save(PackedByteArray([1,2,3]),"record.png",wrapper,runtime)
  check(result.ok==(mode=="success"),"save result reflects write outcome")
  check(wrapper.inserted.is_pending=="1" and wrapper.inserted.relative_path=="Pictures/NakshiWorld","new owned image is initially pending")
  if fail_write:
   check(wrapper.calls==["insert","open","write","close","delete"],"failure closes stream and deletes partial gallery row")
   check(wrapper.published.is_empty(),"failed image never published")
  elif mode=="size_failure":
   check(wrapper.calls==["insert","open","write","flush","close","verify_size","verify_close","delete"],"size mismatch removes unpublished row")
   check(wrapper.published.is_empty(),"truncated image never published")
  else:
   check(wrapper.calls==["insert","open","write","flush","close","verify_size","verify_close","publish"],"publish only after complete write and close")
   check(wrapper.published=={"is_pending":"0"},"publish pending row only")
 print("RECORD_GALLERY_VERIFY failures=",failures," native_device_verified=false")
 quit(0 if failures.is_empty() else 1)
