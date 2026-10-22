# sim12 + 2026-10-18 새벽 결정 반영
#  - 파츠 4칸(찌·바늘·줄·릴): 그 낚시터 재질 파츠를 달수록 높은 ★ 등장. 0개 = ★1만, 4개(풀파츠) = 주인 게이지 시작
#    가격 = 다음 낚시터 해금비(우주는 우주 해금비 × 2) × [10%, 20%, 35%, 60%] × part_scale
#    '줄' 파츠가 돌진 충격 감소를 맡음: 그 낚시터 줄이면 줄 단계 = 낚시터 단계, 아니면 한 단계 낮음
#  - 낚싯대 = 낚시터 단계, 낚싯대마다 강화(최대 +5/+8/+10/+13/+16/+20), 새 낚싯대는 +0
#    강화 = 비늘 + 물고기의 혼. 실패 시 최대치 절반 이상이면 1단계 하락 (하락 유지)
#  - 물고기의 혼: 손질하면 ★ 기본값 × 등급 배수. 봇은 다음 강화에 혼이 모자라면 남는 물고기를 손질, 아니면 판매
#  - 엔드 박스(보관통 마지막 단계)는 우주를 연 뒤에만 판매
import json, statistics, sys, random
import sim8, sim11, sim12
from sim8 import LOCS, STAR_PRICE, G_MULT, G_PEARL, GRADES, BY_STAR
from sim9c import BAITS, BAIT_COST, BAIT_BOOST
from sim12 import P12, P

P.update(dict(
    part_frac=[0.10, 0.20, 0.35, 0.60], part_scale=1.0,
    rod_max=[5, 8, 10, 13, 16, 20], rod_coef=[1, 2, 4, 8, 16, 32],
    soul_star=[1, 2, 4, 8, 20], soul_grade=[1, 2, 4, 8, 16], soul_per_level=5,
    enh_tries=1, enh_drop=True, enh_price=0.05,   # 강화 단계당 판매가 보너스
    owner_grade=None,      # 낚시터별 주인 등급 가중치 [[노멀,레어,유니크,전설,신화]×6], None = 일반 등급 확률
    soul_growth=None,      # 강화 혼: None = 계수×(단계+1)×기본, 숫자 = 계수×기본×성장^단계
    recipe=False, recipe_frac=0.3, recipe_need=[[3, 2, 1], [2, 3, 2]], recipe_per='day',   # 주인 미끼 레시피(★idx, 최소 등급, 마리)
))
FT13 = None

