from http.server import BaseHTTPRequestHandler,HTTPServer
from pathlib import Path
import sys
import re,json
body=Path(sys.argv[1] if len(sys.argv)>1 else 'candidate118/patch.pck').read_bytes();stats={'requests':0,'bytes':0}
class Handler(BaseHTTPRequestHandler):
 def do_GET(self):
  if self.path=='/stats':data=json.dumps(stats).encode();self.send_response(200);self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data);return
  match=re.fullmatch(r'bytes=(\d+)-(\d+)',self.headers.get('Range',''))
  if not match:self.send_error(400);return
  a,b=map(int,match.groups());data=body[a:b+1];stats['requests']+=1;stats['bytes']+=len(data)
  self.send_response(206);self.send_header('Content-Length',str(len(data)));self.send_header('Content-Range',f'bytes {a}-{b}/{len(body)}');self.end_headers();self.wfile.write(data)
 def log_message(self,*a):pass
HTTPServer(('127.0.0.1',18765),Handler).serve_forever()
