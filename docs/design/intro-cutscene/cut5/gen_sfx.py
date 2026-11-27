# 컷5 효과음 합성. python3 gen_sfx.py → proj/snd/*.wav
import numpy as np, wave, os
SR=44100; out=os.path.join(os.path.dirname(os.path.abspath(__file__)),'proj','snd')
rng=np.random.default_rng(31)
def save(name,x):
    x=np.clip(x,-1,1); w=wave.open(os.path.join(out,name),'wb'); w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((x*32000).astype('<i2').tobytes()); w.close()
def tt(d): return np.arange(int(SR*d))/SR
def lp(n,c):
    y=np.zeros(len(n)); s=0.0; a=1-np.exp(-2*np.pi*c/SR)
    for i in range(len(n)): s+=a*(n[i]-s); y[i]=s
    return y
# 밤바람: 낮게 일렁이는 바람(6.5초)
t=tt(6.5); y=lp(rng.standard_normal(len(t)),500)
x=y*4.0*(0.6+0.4*np.sin(2*np.pi*0.35*t))*np.minimum(1,t/0.8)*np.minimum(1,(6.5-t)/0.8)
save('wind.wav',x*0.5)
# 로고 등장: 맑은 종소리 아르페지오
t=tt(2.6); x=np.zeros(len(t))
for k,(f,d) in enumerate([(523.25,0.0),(659.25,0.12),(783.99,0.24),(1046.5,0.38)]):
    tk=np.maximum(t-d,0); on=(t>=d)
    x+=on*(np.sin(2*np.pi*f*tk)+0.35*np.sin(2*np.pi*2*f*tk)+0.12*np.sin(2*np.pi*3.01*f*tk))*np.exp(-tk*2.2)*0.22
save('chime.wav',x)
print('ok')
