from pathlib import Path
from scipy.io.wavfile import read,write
import numpy as np, subprocess,json,hashlib
root=Path(__file__).resolve().parents[1]
sr,pcm=read(root/'village-music/preview_d.wav')
audio=pcm.astype(np.float64)/32768
n=round(27*sr)
loop=audio[:n].copy()
tail=audio[n:]
loop[:len(tail)]+=tail
loop*=.78/np.max(abs(loop))
wav=root/'release075/village_d_loop.wav'
write(wav,sr,(loop*32767).astype(np.int16))
out=root/'project/sfx/village/village.ogg'
subprocess.run(['ffmpeg','-v','error','-y','-i',str(wav),'-c:a','libvorbis','-q:a','2',str(out)],check=True)
subprocess.run(['ffmpeg','-v','error','-i',str(out),'-f','null','-'],check=True)
report={'source':'original D 3/4 80BPM','loop_seconds':27,'musical_bars':12,'tail_folded':True,'pcm_seam_delta':float(np.max(abs(loop[0]-loop[-1]))),'peak':float(abs(loop).max()),'decode_pass':True,'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'size':out.stat().st_size}
(root/'release075/MUSIC_QA.json').write_text(json.dumps(report,indent=2))
p=root/'project/sfx/village/manifest.json';entries=json.loads(p.read_text())
for item in entries:
 if item['file']=='village.ogg':item.update(sha256=report['sha256'],size=report['size'])
p.write_text(json.dumps(entries,indent=2)+'\n')
p=root/'project/sfx/village/CREDITS.txt';p.write_text(p.read_text()+'\n0.75 replacement village.ogg: original synthesized composition D, 3/4 80 BPM. No reference samples or transcribed melody. Guitar/flute/pad/harp synthesis, 27s musical loop with reverb tail folded into start.\n')
print(json.dumps(report))