class P13(P12):
    def part_base(self, L):
        lc = self.c['loc_cost']
        return lc[L + 1] if L < 5 else 2 * lc[5]
    def part_price(self, L, k): return self.part_base(L) * P['part_frac'][k] * P['part_scale']
    def line_tier(self):
        L = getattr(self, '_L', self.loc)
        return L if self.parts[L] >= 3 else max(0, L - 1)
    def star_w(self, L):
        w = P12.star_w(self, L)
        for s in range(1, 5):
            if s > self.parts[L]: w[s] = 0      # 파츠가 모자라면 그 ★은 안 나옴
        if sum(w) == 0: w[0] = 1
        return w
    def rneed(self, L):
        r = P['recipe_need']
        return r[L] if isinstance(r[0][0], list) else r
    def soul_need(self):
        if P['soul_growth']: return P['rod_coef'][self.loc] * P['soul_per_level'] * P['soul_growth'] ** self.enh
        return P['rod_coef'][self.loc] * (self.enh + 1) * P['soul_per_level']

    def process(self):
        for price, inc, soul in self.bag:
            if len(self.tank) < self.slots: self.tank.append(inc); self.n_tank += 1
            elif inc > min(self.tank):
                self.gold += min(self.tank) * self.c['inc_div']; self.tank.remove(min(self.tank)); self.tank.append(inc); self.n_tank += 1
            elif self.enh < P['rod_max'][self.loc] and self.loc >= 0 and self.soul < self.soul_need():
                self.soul += soul; self.n_soul += 1; self.soul_total += soul
            else: self.gold += price; self.n_sell += 1
        self.bag = []; self.bag_w = 0.0

    def shop(self):
        L = self.loc
        # 엔드 박스(마지막 단계)는 우주를 연 뒤에만
        while P['storage'] and self.st + 1 < len(P['store_price']) and self.gold >= P['store_price'][self.st + 1] \
                and (self.st + 1 < len(P['store_price']) - 1 or self.loc >= 5):
            self.gold -= P['store_price'][self.st + 1]; self.st += 1; self.bought = True
            self.mark('보관통 %d단계' % self.st)
        if P['recipe']:
            for k in range(self.loc + 1):
                pr = self.part_base(k) * P['recipe_frac']
                if self.owner_caught[k] and not self.recipe[k] and self.gold >= pr:
                    self.gold -= pr; self.recipe[k] = True; self.bought = True; self.mark('%s 레시피' % LOCS[k])
        # 파츠: 순서대로(찌 → 바늘 → 줄 → 릴), 돈이 되면 바로
        while self.parts[L] < 4 and self.gold >= self.part_price(L, self.parts[L]):
            self.gold -= self.part_price(L, self.parts[L]); self.parts[L] += 1; self.bought = True
            self.mark('%s 파츠 %d' % (LOCS[L], self.parts[L]))
        while True:
            L = self.loc
            sc = 500 * self.c['vm'][L] * 1.5 ** self.slv[L]
            if self.slv[L] < 3 + L and self.gold >= sc:
                self.gold -= sc; self.slv[L] += 1; self.bought = True; continue
            lc, vc, sl = self.loc_ok(), self.village_ok(), self.slot_ok()
            if lc is not None and self.gold >= lc:
                self.gold -= lc; self.loc += 1; self.enh = 0; self.mark(LOCS[self.loc] + ' 해금'); self.bought = True
                return self.shop()
            if vc is not None and self.gold >= vc:
                self.gold -= vc; self.village += 1; self.mark('마을 Lv.%d' % (self.village + 1)); self.bought = True; continue
            if sl is not None and self.gold >= sl:
                self.gold -= sl; self.slots += 1; self.mark('수조 %d칸' % self.slots); self.bought = True; continue
            goal = lc if lc is not None else vc
            k = min(self.lv, key=self.up_cost); cost = self.up_cost(k)
            if self.gold >= cost and (goal is None or cost < 0.2 * goal):
                self.gold -= cost; self.lv[k] += 1; self.bought = True; continue
            mx = P['rod_max'][L]
            if self.enh < mx and self.enh_tries < P['enh_tries'] and self.soul >= self.soul_need():
                ec = 3000 * self.c['vm'][L] * 1.3 ** self.enh
                if self.gold >= ec and (goal is None or ec < 0.2 * goal):
                    self.gold -= ec; self.soul -= self.soul_need(); self.bought = True; self.enh_tries += 1; self.enh_spent += ec
                    if self.rng.random() < max(0.3, 0.95 - 0.05 * self.enh * 20 / mx):
                        self.enh += 1; self.best_enh[L] = max(self.best_enh[L], self.enh)
                    elif P['enh_drop'] and self.enh >= (mx + 1) // 2: self.enh -= 1; self.drops += 1
                    continue
            return

    def cast(self):
        L = self.force_L if getattr(self, 'force_L', None) is not None else max(range(self.loc + 1), key=self.ev)
        self._L = L
        sim11.ENH_NOW = self.enh / P['rod_max'][self.loc] if L == self.loc else 0.0
        k = self.pick_bait(L); self.bait = k
        self.gold -= BAIT_COST[k]; self.bait_spent += BAIT_COST[k]
        m = self.fresh(L)
        need = P['gauge'][L] * (P['gauge_repeat'] if self.owner_caught[L] else 1)
        if self.parts[L] >= 4: self.gauge[L] += 1            # 풀파츠여야 주인 기척이 쌓임
        owner = self.gauge[L] >= need
        if P['recipe'] and self.owner_caught[L]:              # 두 번째부터는 게이지 대신 레시피 미끼로만
            owner = False; self.gauge[L] = 0
            day = int(self.now_day) if P['recipe_per'] == 'day' else self.now_day
            if self.recipe[L] and self.last_use[L] != day and all(self.stash[L][i] >= n for i, (_, _, n) in enumerate(self.rneed(L))):
                for i, (_, _, n) in enumerate(self.rneed(L)): self.stash[L][i] -= n
                self.last_use[L] = day; self.bait_used += 1; owner = True
        s = 4 if owner else self.rng.choices(range(5), self.star_w(L))[0]
        bb = BAIT_BOOST[k]
        gw = [sim11.NEW_BASE[g] * bb ** g * self.b() ** (0.3 * g) for g in range(5)]
        fw = [sum(gw[i] * self.Mh[i][j] for i in range(5)) for j in range(5)]
        g = self.rng.choices(range(5), fw)[0]
        if owner and P['owner_grade']: g = self.rng.choices(range(5), P['owner_grade'][L])[0]
        ln = max(0.5, min(2.0, self.rng.gauss(1.0, 0.15)))
        extra = g + (2 if ln >= 1.5 else 1 if ln >= 1.2 else 0)
        dt = self.cycle(s, g)
        self.stock[L] = max(0, self.stock[L] - 1)
        p = self.succ(s, L, extra)
        if owner: p = 1 - (1 - p) * P.get('owner_tire', 1.0) ** self.owner_fail[L]   # 놓칠수록 지친 주인(임시 실험)
        if self.rng.random() < p:
            if owner:
                self.gauge[L] = 0; self.owner_fail[L] = 0
                if not self.owner_caught[L]: self.mark(LOCS[L] + ' 주인')
                self.owner_caught[L] += 1
            sp = self.rng.choice(BY_STAR[s])
            self.caught[L].add(sp); self.grades.add((L, sp, g))
            if owner: self.owner_g[L].add(g)
            if hasattr(self, 'catch_log'): self.catch_log[(s, g)] += 1   # rates.py용
            if s > self.best_star: self.best_star = s; self.mark('첫 ★%d' % (s + 1))
            if g > self.best_grade: self.best_grade = g; self.mark('첫 ' + GRADES[g])
            self.pearls += G_PEARL[g]
            enh_here = self.enh if L == self.loc else 0
            price = STAR_PRICE[s] * self.c['vm'][L] * G_MULT[g] * min(2.5, ln * ln) * (1 + P['enh_price'] * enh_here) * m
            self.max_fish[L] = max(self.max_fish[L], price)
            inc = price / self.c['inc_div']
            soul = P['soul_star'][s] * P['soul_grade'][g]
            if P['recipe'] and self.recipe[L] and not owner:
                for i, (ns, ng, n) in enumerate(self.rneed(L)):
                    if s == ns and g >= ng and self.stash[L][i] < n:
                        self.stash[L][i] += 1; return dt        # 미끼 재료로 따로 보관
            wt = P['wbase'][s] * P['wloc'][L] * ln ** 3 * P['wgrade'][g]
            if self.bag_w + wt <= self.store_capacity():
                self.bag.append((price, inc, soul)); self.bag_w += wt
                if self.store_capacity() - self.bag_w < P['wbase'][0] * P['wloc'][L] * 0.8:
                    self.process(); dt += P['trip_s']; self.trips += 1
            else:
                self.bag.append((price, inc, soul)); self.process(); dt += P['trip_s']; self.trips += 1; self.shoulder += 1
        elif owner:
            self.owner_fail[L] += 1
            if not (P['recipe'] and self.owner_caught[L]): self.gauge[L] = int(need * P.get('owner_keep', 0.5))   # 주인 놓쳤을 때 남는 게이지 비율(주인 규칙 미정이라 임시)
        return dt

