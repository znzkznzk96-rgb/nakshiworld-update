const REPO = "https://github.com/znzkznzk96-rgb/nakshiworld-update";
const CORS = {"Access-Control-Allow-Origin":"*","Access-Control-Allow-Methods":"GET, HEAD, OPTIONS","Access-Control-Allow-Headers":"Range, If-None-Match","Access-Control-Expose-Headers":"Content-Length, ETag, Content-Range, X-Patch-Source"};
function reply(text,status=200,extra={}) { return new Response(text,{status,headers:{...CORS,"Cache-Control":"no-store",...extra}}); }
async function manifest() {
  const r=await fetch(REPO+"/releases/latest/download/version.json",{redirect:"follow",headers:{"User-Agent":"nakshiworld-updater","Cache-Control":"no-cache"},cf:{cacheTtl:0},signal:AbortSignal.timeout(5000)});
  if(!r.ok) throw new Error("Manifest unavailable: "+r.status);
  const reader=r.body.getReader();let bytes=0;const parts=[];
  while(true){const {done,value}=await reader.read();if(done)break;bytes+=value.length;if(bytes>16384){await reader.cancel();throw new Error("Oversize manifest");}parts.push(value);}
  const data=new Uint8Array(bytes);let offset=0;for(const p of parts){data.set(p,offset);offset+=p.length;}
  const d=JSON.parse(new TextDecoder().decode(data));
  if(!Number.isSafeInteger(d.code)||d.code<=60||!/^\d+\.\d+(?:\.\d+)?$/.test(d.name)||!Number.isSafeInteger(d.size)||d.size<=0||!/^[a-f0-9]{64}$/i.test(d.sha256))throw new Error("Invalid manifest");
  return d;
}
async function fromR2(request,env,key) {
  const o=await env.GAME_PATCHES.get(key);
  if(!o)return reply("Not found",404);
  const h=new Headers({...CORS,"Cache-Control":"no-store","X-Patch-Source":"r2"});
  o.writeHttpMetadata(h);h.set("ETag",o.httpEtag);h.set("Content-Length",String(o.size));
  return new Response(request.method==="HEAD"?null:o.body,{headers:h});
}
export default {
 async fetch(request,env) {
  if(request.method==="OPTIONS")return new Response(null,{status:204,headers:CORS});
  if(!["GET","HEAD"].includes(request.method))return reply("Method not allowed",405,{Allow:"GET, HEAD, OPTIONS"});
  const url=new URL(request.url);let key;
  try{key=decodeURIComponent(url.pathname.slice(1));}catch{return reply("Invalid path",400);}
  if(!key||key.split("/").some(p=>!p||p==="."||p===".."))return reply("Invalid path",400);
  try {
   if(["version.json","latest.json","patch.pck"].includes(key)) {
    const d=await manifest();
    if(key!=="patch.pck") {
     const body=JSON.stringify(d);
     return reply(request.method==="HEAD"?null:body,200,{"Content-Type":"application/json","X-Patch-Source":"github-releases","Content-Length":String(new TextEncoder().encode(body).length)});
    }
    const requested=url.searchParams.get("v");
    if(requested!==null&&requested!==String(d.code))return reply("Version changed; restart update",409);
    const headers={"User-Agent":"nakshiworld-updater","Accept":"application/octet-stream"};
    if(request.headers.has("Range"))headers.Range=request.headers.get("Range");
    const r=await fetch(REPO+"/releases/download/v"+d.name+"/patch.pck",{method:request.method,headers,redirect:"follow",cf:{cacheTtl:0}});
    if(!r.ok)return reply("Patch temporarily unavailable",502);
    if(r.status===200&&r.headers.has("Content-Length")&&Number(r.headers.get("Content-Length"))!==d.size){if(r.body)await r.body.cancel();return reply("Patch size mismatch",502);}
    const h=new Headers(r.headers);for(const [k,v]of Object.entries(CORS))h.set(k,v);
    h.set("Cache-Control","no-store");h.set("Content-Type","application/octet-stream");h.set("X-Patch-Source","github-releases");
    return new Response(request.method==="HEAD"?null:r.body,{status:r.status,headers:h});
   }
   return await fromR2(request,env,key);
  }catch(error){
   console.error(JSON.stringify({event:"patch_origin_error",message:String(error)}));
   if(key==="patch.pck")return reply("Update unavailable; try again later",503);
   try{return await fromR2(request,env,key);}catch{return reply("Update unavailable; try again later",503);}
  }
 }
};
