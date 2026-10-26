"""Original 3/4 Celtic-folk village sketch D. No sampled or transcribed reference material."""
from pathlib import Path
import numpy as np
from scipy.io.wavfile import write
from scipy.signal import butter, sosfilt
import subprocess, json

SR = 44100
EIGHTH = 60 / 80 / 2
BARS = 12
DURATION = BARS * 6 * EIGHTH + 3
rng = np.random.default_rng(741)
mix = np.zeros((int(DURATION * SR), 2))

def note(pitch, start, duration, volume, kind, pan=0):
    t = np.arange(int((duration + 1.7) * SR)) / SR
    f = 440 * 2 ** ((pitch - 69) / 12)
    if kind in ('harp', 'guitar'):
        # A plucked attack and a mellow wooden decay, rather than a held sine lead.
        decay = 1.2 if kind == 'harp' else 1.8
        y = sum(np.sin(2*np.pi*f*k*t) * np.exp(-t*(decay+k*.38)) / k**(1.6 if kind == 'guitar' else 2.0) for k in range(1, 7))
        env = (1-np.exp(-t*280)) * np.exp(-np.maximum(t-duration,0)*5)
    elif kind == 'air':
        phase = 2*np.pi*f*t + .10*np.sin(2*np.pi*4.5*t)*np.minimum(t/.4,1)
        y = np.sin(phase) + .30*np.sin(phase*2) + .085*np.sin(phase*3)
        breath = sosfilt(butter(2,[900,4200],fs=SR,btype='bandpass',output='sos'),rng.normal(0,1,len(t)))
        y += .025*breath
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

# Own 12-bar melody: a wistful question, rising answer, pastoral major resolution.
chords = [[52,59,64,67],[48,55,62,64],[55,59,62,69],[50,57,62,66],
          [45,57,60,64],[52,59,64,67],[48,55,59,64],[47,54,62,66],
          [52,59,64,67],[48,55,62,64],[50,57,62,67],[43,55,59,62]]
melody = [
 [(76,0,1.5),(79,2,1),(78,3,1),(76,4,1.7)],
 [(74,0,2.5),(76,3,1),(79,4,1.5)],
 [(81,0,1.5),(79,2,1),(78,3,1.5),(74,5,.7)],
 [(76,0,1.5),(74,2,2.6)],
 [(76,0,1),(81,1.5,2),(79,4,1.5)],
 [(78,0,1),(76,1.5,1),(74,3,1),(76,4.5,1)],
 [(79,0,2),(76,2.5,1),(74,4,1.5)],
 [(78,0,2.4),(74,3.5,1.7)],
 [(76,0,1.5),(79,2,1),(83,3,1.5),(81,5,.7)],
 [(79,0,2),(76,2.5,1),(74,4,1.7)],
 [(78,0,1),(76,1.5,1),(74,3,2.3)],
 [(71,0,1),(74,1.5,1),(79,3,2.7)]]
for bar,(ch,mel) in enumerate(zip(chords,melody)):
    at = bar * 6 * EIGHTH
    # Bass, then alternating middle/high nylon strings: three clear quarter beats.
    for k,idx in enumerate([0,2,1,3,2,1]):
        note(ch[idx],at+k*EIGHTH,.95*EIGHTH,.09*(1 if k%2==0 else .74),'guitar',-.3)
    for p in ch[1:]:
        note(p,at,5.6*EIGHTH,.015,'strings',.18)
    for p,pos,length in mel:
        note(p,at+pos*EIGHTH+.018,length*EIGHTH,.105,'air',.06)
    if bar in [1,3,5,7,9,11]:
        for j,p in enumerate([ch[1]+12,ch[2]+12,ch[3]+12]):
            note(p,at+(3+j)*EIGHTH,.9*EIGHTH,.042,'harp',.45)

dry=mix.copy()
for delay,gain in [(.057,.10),(.109,.08),(.197,.065),(.311,.05),(.433,.038),(.619,.025),(.853,.015)]:
    n=int(delay*SR);mix[n:]+=dry[:-n,::-1]*gain
mix=sosfilt(butter(2,6800,fs=SR,output='sos'),mix,axis=0)
mix[-int(1.8*SR):]*=np.linspace(1,0,int(1.8*SR))[:,None]
mix*=.78/np.max(np.abs(mix))
out=Path(__file__).parent
wav=out/'preview_d.wav'
write(wav,SR,(mix*32767).astype(np.int16))
mp3=out.parent/'NAKSHIWORLD_VILLAGE_BGM_D.mp3'
subprocess.run(['ffmpeg','-y','-v','error','-i',str(wav),'-c:a','libmp3lame','-b:a','192k',str(mp3)],check=True)
subprocess.run(['ffmpeg','-v','error','-i',str(mp3),'-f','null','-'],check=True)
(out/'QA_D.json').write_text(json.dumps({'seconds':DURATION,'meter':'3/4','quarter_bpm':80,'peak':float(abs(mix).max()),'finite':bool(np.isfinite(mix).all()),'mp3_full_decode':True,'reference_audio_used':False,'original_melody':True,'instruments':['synthesized nylon guitar','breathy flute','warm pads','harp'],'auditory_user_review_pending':True,'game_applied':False,'loop_master':False},indent=2))
print('D: 3/4, 80 BPM,',DURATION,'seconds; MP3 full decode PASS')

