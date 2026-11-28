# 컷3 효과음 합성. python3 gen_sfx.py → proj/snd/*.wav
import numpy as np, wave, os
SR=44100; out=os.path.join(os.path.dirname(os.path.abspath(__file__)),'proj','snd')
rng=np.random.default_rng(11)
def save(name,x):
    x=np.clip(x,-1,1); w=wave.open(os.path.join(out,name),'wb'); w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((x*32000).astype('<i2').tobytes()); w.close()
def tt(d): return np.arange(int(SR*d))/SR
def lp(n,cut):
    y=np.zeros(len(n)); s=0.0
    for i in range(len(n)):
        a=1-np.exp(-2*np.pi*cut[i]/SR); s+=a*(n[i]-s); y[i]=s
    return y
# 타일 금 가는 소리: 짧고 날카로운 틱 여러 개
t=tt(0.7); x=np.zeros(len(t))
for k in range(14):
    p=int(rng.random()*0.55*SR); L=int(0.02*SR); tk=np.arange(L)/SR
    x[p:p+L]+=(rng.standard_normal(L)*np.exp(-tk*220)+np.sin(2*np.pi*(1800+rng.random()*2500)*tk)*np.exp(-tk*300))*(0.3+0.5*rng.random())
save('crack.wav',x*0.8)
# 차원 열림: 올라가는 떨림음 + 반짝임 (2.0초)
t=tt(2.0); f=180*np.exp(2.2*t/2.0)+14*np.sin(2*np.pi*9*t)
ph=2*np.pi*np.cumsum(f)/SR; x=(np.sin(ph)+0.5*np.sin(2*ph)+0.3*np.sin(3.01*ph))*np.minimum(1,t/0.3)*np.minimum(1,(2.0-t)/0.15)*0.35
n0=len(x); x=np.concatenate([x,np.zeros(SR)])
for k in range(26):
    p=int((0.3+rng.random()*1.6)*SR); L=int(0.25*SR); tk=np.arange(L)/SR; fr=2500+rng.random()*3500
    x[p:p+L]+=np.sin(2*np.pi*fr*tk)*np.exp(-tk*18)*0.12
save('sweep.wav',x[:n0])
# 소용돌이: 낮게 윙 하며 돌아가는 소리 (2.0초)
t=tt(2.0); n=rng.standard_normal(len(t)); y=lp(n,300+900*np.sin(np.pi*t/2.0)**2+200*np.sin(2*np.pi*6*t))
x=y*3.0*np.minimum(1,t/0.2)*np.minimum(1,(2.0-t)/0.2)*(0.7+0.3*np.sin(2*np.pi*7*t))
save('vortex.wav',x*0.8)
# 낙하 바람: 점점 세지는 바람 (2.6초)
t=tt(2.6); n=rng.standard_normal(len(t)); y=lp(n,400+2200*(t/2.6)**1.5)
x=y*(1.2+3.0*(t/2.6)**1.5)*np.minimum(1,t/0.2)
save('rush.wav',x*0.55)
# 첨벙: 저음 쿵 + 물보라 잡음 + 거품
t=tt(1.6); n=rng.standard_normal(len(t)); y=lp(n,np.maximum(300,5000*np.exp(-t*3.0)))
x=y*np.exp(-t*2.6)*4.0+np.sin(2*np.pi*(90-45*np.minimum(t,0.5))*t)*np.exp(-t*7)*0.9
for k in range(16):
    p=int((0.1+rng.random()*1.2)*SR); L=int(0.12*SR); tk=np.arange(L)/SR; fr=500+rng.random()*900
    x[p:p+L]+=np.sin(2*np.pi*(fr+4000*tk)*tk)*np.exp(-tk*28)*0.18
save('splash.wav',x*0.9)
print('ok')
