extends RefCounted
# Reconstruct the exact published PCK using verified local resources plus byte ranges.
var received:=0
var planned:=-1
var request:HTTPRequest
var index_bytes:=PackedByteArray()
var entries:Array=[]
var reused:=0
var error:=""

func parse_index(data:PackedByteArray,total:int)->Array:
 if data.size()<100 or data.slice(0,4)!=PackedByteArray([71,68,80,67]):return []
 if data.decode_u32(4)!=2 or data.decode_u32(20)!=0:return []
 var base:int=data.decode_u64(24)
 if base<100 or base>4194304 or base>total or data.size()!=base:return []
 var count:int=data.decode_u32(96)
 if count<=0 or count>20000:return []
 var pos:=100;var out:Array=[];var paths:Dictionary={};var last_end:int=base
 for i in count:
  if pos+4>data.size():return []
  var length:int=data.decode_u32(pos);pos+=4
  if length<=0 or length>4096 or pos+length+36>data.size():return []
  var raw_path:PackedByteArray=data.slice(pos,pos+length);var zero:int=raw_path.find(0)
  var path:String=raw_path.slice(0,zero if zero>=0 else raw_path.size()).get_string_from_utf8();pos+=length
  if not path.begins_with("res://"):path="res://"+path
  if not path.begins_with("res://") or ".." in path.trim_prefix("res://").split("/") or paths.has(path):return []
  paths[path]=true
  var start:int=base+data.decode_u64(pos);var size:int=data.decode_u64(pos+8)
  var digest:String=data.slice(pos+16,pos+32).hex_encode();var flags:int=data.decode_u32(pos+32);pos+=36
  if flags!=0 or size<0 or start<base or start+size>total:return []
  out.append({"path":path,"start":start,"size":size,"md5":digest})
 out.sort_custom(func(a,b):return a.start<b.start)
 for e in out:
  if int(e.start)<last_end:return []
  last_end=int(e.start)+int(e.size)
 return out

func local_index(pack:String)->Dictionary:
 var result:Dictionary={}
 if pack.is_empty() or not FileAccess.file_exists(pack):return result
 var f:=FileAccess.open(pack,FileAccess.READ)
 if f==null:return result
 var h:=f.get_buffer(100)
 if h.size()!=100:return result
 var base:int=h.decode_u64(24)
 if base<100 or base>4194304:return result
 f.seek(0)
 for e in parse_index(f.get_buffer(base),f.get_length()):result[e.path]=e
 return result

func local_bytes(e:Dictionary,installed:String,old:Dictionary)->PackedByteArray:
 if old.has(e.path):
  var previous:Dictionary=old[e.path]
  if previous.md5==e.md5 and previous.size==e.size:
   var f:=FileAccess.open(installed,FileAccess.READ)
   if f:
    f.seek(previous.start);var b:=f.get_buffer(previous.size)
    if b.size()==e.size and md5(b)==e.md5:return b
 if FileAccess.file_exists(e.path):
  var b:=FileAccess.get_file_as_bytes(e.path)
  if b.size()==e.size and md5(b)==e.md5:return b
 return PackedByteArray()

func range_header(headers:PackedStringArray)->String:
 for h in headers:
  if h.to_lower().begins_with("content-range:"):return h.split(":",true,1)[1].strip_edges().to_lower()
 return ""

func fetch_range(url:String,start:int,length:int,total:int)->PackedByteArray:
 request.body_size_limit=length
 request.download_file=""
 var result:int=request.request(url,PackedStringArray(["Range: bytes=%d-%d"%[start,start+length-1],"Accept-Encoding: identity"]))
 if result!=OK:error="request";return PackedByteArray()
 var response:Array=await request.request_completed
 var data:PackedByteArray=response[3]
 if response[0]!=HTTPRequest.RESULT_SUCCESS or response[1]!=206 or data.size()!=length or range_header(response[2])!="bytes %d-%d/%d"%[start,start+length-1,total]:
  error="range_response result=%s code=%s bytes=%s header=%s"%[response[0],response[1],data.size(),range_header(response[2])];return PackedByteArray()
 received+=data.size()
 return data

func snapshot()->Dictionary:
 var in_flight:int=maxi(0,request.get_downloaded_bytes()) if request and request.get_http_client_status()!=HTTPClient.STATUS_DISCONNECTED else 0
 # completed requests can retain the previous byte counter; only count while receiving.
 if request and request.get_http_client_status()!=HTTPClient.STATUS_BODY:in_flight=0
 var count:int=received+in_flight
 return {"received":count,"total":planned,"progress":clampf(float(count)/planned,0,1) if planned>0 else -1.0}

func download(owner:Node,url:String,total:int,expected_sha:String,target:String,installed:String="")->bool:
 request=HTTPRequest.new();request.timeout=90;owner.add_child(request)
 var header:=await fetch_range(url,0,100,total)
 if header.size()!=100 or header.slice(0,4)!=PackedByteArray([71,68,80,67]):return finish(false)
 var base:int=header.decode_u64(24)
 if base<100 or base>4194304 or base>total:return finish(false)
 var rest:=await fetch_range(url,100,base-100,total)
 if rest.size()!=base-100:return finish(false)
 index_bytes=header+rest;entries=parse_index(index_bytes,total)
 if entries.is_empty():return finish(false)
 var old:Dictionary=local_index(installed);var cache:Dictionary={}
 planned=received
 for e in entries:
  var b:=local_bytes(e,installed,old)
  if (e.size==0 or not b.is_empty()):cache[e.path]=true;reused+=1
  else:planned+=int(e.size)
 var out:=FileAccess.open(target,FileAccess.WRITE)
 if out==null:return finish(false)
 out.store_buffer(index_bytes)
 for e in entries:
  if out.get_position()>int(e.start):out=null;return finish(false)
  if out.get_position()<int(e.start):out.store_buffer(zeros(int(e.start)-out.get_position()))
  var b:PackedByteArray
  if cache.has(e.path):b=local_bytes(e,installed,old);cache.erase(e.path)
  else:b=await fetch_range(url,int(e.start),int(e.size),total)
  if b.size()!=e.size or md5(b)!=e.md5:out=null;return finish(false)
  out.store_buffer(b)
  if out.get_error()!=OK:out=null;return finish(false)
 if out.get_position()>total:out=null;return finish(false)
 out.store_buffer(zeros(total-out.get_position()));out.flush();out=null
 return finish(FileAccess.get_sha256(target)==expected_sha)

func zeros(count:int)->PackedByteArray:
 var data:=PackedByteArray();data.resize(count);data.fill(0);return data
func finish(ok:bool)->bool:
 if request:request.queue_free();request=null
 return ok

func md5(data:PackedByteArray)->String:
 var context:=HashingContext.new();context.start(HashingContext.HASH_MD5);context.update(data);return context.finish().hex_encode()