_make12 = sim12.make
def make(c, rng):
    p = _make12(c, rng)
    p.__class__ = P13
    p.parts = [0] * 6; p.soul = 0; p.soul_total = 0; p.n_soul = 0; p.n_sell = 0; p.n_tank = 0
    p.best_enh = [0] * 6; p.drops = 0; p.recipe = [False] * 6; p.stash = [[0, 0, 0] for _ in range(6)]; p.last_use = [None] * 6; p.bait_used = 0; p.owner_g = [set() for _ in range(6)]; p.owner_fail = [0] * 6
    return p

def run(profile, days, seed, c):
    orig = sim12.make
    sim12.make = make
    try: return sim12.run(profile, days, seed, c)
    finally: sim12.make = orig

if __name__ == '__main__':
    c = json.load(open('tuned8.json')); c['refill_tax'] = 1e18
    prof, skill, seeds, days = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
    if len(sys.argv) > 5: P.update(json.loads(sys.argv[5]))
    if len(sys.argv) > 6:
        sim11.FT = json.load(open(sys.argv[6]))
    c['loc_cost'][5] *= P['space_mul']
    sim11.SKILL = skill; sim11.LINE_PRICE = 1.0; sim8.G_P[:] = sim11.NEW_BASE
    runs = [run(prof, days, s, c) for s in range(seeds)]
    out = dict(prof=prof, skill=skill, P={k: P[k] for k in ("space_mul", "part_scale", "enh_tries", "enh_drop", "soul_per_level", "rod_coef", "owner_keep", "owner_tire", "recipe", "recipe_need", "recipe_per", "owner_grade", "soul_growth", "enh_price") if k in P}, **sim12.summary(runs, days))
    med = lambda xs: round(statistics.median(xs), 1)
    out['parts'] = {'%s %d' % (LOCS[L], k): med([r.events.get('%s 파츠 %d' % (LOCS[L], k), 999) for r in runs]) for L in range(6) for k in (1, 4)}
    out['fate'] = dict(tank=med([r.n_tank for r in runs]), soul=med([r.n_soul for r in runs]), sell=med([r.n_sell for r in runs]))
    out['best_enh'] = [med([r.best_enh[L] for r in runs]) for L in range(6)]
    out['drops'] = med([r.drops for r in runs])
    out['owner_n'] = [med([r.owner_caught[L] for r in runs]) for L in range(6)]
    out['owner_grades'] = [med([len(r.owner_g[L]) for r in runs]) for L in range(6)]
    out['bait_used'] = med([r.bait_used for r in runs])
    out['recipe_day'] = {LOCS[L]: med([r.events.get('%s 레시피' % LOCS[L], 999) for r in runs]) for L in range(6)}
    print(json.dumps(out, ensure_ascii=False), flush=True)
