"""Original deterministic modal synthesis: chain links and a heavy metal latch.
No external recording, paid generation, or third-party sample is used.
"""
import json, hashlib, wave
from pathlib import Path
import numpy as np
from scipy.signal import butter, sosfilt
RATE=44100
rng=np.random.default_rng(1132026)
def strike(length, pitch=1., weight=1.):
 t=np.arange(int(length*RATE))/RATE
 modes=[(670,.07,.26),(1137,.10,.34),(1823,.13,.26),(2681,.08,.19),(3727,.06,.14),(5311,.035,.08)]
 out=np.zeros(len(t))
 for freq,decay,gain in modes:
  out+=gain*np.sin(2*np.pi*freq*pitch*t+rng.uniform(-.2,.2))*np.exp(-t/decay)
 noise=sosfilt(butter(2,[1100,12500],btype='bandpass',fs=RATE,output='sos'),rng.normal(0,1,len(t)))
 out+=noise*.45*np.exp(-t/.006)
 out+=.25*weight*np.sin(2*np.pi*170*t)*np.exp(-t/.022)
 return out*(1-np.exp(-t/.00035))
def add(dst,clip,at,level,pan=0):
 start=round(at*RATE);count=min(len(clip),len(dst)-start)
 if count<1:return
 dst[start:start+count,0]+=clip[:count]*level*np.sqrt((1-pan)/2)
 dst[start:start+count,1]+=clip[:count]*level*np.sqrt((1+pan)/2)
def make(name,length,events):
 out=np.zeros((round(length*RATE),2))
 for at,pitch,level,pan in events:add(out,strike(.27,pitch),at,level,pan)
 # A short room tail makes the metal dry and tangible, without a fantasy chime.
 delay=round(.013*RATE);out[delay:]+=out[:-delay]*.055
 out=np.tanh(out*1.15)
 peak=np.max(np.abs(out));out*=.84/max(peak,.001)
 fade=min(round(.035*RATE),len(out));out[-fade:]*=np.linspace(1,0,fade)[:,None]
 out[:100]*=np.linspace(0,1,100)[:,None]
 path=dest/(name+'.wav')
 with wave.open(str(path),'wb') as wav:
  wav.setnchannels(2);wav.setsampwidth(2);wav.setframerate(RATE);wav.writeframes((out*32767).astype('<i2').tobytes())
 return {'file':path.name,'duration':length,'peak':float(np.max(np.abs(out))),'rms':float(np.sqrt(np.mean(out*out))),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
if __name__=='__main__':
 import sys
 dest=Path(sys.argv[1]);dest.mkdir(parents=True,exist_ok=True)
 results=[]
 results.append(make('unlock_chain_pull',.48,[(0,.85,.40,-.35),(.04,1.12,.32,.2),(.095,.91,.5,-.2),(.135,1.21,.24,.4),(.19,.79,.65,-.3),(.24,1.02,.48,.2),(.285,.84,.7,0)]))
 # Two mechanical contacts: latch releases, then the shackle hits its stop.
 results.append(make('unlock_latch',.34,[(0,.59,.9,0),(.023,1.5,.27,0),(.073,.73,1.15,0),(.083,1.19,.3,0)]))
 results.append(make('unlock_chain_release',.62,[(0,.76,.8,-.45),(.014,.88,.78,.45),(.04,1.31,.4,-.5),(.068,1.06,.45,.5),(.10,.94,.44,-.5),(.145,1.26,.3,.6),(.19,.82,.37,-.55),(.25,1.09,.23,.5),(.32,1.37,.16,-.5),(.39,.91,.11,.4)]))
 (dest/'manifest.json').write_text(json.dumps({'origin':'original deterministic modal synthesis','license':'project original; no third-party samples','generator':'automation/audio/generate_unlock.py','rate':RATE,'channels':2,'bits':16,'assets':results},indent=2)+'\n')
 print(json.dumps(results,indent=2))
