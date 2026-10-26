import random, statistics, json, math, copy, sys

LOCS = ['저수지', '계곡', '방파제', '선상', '심해', '우주']
STAR = [0] * 8 + [1] * 6 + [2] * 3 + [3] * 2 + [4]          # 낚시터당 20종
STAR_P = [0.62, 0.27, 0.09, 0.018, 0.002]
STAR_PRICE = [20, 85, 275, 1250, 8000]
SKILL = [0.97, 0.92, 0.82, 0.65, 0.45]
GRADES = ['노멀', '레어', '유니크', '전설', '신화']
G_P = [0.70, 0.22, 0.065, 0.013, 0.002]
G_MULT = [1, 1.3, 1.7, 2.2, 3]
G_PEARL = [0, 0, 1, 3, 10]
BY_STAR = [[i for i in range(20) if STAR[i] == k] for k in range(5)]

CFG = dict(
    vm=[1, 2.5, 6, 15, 40, 100],
    loc_cost=[0, 3000, 15000, 580000, 4800000, 23000000],
    loc_doc=0.6, loc_diff=0.06, line_bonus=0.012,
    bait_decay=0.95, up_base={'rod': 100, 'line': 80, 'bait': 60}, up_growth=1.25,
    inc_div=300, offline_cap=480,
    vmult=[1.0, 1.15, 1.3, 1.5, 1.7, 1.9, 2.1],
    vspecies=[0, 8, 16, 33, 53, 73, 93],
    stock_base=120, stock_regen=40, refill_tax=0.5,
)

PROFILES = {
    '라이트 (하루 10분)': ([8, 20], 5),
    '보통 (하루 30분)': ([7, 13, 21], 10),
    '헤비 (하루 2시간)': ([7, 12, 18, 22], 30),
    '하루 10시간': ([8, 13, 18], 200),
}
NORMAL = '보통 (하루 30분)'


