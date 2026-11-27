# 컷신 효과음을 BigSoundBank CC0 실제 녹음으로 바꾼다. 출처는 SOUND_CREDITS.txt.
# 사용: python3 make_sounds.py <원본 mp3 폴더> <출력 폴더>   (원본은 bigsoundbank.com/UPLOAD/mp3/<번호>.mp3)
import subprocess, sys, os
R, O = sys.argv[1], sys.argv[2]
GAME = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'game', 'sfx', 'refresh65', 'splash.ogg')
def ff(args): subprocess.run(['ffmpeg', '-y', '-v', 'error'] + args, check=True)
def peak(f):
    r = subprocess.run(['ffmpeg', '-i', f, '-af', 'volumedetect', '-f', 'null', '-'], capture_output=True, text=True).stderr
    return float(r.split('max_volume:')[1].split('dB')[0])
def cut(name, src, ss, t, extra='', fin=0.0, target=-2.0, ext='wav'):
    out = os.path.join(O, name + '.' + ext); tmp = out + '.tmp.wav'
    af = 'afade=t=out:st=%.3f:d=%.3f' % (max(t - 0.08, 0.01), min(0.08, t / 2))
    if fin > 0: af = 'afade=t=in:st=0:d=%.3f,' % fin + af
    if extra: af = extra + ',' + af
    ff(['-ss', str(ss), '-t', str(t), '-i', src, '-ac', '1', '-ar', '44100', '-af', af, tmp])
    g = target - peak(tmp)
    codec = ['-c:a', 'libvorbis', '-q:a', '4'] if ext == 'ogg' else []
    ff(['-i', tmp, '-af', 'volume=%.2fdB,alimiter=limit=0.9' % g] + codec + [out]); os.remove(tmp)
    print(name, round(g, 1))
r = lambda n: os.path.join(R, n + '.mp3')
cut('creak', r('0306'), 0.0, 1.2)
cut('slam', r('0377'), 8.18, 0.7)
cut('tik', r('0007'), 0.22, 0.12, target=-4)
cut('zap', r('1252'), 0.08, 0.7, extra='highpass=f=300')
for i, s in enumerate([1.80, 3.54, 5.28, 7.12]): cut('slosh%d' % (i + 1), r('0690'), s, 0.7, target=-4)
cut('crack', r('0387'), 0.0, 1.4)
cut('rush', r('0595'), 10.0, 2.6, fin=1.6, target=-4)
cut('heart', r('0218'), 0.02, 0.9)
cut('drop', r('0516'), 0.46, 0.5, extra='highpass=f=180,asetrate=44100*1.3,aresample=44100', target=-5)
cut('wind', r('0908'), 5.0, 6.5, fin=0.8, target=-6)
cut('chime', r('3360'), 0.26, 2.6, target=-4)
# 밤 물가 배경(귀뚜라미 + 개구리), 반복용
n = os.path.join(O, 'night.ogg')
ff(['-ss', '3', '-t', '14', '-i', r('1020'), '-ss', '0', '-t', '14', '-i', r('0819'), '-filter_complex',
    '[0]volume=-6dB[a];[1]volume=-3dB[b];[a][b]amix=inputs=2:normalize=0,afade=t=in:d=0.5,afade=t=out:st=13.4:d=0.6', '-ac', '1', '-ar', '44100', '-c:a', 'libvorbis', '-q:a', '4', n])
ff(['-i', GAME, '-ac', '1', '-ar', '44100', os.path.join(O, 'splash.wav')])
print('ok')
