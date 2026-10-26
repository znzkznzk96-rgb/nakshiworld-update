from pathlib import Path
import subprocess,numpy as np,wave,json,hashlib
out=Path('fix65-repo/game/sfx/refresh65');out.mkdir(parents=True,exist_ok=True)
def convert(src,name,filters='anull',loop=False):
 subprocess.run(['ffmpeg','-v','error','-y','-i',str(src),'-af',filters,'-ar','44100','-ac','1','-c:a','libvorbis','-q:a','4',str(out/(name+'.ogg'))],check=True)
for n,src,f in [('water','water.wav','highpass=f=100,afade=t=out:st=0.25:d=0.1'),('swim','swim.wav','highpass=f=90'),('bubbles','bubbles.wav','highpass=f=100'),('splash','waterReentry.wav','highpass=f=70'),('rain','rain.wav','highpass=f=90'),('music','ancient_mysteries.ogg','anull')]:convert(Path('audio65')/src,n,f)
for name,src in {'click':'click_002','hook':'select_002','catch':'maximize_003','record':'maximize_006','snap':'error_003','hammer':'click_002','reel':'scroll_003'}.items():convert(Path('audio65/ui/Audio')/(src+'.ogg'),name)
# Original procedural accents, not represented as recorded audio.
sr=44100;rng=np.random.default_rng(6501)
def wav(x,name):
 x=x/(max(abs(x)) or 1)*.7
 with wave.open(str(Path('audio65')/(name+'.wav')),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(sr);w.writeframes((x*32767).astype('<i2').tobytes())
 convert(Path('audio65')/(name+'.wav'),name)
t=np.arange(int(sr*3.5))/sr;n=rng.normal(0,1,len(t));rumble=np.convolve(n,np.ones(180)/180,'same');crack=n*np.exp(-t*40)*.12
wav((rumble*(1-np.exp(-t*35))*np.exp(-t*1.1)+crack)*np.minimum(1,(3.5-t)*5),'thunder')
t=np.arange(int(sr*.45))/sr;phase=2*np.pi*(220*t+90*t*t);wav((np.sin(phase)+.22*np.sin(phase*2.03))*np.exp(-t*9)*(1-np.exp(-t*120)),'tension')
t=np.arange(int(sr*.35))/sr;n=rng.normal(0,1,len(t));wav(np.convolve(n,np.ones(16)/16,'same')*np.sin(np.pi*t/.35)**2,'cast')
entries=[]
for p in out.glob('*.ogg'):entries.append(dict(file=p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),size=p.stat().st_size))
(out/'manifest.json').write_text(json.dumps(entries,indent=2)+'\n')
(out/'CREDITS.txt').write_text('''Audio refresh 0.65\nwater/swim/bubbles/splash: jcpmcdonald, Skippy Fish Water Sound Collection, CC0\nhttps://opengameart.org/content/skippy-fish-water-sound-collection\nrain: alxl, Rain on Window Loop, CC0 option\nhttps://opengameart.org/content/rain-on-window-loop\nmusic: Sperry Lion, LLC 2024, Ancient Mysteries (loop version), CC0\nhttps://opengameart.org/content/ancient-mysteries\nclick/hook/catch/record/snap/hammer/reel: Kenney Interface Sounds, CC0\nhttps://kenney.nl/assets/interface-sounds\ncast/tension/thunder: original deterministic procedural synthesis for this project; not field recordings.\nProcessing: mono 44.1kHz Vorbis; water high-pass and fade. Original music arrangement preserved.\nCC0: https://creativecommons.org/publicdomain/zero/1.0/\nExisting drag_recording.ogg unchanged.\n''')
print(len(entries),'audio files prepared')
