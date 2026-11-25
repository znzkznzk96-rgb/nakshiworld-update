# 11/22에 만든 펫별 오라(윤곽 오라·발광·눈 깜빡임·파티클, docs/qa/pet-newstyle-20261122/layer_all.py의 D 표)를
# 게임용 투명 오버레이 스트립으로 굽는다. 몸 이미지는 건드리지 않는다.
# 출력: game/art/pet_hut/pets/{펫}_fx_{idle|move|work}.png  (9프레임, 칸 = 몸 칸 + 사방 P)
# 오버레이는 몸 칸을 사방 P만큼 넓힌 사각형에 몸 위로 그린다. 윤곽 오라는 몸 바깥 픽셀만 칠하므로 몸을 가리지 않는다.
import math, random, sys
import numpy as np
from PIL import Image
from scipy.ndimage import distance_transform_edt as EDT

ROOT = "/home/claude/nakshiworld-update/"
SRC = ROOT + "docs/qa/pet-newstyle-20261122/layer_all.py"
PETS = ROOT + "game/art/pet_hut/pets/"
P = 14      # 칸 사방 여백(파티클이 몸 높이의 절반까지 올라간다)
FR = 24     # 원본 시안의 한 바퀴 시간 단계. 9프레임이 한 바퀴를 고르게 나눈다.
N = 9

src = open(SRC).read()
env = {"np": np, "math": math}
exec(src[src.index("WH="):src.index("def region")], env)
D = env["D"]

def region(w, h, b):
    return (int(b[0]*w), int(b[1]*h), max(int(b[0]*w)+1, int(b[2]*w)), max(int(b[1]*h)+1, int(b[3]*h)))