class P:
    def __init__(self, c, rng):
        self.c, self.rng = c, rng
        self.gold = 0.0; self.pearls = 0
        self.lv = {'rod': 0, 'line': 0, 'bait': 0}
        self.loc = 0; self.village = 0; self.slots = 3; self.tank = []
        self.caught = [set() for _ in LOCS]; self.grades = set()
        self.best_star = -1; self.best_grade = -1
        self.slv = [0] * 6; self.stock = [c['stock_base']] * 6
        self.enh = 0
        self.win3 = self.win4 = True
        self.events = {}; self.ratio = {}; self.now_day = 0; self.active_min = 0
        self.bought = False; self.dry = 0; self.max_dry = 0
        self.max_fish = [0] * 6; self.refills = 0

    def mark(self, k):
        if k not in self.events:
            self.events[k] = self.now_day
            self.ratio[k] = self.tank_rate() * self.c['offline_cap'] / max(1e-9, self.ev(self.loc))

    def b(self):
        return 1 + (1 - math.exp(-self.lv['rod'] / 40))

    def mx(self, L): return self.c['stock_base'] * (1 + 0.3 * self.slv[L])
    def fresh(self, L): return 0.3 + 0.7 * self.stock[L] / self.mx(L)
    def regen(self, dmin):
        r = self.c['stock_regen']
        self.stock = [min(self.mx(L), s + r * (1 + 0.3 * self.slv[L]) * dmin / 60) for L, s in enumerate(self.stock)]

    def star_w(self, L):
        m = self.fresh(L); b = self.b()
        w = [STAR_P[s] * b ** (0.6 * s) * m ** s for s in range(5)]
        if not self.win3: w[2] = 0
        if not self.win4: w[3] = 0
        if not (self.win4 and self.stock[L] >= 0.9 * self.mx(L)): w[4] = 0
        return w

    def succ(self, s, L, extra):
        p = SKILL[s] - self.c['loc_diff'] * L + self.c['line_bonus'] * self.lv['line']
        if p > SKILL[s]: p = SKILL[s] + (p - SKILL[s]) * 0.3
        return max(0.03, min(0.99, p * 0.93 ** extra))

    def cycle(self, s, g=0):
        return 6 + max(3.0, 15 * self.c['bait_decay'] ** self.lv['bait']) + 4 + 2 * s + g

    def ev(self, L):
        w = self.star_w(L); t = sum(w)
        if t == 0: return 0
        gm = sum(G_P[g] * G_MULT[g] for g in range(5))
        val = sum(w[s] / t * self.succ(s, L, 0.4) * STAR_PRICE[s] * gm * 1.05 * self.c['vm'][L] for s in range(5))
        cyc = sum(w[s] / t * self.cycle(s) for s in range(5))
        return val / cyc * 60 * self.fresh(L) * (1 + 0.05 * self.enh)

    def tank_rate(self): return sum(self.tank) * self.c['vmult'][self.village]

    def cast(self):
        L = self.force_L if getattr(self, 'force_L', None) is not None else max(range(self.loc + 1), key=self.ev)
        if self.stock[L] < 0.15 * self.mx(L):
            cost = self.c['refill_tax'] * self.ev(L) / 3 * (self.mx(L) - self.stock[L])
            if self.gold >= cost:
                self.gold -= cost; self.stock[L] = self.mx(L); self.refills += 1
        m = self.fresh(L)
        w = self.star_w(L)
        s = self.rng.choices(range(5), w)[0]
        gw = [G_P[g] * self.b() ** (0.3 * g) for g in range(5)]
        g = self.rng.choices(range(5), gw)[0]
        ln = max(0.5, min(2.0, self.rng.gauss(1.0, 0.15)))
        extra = g + (2 if ln >= 1.5 else 1 if ln >= 1.2 else 0)
        dt = self.cycle(s, g)
        self.stock[L] = max(0, self.stock[L] - 1)
        if self.rng.random() < self.succ(s, L, extra):
            sp = self.rng.choice(BY_STAR[s])
            self.caught[L].add(sp); self.grades.add((L, sp, g))
            if s > self.best_star: self.best_star = s; self.mark('첫 ★%d' % (s + 1))
            if g > self.best_grade: self.best_grade = g; self.mark('첫 ' + GRADES[g])
            self.pearls += G_PEARL[g]
            price = STAR_PRICE[s] * self.c['vm'][L] * G_MULT[g] * min(2.5, ln * ln) * (1 + 0.05 * self.enh) * m
            self.max_fish[L] = max(self.max_fish[L], price)
            inc = price / self.c['inc_div']
            if len(self.tank) < self.slots: self.tank.append(inc)
            elif inc > min(self.tank):
                self.gold += min(self.tank) * self.c['inc_div']; self.tank.remove(min(self.tank)); self.tank.append(inc)
            else: self.gold += price
        return dt

    def up_cost(self, k): return self.c['up_base'][k] * self.c['up_growth'] ** self.lv[k]

    def loc_ok(self):
        n = self.loc + 1
        if n >= 6 or self.slv[self.loc] < 3: return None
        if len(self.caught[self.loc]) / 20 < self.c['loc_doc']: return None
        if n >= 2 and not any(STAR[i] >= 3 for i in self.caught[self.loc]): return None
        if n == 5 and 19 not in self.caught[4]: return None
        return self.c['loc_cost'][n]

    def village_ok(self):
        n = self.village + 1
        if n >= 7 or sum(len(x) for x in self.caught) < self.c['vspecies'][n]: return None
        if n == 1: return 3000 if self.best_star >= 2 else None
        if self.loc < n - 1: return None
        return 0.5 * self.c['loc_cost'][n - 1]

    def slot_ok(self):
        i = self.slots - 3; lc = self.c['loc_cost']
        t = [(1000, 0), (5000, 0), (20000, 0), (0.3 * lc[2], 2), (0.8 * lc[2], 2), (0.3 * lc[3], 3), (0.8 * lc[3], 3), (0.5 * lc[4], 4), (0.5 * lc[5], 5)]
        if i >= len(t): return None
        if i == 1 and sum(len(x) for x in self.caught) < 5: return None
        if i == 2 and self.village < 1: return None
        if self.loc < t[i][1]: return None
        return t[i][0]

    def shop(self):
        while True:
            L = self.loc
            sc = 500 * self.c['vm'][L] * 1.5 ** self.slv[L]
            if self.slv[L] < 3 + L and self.gold >= sc:
                self.gold -= sc; self.slv[L] += 1; self.bought = True; continue
            lc, vc, sl = self.loc_ok(), self.village_ok(), self.slot_ok()
            if lc is not None and self.gold >= lc:
                self.gold -= lc; self.loc += 1; self.mark(LOCS[self.loc] + ' 해금'); self.bought = True; continue
            if vc is not None and self.gold >= vc:
                self.gold -= vc; self.village += 1; self.mark('마을 Lv.%d' % (self.village + 1)); self.bought = True; continue
            if sl is not None and self.gold >= sl:
                self.gold -= sl; self.slots += 1; self.mark('수조 %d칸' % self.slots); self.bought = True; continue
            goal = lc if lc is not None else vc
            k = min(self.lv, key=self.up_cost); cost = self.up_cost(k)
            if self.gold >= cost and (goal is None or cost < 0.2 * goal):
                self.gold -= cost; self.lv[k] += 1; self.bought = True; continue
            if self.loc >= 2 and self.enh < 20:
                ec = 3000 * self.c['vm'][self.loc] * 1.3 ** self.enh
                if self.gold >= ec and (goal is None or ec < 0.2 * goal):
                    self.gold -= ec; self.bought = True
                    if self.rng.random() < max(0.3, 0.95 - 0.05 * self.enh): self.enh += 1
                    elif self.enh >= 5: self.enh -= 1
                    continue
            return


