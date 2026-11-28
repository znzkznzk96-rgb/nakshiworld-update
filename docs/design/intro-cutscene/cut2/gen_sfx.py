# 컷2 효과음 합성(저작권 문제 없는 자체 합성). python3 gen_sfx.py → proj/snd/*.wav
import numpy as np, wave, os
SR=44100; out=os.path.join(os.path.dirname(os.path.abspath(__file__)),'proj','snd')
rng=np.random.default_rng(7)
def save(name,x):
    x=np.clip(x,-1,1); w=wave.open(os.path.join(out,name),'wb'); w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((x*32000).astype('<i2').tobytes()); w.close()
def tt(d): return np.arange(int(SR*d))/SR
# 문 끼이익: 주파수가 올라갔다 내려가는 톱니파 + 떨림 + 잡음
t=tt(1.0); f=170+260*np.sin(np.pi*t/1.0)**1.3+18*np.sin(2*np.pi*23*t)
ph=2*np.pi*np.cumsum(f)/SR; saw=2*((ph/(2*np.pi))%1)-1
env=np.minimum(1,t/0.08)*np.minimum(1,(1.0-t)/0.25)
x=(0.5*saw+0.25*np.sign(np.sin(ph*0.5))+0.15*rng.standard_normal(len(t))*np.sin(np.pi*t))*env*0.55
save('creak.wav',x)
# 쾅(문 닫힘)
t=tt(0.6); x=(np.sin(2*np.pi*(70-40*t)*t)*np.exp(-t*9)*1.0+rng.standard_normal(len(t))*np.exp(-t*30)*0.7)*0.9
save('slam.wav',x)
# TIK
t=tt(0.06); x=(np.sin(2*np.pi*2200*t)*np.exp(-t*140)+rng.standard_normal(len(t))*np.exp(-t*200)*0.5)*0.8
save('tik.wav',x)
# 대사 타자음
t=tt(0.04); x=np.sign(np.sin(2*np.pi*880*t))*np.exp(-t*60)*0.35
save('blip.wav',x)
# 놀람 "!"
t=tt(0.16); f=np.where(t<0.07,660,990); x=np.sign(np.sin(2*np.pi*f*t))*np.minimum(1,(0.16-t)/0.05)*0.35
save('alert.wav',x)
# 불꽃 팍
t=tt(0.7); n=rng.standard_normal(len(t)); crack=n*np.exp(-t*7)*(rng.random(len(t))>0.55)
x=(crack*0.9+np.sin(2*np.pi*(120-80*t)*t)*np.exp(-t*14)*0.8+n*np.exp(-t*40)*0.6)*0.9
save('zap.wav',x)
# 물음(? 소리) 짧은 두 음
t=tt(0.22); f=np.where(t<0.1,520,430); x=np.sin(2*np.pi*f*t)*np.exp(-(t%0.11)*18)*0.3
save('hmm.wav',x)
print('ok')
# 철썩(물이 찰랑이며 부딪히는 소리) 4종: 저역 통과 잡음이 쓸려 내려가는 모양 + 작은 거품음
def slosh(name,dur,f0,f1,seed):
    r=np.random.default_rng(seed); t=tt(dur); n=r.standard_normal(len(t))
    cut=np.linspace(f0,f1,len(t)); y=np.zeros(len(t)); s=0.0
    for i in range(len(t)):
        a=1-np.exp(-2*np.pi*cut[i]/SR); s+=a*(n[i]-s); y[i]=s
    env=np.minimum(1,t/0.03)*np.exp(-t*(5.0/dur)) ; y=y/np.max(np.abs(y))*env
    for _ in range(3):
        c=r.uniform(0.04,dur*0.7); m=(t>c)&(t<c+0.06); y[m]+=0.18*np.sin(2*np.pi*(500+3500*(t[m]-c))*(t[m]-c))*np.exp(-(t[m]-c)*40)
    save(name,y*0.9)
slosh('slosh1.wav',0.55,2600,300,11); slosh('slosh2.wav',0.7,1800,200,12); slosh('slosh3.wav',0.45,3200,400,13); slosh('slosh4.wav',0.8,1500,180,14)
print('slosh ok')
