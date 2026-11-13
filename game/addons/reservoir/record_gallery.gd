extends RefCounted
# MediaStore writes only the new image owned by this app. No media-read permission.
var last_error := ""
func failure(message: String) -> Dictionary:
 last_error=message
 return {"ok":false,"message":message}
func checked(wrapper) -> bool:
 return wrapper.get_exception()==null
func android_save(data: PackedByteArray, filename: String, wrapper, runtime) -> Dictionary:
 var version=wrapper.wrap("android.os.Build$VERSION")
 if version==null or not checked(wrapper):return failure("안드로이드 정보를 확인하지 못했어요")
 if int(version.SDK_INT)<29:return failure("이 기기의 갤러리 저장은 Android 10 이상이 필요해요")
 var context=runtime.getApplicationContext()
 if context==null or not checked(wrapper):return failure("갤러리에 연결하지 못했어요")
 var resolver=context.getContentResolver()
 if resolver==null or not checked(wrapper):return failure("갤러리에 연결하지 못했어요")
 var values_class=wrapper.wrap("android.content.ContentValues")
 var media=wrapper.wrap("android.provider.MediaStore$Images$Media")
 if values_class==null or media==null or not checked(wrapper):return failure("갤러리 저장 기능에 연결하지 못했어요")
 var values=values_class.ContentValues()
 # String overload avoids primitive/boxed Integer ambiguity in JNI reflection.
 for pair in [["_display_name",filename],["mime_type","image/png"],["relative_path","Pictures/NakshiWorld"],["is_pending","1"]]:
  values.put(pair[0],pair[1])
  if not checked(wrapper):return failure("사진 정보를 만들지 못했어요")
 var uri=resolver.insert(media.EXTERNAL_CONTENT_URI,values)
 var inserted_ok:=checked(wrapper)
 if uri==null or not inserted_ok:return failure("갤러리에 사진을 만들지 못했어요")
 var stream=resolver.openOutputStream(uri,"w")
 var stream_ok:=checked(wrapper)
 if stream==null or not stream_ok:
  resolver.delete(uri,"",PackedStringArray());checked(wrapper)
  return failure("사진 저장 공간을 열지 못했어요")
 stream.write(data)
 var success:=checked(wrapper)
 if success:stream.flush();success=checked(wrapper)
 stream.close();success=checked(wrapper) and success
 # Verify the actual newly written file before making it visible in the gallery.
 # Godot 4.4 rejects NIL for Java String and String[] arguments; use explicit
 # empty selection/arguments for update/delete, even though Android permits null.
 if success:
  var descriptor=resolver.openFileDescriptor(uri,"r")
  var opened:=checked(wrapper)
  success=descriptor!=null and opened
  if success:
   var stored_size=descriptor.getStatSize()
   success=checked(wrapper) and int(stored_size)==data.size()
   descriptor.close();success=checked(wrapper) and success
 if success:
  values.clear();values.put("is_pending","0")
  success=checked(wrapper)
  if success:
   var updated=resolver.update(uri,values,"",PackedStringArray())
   success=checked(wrapper) and int(updated)>0
 if not success:
  resolver.delete(uri,"",PackedStringArray());checked(wrapper)
  return failure("사진을 저장하지 못했어요. 다시 시도해 주세요")
 return {"ok":true,"message":"갤러리에 저장했어요"}
func save(image: Image, filename: String, directory: String="") -> Dictionary:
 last_error=""
 if image==null or image.is_empty():return failure("사진을 만들지 못했어요")
 var data:=image.save_png_to_buffer()
 if data.is_empty():return failure("사진 파일을 만들지 못했어요")
 if OS.get_name()=="Android":
  if not Engine.has_singleton("AndroidRuntime") or not Engine.has_singleton("JavaClassWrapper"):
   return failure("이 앱에서는 갤러리 연결을 사용할 수 없어요")
  return android_save(data,filename,Engine.get_singleton("JavaClassWrapper"),Engine.get_singleton("AndroidRuntime"))
 # Desktop export used by editors/tests; never call it an Android gallery success.
 var folder:=directory if not directory.is_empty() else OS.get_system_dir(OS.SYSTEM_DIR_PICTURES).path_join("NakshiWorld")
 if folder.is_empty() or DirAccess.make_dir_recursive_absolute(folder)!=OK:return failure("사진 폴더를 만들지 못했어요")
 var path:=folder.path_join(filename)
 var file:=FileAccess.open(path,FileAccess.WRITE)
 if file==null:return failure("사진 파일을 저장하지 못했어요")
 file.store_buffer(data);file.flush()
 var ok:=file.get_error()==OK
 file.close()
 if not ok:DirAccess.remove_absolute(path);return failure("사진을 끝까지 저장하지 못했어요")
 return {"ok":true,"message":"사진 폴더에 저장했어요","path":path}