def bake(k, kind, mask_frames):
    au, R, steps, ops = D[k]
    if kind == "rv":    # 슬롯 공개 연출용: 연출에서 쓰는 몸 프레임(rv_)과 같은 프레임으로 굽는다
        cells = [Image.open(ROOT + f"game/art/pet_hut/slot/rv_{k}_{i:02d}.png").convert("RGBA") for i in range(N)]
        c = cells[0].height
    else:
        body = Image.open(PETS + f"{k}_{'move' if kind == 'idle' else kind}.png").convert("RGBA")
        c = body.height
        cells = [body.crop((i*c, 0, (i+1)*c, c)) for i in range(N)]
    bb = None
    for f in cells:
        b = f.getbbox()
        if b: bb = b if bb is None else (min(bb[0], b[0]), min(bb[1], b[1]), max(bb[2], b[2]), max(bb[3], b[3]))
    w, h = bb[2]-bb[0], bb[3]-bb[1]
    S = c + 2*P
    out = Image.new("RGBA", (S*N, S), (0, 0, 0, 0))
    rng = random.Random(k)
    parts = [o for o in ops if o[0] == "part"]
    seeds = {id(p): [(rng.uniform(-1, 1), rng.uniform(0, 1)) for _ in range(p[3])] for p in parts}
    for i in range(N):
        t = i * FR / N
        u = 2*math.pi*t/FR
        cell = cells[0] if kind == "idle" else cells[i]
        a = np.array(cell.crop(bb)).astype(int)   # 몸(자른 영역)
        alpha_full = np.zeros((S, S), np.uint8)
        alpha_full[P:P+c, P:P+c] = np.array(cell)[..., 3]
        layer = np.zeros((S, S, 4), float)        # 오버레이(RGBA)
        # 윤곽 오라: 몸 바깥을 색으로 칠한다
        if au:
            m = alpha_full > 128
            d = EDT(~m)
            yy, xx = np.mgrid[0:S, 0:S]
            oy_b = P + bb[1]
            up = np.clip((oy_b + h - yy) / h, 0, 1)
            n = (np.sin(xx//2*1.3+u-yy//2*0.9)+np.sin(xx//2*0.7-2*u+yy//2*0.5)+np.sin(yy//2*1.7-3*u+xx//2*0.4))/3
            Rr = R*(0.55+0.45*up)+n*R*0.55+up*1.2
            idx = [2, 1, 0] if steps == 3 else ([2, 1] if steps == 2 else [1])
            al = [.55, .7, .85] if steps == 3 else [.6, .8] if steps == 2 else [.5]
            for b in range(steps):
                mk = (d > 0) & (d <= Rr*(1-b*.38)) & (yy < P+c+3)
                ca = min(1.0, al[b]*(.55 if b == 0 else .7)*1.5)
                col = np.array(au[idx[b]], float)
                # 안쪽 단이 바깥 단 위에 겹쳐 칠해진다(원본과 같은 순서)
                layer[mk, :3] = col
                layer[mk, 3] = np.maximum(layer[mk, 3], ca) if b == 0 else ca
        # 발광·눈 깜빡임: 몸 픽셀 위에 덧칠
        for op in ops:
            if op[0] == "glow":
                _, fn, box, col, per, seq = op
                x0, y0, x1, y1 = region(w, h, box)
                m = np.zeros((h, w), bool)
                m[y0:y1, x0:x1] = fn(a[y0:y1, x0:x1, 0], a[y0:y1, x0:x1, 1], a[y0:y1, x0:x1, 2]) & (a[y0:y1, x0:x1, 3] > 128)
                yy2 = np.arange(h)[:, None]*np.ones((1, w))
                ph = 0.5+0.5*np.sin(u*FR/per-(yy2/h*3 if seq else 0))
                mix = np.clip(ph*0.8, 0, 1)*m
                ys, xs = np.nonzero(mix > 0.02)
                for y, x in zip(ys, xs):
                    layer[P+bb[1]+y, P+bb[0]+x] = (*col, mix[y, x]*255/255.0)
            elif op[0] == "blink" and int(round(t)) % op[2] in (0, 1):
                x0, y0, x1, y1 = region(w, h, op[1])
                sub = a[y0:y1, x0:x1]
                m = env["WH"](sub[..., 0], sub[..., 1], sub[..., 2]) & (sub[..., 3] > 128)
                ys, xs = np.nonzero(m)
                for y, x in zip(ys, xs):
                    layer[P+bb[1]+y0+y, P+bb[0]+x0+x] = (40, 50, 30, 1.0)
        img = np.zeros((S, S, 4), np.uint8)
        img[..., :3] = np.clip(layer[..., :3], 0, 255).astype(np.uint8)
        img[..., 3] = np.clip(layer[..., 3]*255, 0, 255).astype(np.uint8)
        # 파티클(불투명 1픽셀)
        ox, oy = P+bb[0], P+bb[1]
        for p in parts:
            _, pk, cols, cnt, per = p
            for j, (x0, y0) in enumerate(seeds[id(p)]):
                ph = ((t/per)+y0) % 1.0
                cx, cy = ox+w/2, oy+h/2
                if pk == "up": X = cx+x0*w*.45+1.5*math.sin(2*math.pi*(ph+x0)); Y = oy+h*.8-ph*h*1.3
                elif pk == "down": X = cx+x0*w*.5+1.5*math.sin(2*math.pi*ph); Y = oy-2+ph*h*1.1
                elif pk == "hop": X = cx+x0*w*.4; Y = oy+h-1-ph*4
                elif pk == "drift": X = cx+x0*w*.6+3*math.sin(2*math.pi*ph); Y = oy+h*.3+ph*h*.4
                else:
                    ang = 2*math.pi*(ph+j/cnt); X = cx+math.cos(ang)*(w*.6+3); Y = cy+math.sin(ang)*(h*.22)-h*.1
                X, Y = int(X), int(Y)
                if 0 <= X < S and 0 <= Y < S: img[Y, X] = (*cols[j % len(cols)], 255)
        out.paste(Image.fromarray(img, "RGBA"), (i*S, 0))
    return out

if __name__ == "__main__":
    keys = sys.argv[1:] or [k for k in D if k != "s_rock"]
    for k in keys:
        for kind in ("idle", "move", "work", "rv"):
            bake(k, kind, None).save(PETS + f"{k}_fx_{kind}.png")
        print("ok", k)
