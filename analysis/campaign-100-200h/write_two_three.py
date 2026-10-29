import json,math
from pathlib import Path
P=Path(__file__).resolve().parent
rows=json.loads((P/'two_three.json').read_text());assert len(rows)==13
for r in rows:
 assert r['n']==r['end_hours']['observed']+r['censored']
 assert abs(sum(r[k] for k in ['within_100_200h','below_100h','above_200h_or_censored'])-1)<1e-9
 h=[x['p50'] for x in r['region_hours'] if x['p50'] is not None];assert h==sorted(h)
 assert all(math.isfinite(r[k]) and r[k]>=0 for k in ['mean_manual_sale','mean_robot_sale','mean_aqua_income','mean_spending'])
text='''# 해금비·장비비2~3배 비교 — 2026-10-30

사용자 요청에 따라 각 비용1/2/3배를 교차 비교. **시뮬레이션만 수행, 게임 가격 미변경.**

13조건 ×128경로 =1,664경로. 신규 seed20261101. 하루2시간 플레이·오프라인 수족관8시간·수족관 지급률75%·주민최대5.25배·신규어장40·접속중로봇. 시설 비용과 구매 조건은 현재 기준(`infra=False`). 이전 보고서의 시설 단계별 가격곡선/지역상한은 이번에는 제외하여 미적용 조건이 섞이지 않도록 했다. 따라서 이전19.3일 기준과 직접 혼합 비교하면 안 된다.

비용 배수는 해금비와 낚싯대 구매/지역파츠 구매에만 적용한다. 강화·가방·로봇·수족관 확장·주민 배·어장 비용은 그대로. 시도 기본35초+가방 왕복/재고 대기, 수동 성공90%, 주인 성공60%, 수동 매출15%는 기타 지출 근사.

## 기본 비교

| 해금비 | 낚싯대·파츠 | 완료 중앙일 | 완료10–90% | 계곡 진입 중앙일 | 최장 구매간격 중앙(h) | 목표50–100일 내 비율 |
|---:|---:|---:|---:|---:|---:|---:|
'''
for r in rows[:9]:
 c=r['config'];e=r['end_hours'];text+=f"| {c['fee_scale']}배 | {c['gear_scale']}배 | {e['p50']/2:.2f} | {e['p10']/2:.2f}–{e['p90']/2:.2f} | {r['region_hours'][1]['p50']/2:.2f} | {r['median_upgrade_gap_hours']:.2f} | {r['within_100_200h']:.1%} |\n"
text+='\n## 플레이 속도 민감도\n\n| 해금/장비 배수 | 시도 기본 시간 | 완료 중앙일 | 10–90% |\n|---:|---:|---:|---:|\n'
for r in rows[9:]:
 e=r['end_hours'];text+=f"| {r['config']['fee_scale']} | {r['pace']}초 | {e['p50']/2:.2f} | {e['p10']/2:.2f}–{e['p90']/2:.2f} |\n"
text+='\n## 지역별 진입 중앙일\n\n| 해금/장비 | 계곡 | 방파제(가정) | 균열해역(가정) | 심해(가정) | 우주(가정) | 마지막 주인 |\n|---|---:|---:|---:|---:|---:|---:|\n'
for r in rows[:9]:
 c=r['config']
 if c['fee_scale']!=c['gear_scale']:continue
 vals=[f"{x['p50']/2:.2f}" for x in r['region_hours'][1:]]+[f"{r['end_hours']['p50']/2:.2f}"]
 text+=f"| {c['fee_scale']}배 | "+' | '.join(vals)+' |\n'
text+='''
## 2배·3배 가격 예시
| 항목 | 현재 | 2배 | 3배 |
|---|---:|---:|---:|
| 계곡 해금 | 6,600 | 13,200 | 19,800 |
| 다음 지역 해금 | 104,000 | 208,000 | 312,000 |
| 2단계 낚싯대 구매 | 2,000 | 4,000 | 6,000 |
| 저수지 첫 파츠 | 165 | 330 | 495 |

## 한계·판정 범위
- 후반4지역 어종가격/기증/전투가 미구현이므로 가정한 미래 가격배수6/15/40/100을 사용한 경제 모형이다. 2지역만으로 실제 완성판 엔딩 일수를 검증한 것이 아니다.
- 강화/탐험 수입·소비·전투성능은 완전 연동되지 않았다. 로봇 속도 단계는 지역별 묶음, 수거/재고는 근사, 미끼 시도당5로 단순화. 상세 한계는 MODERATE_REPORT.md와 REPORT.md 참조.
- 동일 조건128개 경로의10–90%는 난수 변동 범위다. 가정의 불확실성을 포함하는 신뢰구간이 아니다.
- 구매 공백은 모형에 포함된 구매 사이의 최장 간격이며 모형 밖 강화/탐험 등의 활동을 포함하지 않는다.
- 2~3배는 초반 가격 부담과 진행을 조정하는 후보이며, 목표50–100일 달성 여부는 결과로 판단한다. 기간을 강제로 맞추는 날짜 제한은 넣지 않았다.

재현: `python two_three.py`, `python write_two_three.py`. 전체 설정/수입/지출/진입시간/검열은 two_three.json, 진행 로그는 two_three.log. 출력13조건의 표본 합·확률 합·진입 순서·수입 유한성과 비음수 검사 통과. 게임코드 변경이 없어 기존59개 엔진검사는 반복하지 않았다.
'''
(P/'TWO_THREE_REPORT.md').write_text(text)
(P/'two_three_verification.json').write_text(json.dumps({'scenarios':len(rows),'paths':sum(r['n'] for r in rows),'output_invariants':'passed','game_modified':False},indent=2))
print(text.split('## 플레이')[0])