def run(profile, days, seed, c, snaps=()):
    hours, mins = PROFILES[profile]
    p = P(c, random.Random(seed)); last = 0.0; p.snap = {}
    for d in range(days):
        for h in hours:
            start = d * 1440 + h * 60
            p.gold += p.tank_rate() * min(start - last, c['offline_cap']); p.regen(start - last)
            p.now_day = start / 1440
            p.win3 = p.rng.random() < 0.6; p.win4 = p.rng.random() < 0.3
            p.shop(); t = 0.0
            while t < mins * 60:
                dt = p.cast(); t += dt; p.regen(dt / 60)
                p.gold += p.tank_rate() * dt / 60; p.active_min += dt / 60; p.shop()
            last = start + mins
            if p.bought: p.dry = 0
            else: p.dry += 1; p.max_dry = max(p.max_dry, p.dry)
            p.bought = False
        if d + 1 in snaps:
            p.snap[d + 1] = dict(pearls=p.pearls, dex=len(p.grades) / 600, loc=p.loc)
    return p


TARGET = {'계곡 해금': 2.5, '방파제 해금': 7, '선상 해금': 18, '심해 해금': 35, '우주 해금': 65}


def tune(c, rounds=14, seeds=8, days=150):
    for it in range(rounds):
        runs = [run(NORMAL, days, s, c) for s in range(seeds)]
        line = []
        for L in range(1, 6):
            k = LOCS[L] + ' 해금'
            got = statistics.median(r.events.get(k, days * 1.5) for r in runs)
            f = max(0.4, min(2.5, (TARGET[k] / got) ** (0.7 if it < 8 else 0.35)))
            c['loc_cost'][L] *= f
            line.append('%s %.1f일' % (LOCS[L], got))
        print('라운드 %2d: ' % it + ', '.join(line), flush=True)


if __name__ == '__main__':
    c = copy.deepcopy(CFG)
    tune(c)
    print('해금 비용:', [round(x) for x in c['loc_cost']])
    json.dump(c, open('tuned8.json', 'w'), ensure_ascii=False)
    keys = ['계곡 해금', '방파제 해금', '선상 해금', '심해 해금', '우주 해금', '첫 ★5', '첫 신화']
    out = {}
    for prof in PROFILES:
        heavy = prof == '하루 10시간'
        D = 120 if heavy else 200
        runs = [run(prof, D, s, c, snaps=(30, 60, 120) + (() if heavy else (200,))) for s in range(8 if heavy else 16)]
        ev = {k: statistics.median(r.events.get(k, 999) for r in runs) for k in keys}
        rat = {k: statistics.median(r.ratio[k] for r in runs if k in r.ratio) for k in keys[:5]}
        snap = {d: dict(pearls=statistics.median(r.snap[d]['pearls'] for r in runs),
                        dex=statistics.median(r.snap[d]['dex'] for r in runs)) for d in runs[0].snap}
        mf = [round(statistics.median(r.max_fish[L] for r in runs if r.max_fish[L] > 0)) if any(r.max_fish[L] for r in runs) else 0 for L in range(6)]
        out[prof] = dict(events=ev, ratio=rat, snap=snap, max_fish=mf, dry=statistics.median(r.max_dry for r in runs),
                         refills=statistics.median(r.refills / D for r in runs))
        print('==', prof)
        for k in keys: print('  %-8s %6.1f일' % (k, ev[k]), ' 8시간방치=활동 %.0f분' % rat[k] if k in rat else '')
        print('  진주/도감600칸:', {d: (round(v['pearls']), '%.0f%%' % (v['dex'] * 100)) for d, v in snap.items()})
        print('  낚시터별 최고가 한 마리:', mf)
        print('  최장 무구매 세션:', out[prof]['dry'], ' 하루 방류:', out[prof]['refills'])
    json.dump(out, open('report8.json', 'w'), ensure_ascii=False)
