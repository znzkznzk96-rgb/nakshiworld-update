# 컷4 효과음 합성. python3 gen_sfx.py → proj/snd/*.wav
import numpy as np, wave, os
SR=44100; out=os.path.join(os.path.dirname(os.path.abspath(__file__)),'proj','snd')
rng=np.random.default_rng(21)
def save(name,x):
    x=np.clip(x,-1,1); w=wave.open(os.path.join(out,name),'wb'); w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((x*32000).astype('<i2').tobytes()); w.close()
def tt(d): return np.arange(int(SR*d))/SR
# 두근(눈 뜰 때 심장 소리): 낮은 쿵 두 번
t=tt(0.5); x=np.sin(2*np.pi*(70-25*t)*t)*np.exp(-t*16)+0.8*np.sin(2*np.pi*(62-20*(t-0.18)*(t>0.18))*np.maximum(t-0.18,0))*np.exp(-np.maximum(t-0.18,0)*18)*(t>0.18)
save('heart.wav',x*0.9)
# 툭(낚싯대 떨어짐): 짧은 나무 부딪힘 + 작은 튕김
t=tt(0.5); x=np.sin(2*np.pi*(180-90*t)*t)*np.exp(-t*30)*0.8+rng.standard_normal(len(t))*np.exp(-t*90)*0.35
t2=np.maximum(t-0.16,0); x+=np.sin(2*np.pi*220*t2)*np.exp(-t2*45)*0.35*(t>0.16)
save('drop.wav',x*0.9)
print('ok')
