import sys,json,time,base64;sys.path.insert(0,'/tmp/cut1');from gen import *
fr={"type":"base64","base64":b64('/tmp/cut1/out/researcher_xl_clean.png')}
r=curl('POST','https://api.pixellab.ai/v2/animate-with-text-v3',{"first_frame":fr,"last_frame":fr,"action":"standing still, slowly turns her head up to look far down the corridor, then turns her head to the left, then to the right, looking around cautiously, body and feet stay in place, then returns to the starting pose","frame_count":8,"no_background":True,"seed":77})
open('/tmp/cut1/out/look.job','w').write(json.dumps(r));print(r.get('background_job_id'), r if not r.get('background_job_id') else '')
