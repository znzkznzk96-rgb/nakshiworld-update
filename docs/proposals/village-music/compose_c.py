"""Original 6/8 village sketch C. No sampled or transcribed reference material."""
from pathlib import Path
import numpy as np
from scipy.io.wavfile import write
from scipy.signal import butter, sosfilt
import subprocess, json

SR = 44100
EIGHTH = 60 / 68 / 3
BARS = 24
DURATION = BARS * 6 * EIGHTH + 3
rng = np.random.default_rng(741)
mix = np.zeros((int(DURATION * SR), 2))

def note(pitch, start, duration, volume, kind, pan=0):
    t = np.arange(int((duration + 1.7) * SR)) / SR
    f = 440 * 2 ** ((pitch - 69) / 12)
    if kind in ('harp', 'lead'):
        # A plucked attack and a mellow wooden decay, rather than a held sine lead.
        decay = 1.9 if kind == 'harp' else 1.05
        y = sum(np.sin(2*np.pi*f*k*t) * np.exp(-t*(decay+k*.38)) / k**1.9 for k in range(1, 7))
        env = (1-np.exp(-t*280)) * np.exp(-np.maximum(t-duration,0)*5)
    elif kind == 'air':
        phase = 2*np.pi*f*t + .10*np.sin(2*np.pi*4.5*t)*np.minimum(t/.4,1)
        y = np.sin(phase) + .23*np.sin(phase*2) + .05*np.sin(phase*3)
        env = np.minimum(t/.055,1)*np.minimum(np.maximum((duration+.15-t)/.22,0),1)
    elif kind == 'strings':
        y = sum(np.sin(2*np.pi*f*(1+detune)*t + j*.7) / (j+2) for j,detune in enumerate([-.002,0,.0025]))
        y += .10*np.sin(4*np.pi*f*t)
        env = np.minimum(t/.45,1)*np.minimum(np.maximum((duration+.5-t)/.65,0),1)
    else:
        y = np.sin(2*np.pi*f*t) + .12*np.sin(4*np.pi*f*t)
        env = (1-np.exp(-t*60))*np.exp(-t*1.3)*np.minimum(np.maximum((duration+.2-t)/.3,0),1)
    y *= env*volume
    i = round(start*SR); n = min(len(y), len(mix)-i)
    if n > 0:
        mix[i:i+n,0] += y[:n]*np.sqrt((1-pan)/2)
        mix[i:i+n,1] += y[:n]*np.sqrt((1+pan)/2)

# Three eight-bar phrases: invitation, lifted answer, quiet return.
chords = [
 [50,62,66,69,76],[49,61,64,69,73],[47,62,66,69,74],[43,59,62,66,69],
 [45,61,64,69,71],[42,57,61,66,69],[43,59,62,66,71],[45,61,64,67,71],
 [47,62,66,69,74],[43,59,62,67,74],[50,62,66,69,76],[45,61,64,69,73],
 [40,59,64,67,71],[42,57,61,66,73],[43,59,62,66,69],[45,61,64,69,71],
 [50,62,66,69,76],[49,61,64,69,73],[47,62,66,69,74],[43,59,62,66,69],
 [40,59,64,67,71],[45,61,64,67,71],[43,59,62,66,69],[50,62,66,69,74]]
# Own melody, eighth-note positions. Rests and anacrusis keep short visits musical.
melody = [
 [(78,0,2),(76,2,1),(73,3,2),(74,5,1)],[(76,0,3),(73,4,1),(69,5,1)],
 [(74,0,2),(78,2,1),(81,3,2)],[(79,0,2),(78,2,1),(74,3,2)],
 [(76,0,1),(73,1,2),(71,3,2),(73,5,1)],[(73,0,3),(69,4,1),(73,5,1)],
 [(74,0,2),(78,2,1),(76,3,2),(74,5,1)],[(73,0,3),(71,4,1)],
 [(78,0,2),(81,2,1),(83,3,2)],[(81,0,2),(79,2,1),(78,3,2)],
 [(81,0,1),(78,1,1),(76,2,1),(78,3,2),(81,5,1)],[(80,0,2),(76,2,1),(73,3,2)],
 [(79,0,2),(78,2,1),(76,3,1),(74,4,2)],[(78,0,3),(76,4,1),(73,5,1)],
 [(74,0,2),(71,2,1),(74,3,2),(78,5,1)],[(76,0,3),(73,4,1)],
 [(78,0,2),(76,2,1),(73,3,2),(74,5,1)],[(76,0,3),(73,4,1),(69,5,1)],
 [(74,0,2),(78,2,1),(76,3,2)],[(74,0,3),(71,4,1),(69,5,1)],
 [(71,0,2),(74,2,1),(76,3,2)],[(73,0,2),(71,2,1),(69,3,2)],
 [(71,0,2),(74,2,1),(78,3,2),(76,5,1)],[(74,0,5)]]
for bar,(ch,mel) in enumerate(zip(chords,melody)):
    at = bar*6*EIGHTH
    for k,idx in enumerate([1,2,3,2,4,3]):
        note(ch[idx],at+k*EIGHTH,.85*EIGHTH,.071*(1 if k%3==0 else .8),'harp',-.36)
    note(ch[0],at,2.6*EIGHTH,.065,'bass',-.05)
    note(ch[0]+7,at+3*EIGHTH,2.3*EIGHTH,.033,'bass',.05)
    for p in ch[1:4]:
        note(p,at,5.6*EIGHTH,.014 if bar<8 else .020,'strings',.22)
    for p,pos,length in mel:
        note(p,at+pos*EIGHTH+.012,length*EIGHTH,.13,'lead',.08)
    # Brief high woodwind answers only; no continuous low flute.
    if bar in [3,7,11,15,19]:
        for j,p in enumerate([ch[3]+12,ch[2]+12]):
            note(p,at+(4+j)*EIGHTH,.75*EIGHTH,.026,'air',.40)

dry = mix.copy()
for delay,gain in [(.061,.10),(.113,.08),(.181,.07),(.277,.055),(.419,.04),(.613,.025),(.823,.015)]:
    n = int(delay*SR); mix[n:] += dry[:-n,::-1]*gain
mix = sosfilt(butter(2,7000,fs=SR,output='sos'),mix,axis=0)
mix[-int(1.5*SR):] *= np.linspace(1,0,int(1.5*SR))[:,None]
mix *= .78/np.max(np.abs(mix))
out = Path(__file__).parent
wav = out/'preview_c.wav'
write(wav,SR,(mix*32767).astype(np.int16))
mp3 = out.parent/'NAKSHIWORLD_VILLAGE_BGM_C.mp3'
subprocess.run(['ffmpeg','-y','-v','error','-i',str(wav),'-c:a','libmp3lame','-b:a','192k',str(mp3)],check=True)
subprocess.run(['ffmpeg','-v','error','-i',str(mp3),'-f','null','-'],check=True)
(out/'QA_C.json').write_text(json.dumps({'seconds':DURATION,'meter':'6/8','dotted_quarter_bpm':68,'peak':float(abs(mix).max()),'finite':bool(np.isfinite(mix).all()),'mp3_full_decode':True,'reference_audio_used':False,'original_melody':True,'auditory_user_review_pending':True,'game_applied':False,'loop_master':False},indent=2))
print('C preview encoded and decoded:',round(DURATION,2),'seconds')
