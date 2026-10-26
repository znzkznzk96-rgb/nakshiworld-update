"""Original short tonal air-swish; no white noise/static. Deterministic."""
from pathlib import Path
import numpy as np, wave,subprocess,hashlib,json
out=Path(__file__).resolve().parents[1]/'game/sfx/refine68';out.mkdir(exist_ok=True)
sr=44100;t=np.arange(int(sr*.23))/sr
# Soft descending whistle with detuned partials, smooth attack/release.
f=1700*np.exp(-t*8)+260;phase=2*np.pi*np.cumsum(f)/sr
x=(np.sin(phase)+.22*np.sin(phase*1.021)+.12*np.sin(phase*2.0))
envelope=np.sin(np.pi*t/t[-1])**2
x=x*envelope;x=x/max(abs(x))*.55
wav=out/'cast.wav'
with wave.open(str(wav),'wb') as w:
 w.setnchannels(1);w.setsampwidth(2);w.setframerate(sr);w.writeframes((x*32767).astype('<i2').tobytes())
subprocess.run(['ffmpeg','-v','error','-y','-i',str(wav),'-c:a','libvorbis','-q:a','5',str(out/'cast.ogg')],check=True);wav.unlink()
(out/'CREDITS.txt').write_text('Original deterministic synthesized air swish for Nakshiworld. No sampled recordings. Generator: automation/build_cast68.py. 44.1 kHz mono, 230 ms.\n')
(out/'manifest.json').write_text(json.dumps({'file':'cast.ogg','sha256':hashlib.sha256((out/'cast.ogg').read_bytes()).hexdigest(),'duration_seconds':.23,'peak_before_encoding':.55},indent=2)+'\n')
