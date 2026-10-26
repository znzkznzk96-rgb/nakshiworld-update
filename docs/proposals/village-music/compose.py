"""Original preview composition; no reference recording samples or transcription."""
import numpy as np
from scipy.signal import butter,sosfilt
from scipy.io.wavfile import write
from pathlib import Path
import subprocess,json
sr=44100;beat=60/76;bars=12;dur=bars*4*beat+3
mix=np.zeros((int(dur*sr),2),np.float64);rng=np.random.default_rng(274)
def note(midi,start,length,vol,kind,pan=0):
 f=440*2**((midi-69)/12);t=np.arange(int((length+1.1)*sr))/sr
 if kind=='piano':
  y=sum((1/k**1.7)*np.sin(2*np.pi*f*k*(1+0.00015*k*k)*t)*np.exp(-t*(1.1+k*.28)) for k in range(1,7))
  env=(1-np.exp(-t*160))*np.exp(-np.maximum(t-length,0)*8)
 elif kind=='flute':
  phase=2*np.pi*f*t+0.012*f/440*np.sin(2*np.pi*4.7*t)*np.minimum(t/.35,1)
  y=np.sin(phase)+.16*np.sin(2*phase)+.055*np.sin(3*phase)
  breath=sosfilt(butter(2,[700,3300],fs=sr,btype='bandpass',output='sos'),rng.normal(0,1,len(t)))
  y+=.022*breath
  env=np.minimum(t/.065,1)*np.minimum(np.maximum((length+.18-t)/.24,0),1)*(.96+.04*np.sin(t*3.7))
 elif kind=='pad':
  y=(np.sin(2*np.pi*f*t)+.3*np.sin(2*np.pi*f*1.002*t)+.15*np.sin(2*np.pi*f*2*t))/1.45
  env=np.minimum(t/.6,1)*np.minimum(np.maximum((length+.7-t)/.9,0),1)
 else:
  y=np.sin(2*np.pi*f*t)+.17*np.sin(2*np.pi*f*2*t)
  env=(1-np.exp(-t*35))*np.exp(-t*.5)*np.minimum(np.maximum((length+.3-t)/.5,0),1)
 y=y*env*vol;i=int(start*sr);n=min(len(y),len(mix)-i)
 if n>0:mix[i:i+n,0]+=y[:n]*np.sqrt((1-pan)/2);mix[i:i+n,1]+=y[:n]*np.sqrt((1+pan)/2)
# Gmaj9, D/F#, Em9, Cmaj7, Am7, Dsus, Bm7, Cmaj9, Em7, Am9, Dsus/D, G6.
chords=[[55,62,66,69],[54,62,66,69],[52,59,62,66],[48,55,59,64],[45,55,60,64],[50,57,62,67],[47,54,57,62],[48,55,59,62],[52,59,62,67],[45,52,55,59],[50,57,62,66],[43,55,59,64]]
mel=[[(71,0,1),(69,1.5,.5),(66,2,1.5)],[(64,0,1.5),(66,2,.5),(69,3,.8)],[(67,0,1.5),(66,2,.6),(62,3,.8)],[(64,0,2),(62,2.5,.5),(59,3,.8)],[(60,0,1),(64,1.5,.5),(67,2,1.6)],[(69,0,1.3),(67,1.5,.5),(66,2.5,.5),(64,3,.8)],[(66,0,1),(69,1.5,.5),(74,2,1.6)],[(71,0,1.7),(67,2,.7),(64,3,.8)],[(66,0,.8),(67,1,.8),(71,2,1.5)],[(69,0,1.5),(64,2,1.5)],[(67,0,1),(66,1.5,.6),(62,2.5,1)],[(59,0,1),(62,1.5,.5),(67,2,1.8)]]
for bar,ch in enumerate(chords):
 at=bar*4*beat
 note(ch[0]-12 if ch[0]>50 else ch[0],at,3.4*beat,.10,'bass',-.08)
 for pitch in ch[1:]:note(pitch,at,3.75*beat,.025,'pad',.25)
 for k,idx in enumerate([1,2,3,2,1,3,2,1]):
  note(ch[idx],at+k*.5*beat+float(rng.uniform(0,.012)),.65*beat,.082*(.88 if k%2 else 1),'piano',-.30)
 for pitch,pos,ln in mel[bar]:note(pitch,at+pos*beat+.025,ln*beat,.13,'flute',.12)
 if bar in [3,7,11]:note(ch[2]+12,at+2.5*beat,1.4*beat,.035,'piano',.45)
# Stereo early reflections and diffuse decaying tail.
dry=mix.copy()
for delay,gain in [(.079,.12),(.131,.09),(.223,.075),(.347,.06),(.487,.045),(.673,.03),(.887,.02)]:
 n=int(delay*sr);mix[n:]+=dry[:-n,::-1]*gain
mix=sosfilt(butter(2,6500,fs=sr,output='sos'),mix,axis=0)
mix[:int(.015*sr)]*=np.linspace(0,1,int(.015*sr))[:,None]
mix[-int(1.2*sr):]*=np.linspace(1,0,int(1.2*sr))[:,None]
peak=np.max(abs(mix));mix*=.82/peak
p=Path(__file__).parent
write(p/'preview.wav',sr,(mix*32767).astype(np.int16))
subprocess.run(['ffmpeg','-y','-v','error','-i',str(p/'preview.wav'),'-c:a','libmp3lame','-b:a','192k',str(p.parent/'NAKSHIWORLD_VILLAGE_BGM_A.mp3')],check=True)
(p/'QA.json').write_text(json.dumps({'duration_seconds':dur,'bpm':76,'peak':float(abs(mix).max()),'finite':bool(np.isfinite(mix).all()),'reference_samples_used':False,'original_composition':True,'preview_only':True,'game_applied':False},indent=2))
print('CREATED',round(dur,2),'seconds; stereo; no clipping')
