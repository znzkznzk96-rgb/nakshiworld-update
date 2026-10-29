import json,statistics
from pathlib import Path
P=Path(__file__).resolve().parent
b=json.loads((P/'battles.json').read_text());assert len(b)==1500
first=[200,300,500,800,1200,1800,2500,3500,4500,6000]
repeat=[10,15,25,35,50,65,85,110,140,180]
rows=[]
for stage in range(1,11):
 allr=[r for r in b if r['round']==stage];w=[r for r in allr if r['win']]
 assert len(allr)==150 and all(r['gold']==(stage*2 if r['win'] else 0) for r in allr)
 cycle=min(r['cycle_seconds'] for r in w)
 rows.append(dict(stage=stage,sampled_wins=len(w),sampled_cases=len(allr),median_win_seconds=statistics.median(r['seconds'] for r in w),fastest_cycle_seconds=cycle,current_first=26*stage,current_repeat=2*stage,proposed_first=first[stage-1],proposed_repeat=repeat[stage-1],current_repeat_max_hour=2*stage*3600/cycle,proposed_repeat_max_hour=repeat[stage-1]*3600/cycle))
(P/'reward_comparison.json').write_text(json.dumps(rows,indent=2))
c=json.loads((P.parent/'campaign-100-200h/three_four.json').read_text());assert len(c)==5
for r in c:assert r['n']==r['end_hours']['observed']+r['censored']
text='''# 해금3배·장비4배 및 탐험 돈 보상 검토 — 2026-10-30

게임 가격·보상 변경 없이 시뮬레이션과 후보 설계만 수행했다.

## 캠페인 경제: 5조건 ×256경로 =1,280경로
수족관 지급률75%, 주민 최대5.25 유지, 실제 현재 시설가격/제한, 해금3배·낚싯대/지역파츠 구매4배. 강화·가방·로봇 등의 가격은 배수 적용 제외. 하루2시간·오프라인 수족관8시간·기본 시도35초·성공90%·주인 성공60%. 로봇 접속중만. 신규어장40.

| 조건 | 마지막 주인 중앙일 | 10–90% |\n|---|---:|---:|\n'''
for r in c:
 e=r['end_hours'];text+=f"| {r['label']} | {e['p50']/2:.2f} | {e['p10']/2:.2f}–{e['p90']/2:.2f} |\n"
r=c[0];text+='\n기본 지역 진입 중앙일: '+', '.join(f"{i+1}지역 {v['p50']/2:.2f}일" for i,v in enumerate(r['region_hours']))+'.\n'
text+='''
후반4지역은 미구현이므로 미래 가격배수6/15/40/100과 기증·전투를 가정했다. 이 결과는 탐험 보상 인상안을 통합한 결과가 아니다. 현재 탐험 실제 수입도 캠페인에는 연동되지 않았고, 수동 매출15% 기타소비로 강화/탐험 지출을 근사한다. 따라서 보상 인상 이후의 엔딩 일수를 이 표로 단정할 수 없다. 상세 한계 TWO_THREE_REPORT.md 및 MODERATE_REPORT.md 참조.

## 탐험 실제 코드 조사
model.gd: 현재 첫 승리26×구역, 반복승리2×구역, 패배0. 최초10구역 합1,430비늘. 출정 돈 비용 없음. 3병사 필요, 전투 후30초 회복, 접속 중 main._process에서 탐험 진행. 주머니 보상은 별도이며 현금으로 환산하지 않았다. 다른 활동과 함께 진행될 수 있어 탐험수입을 직접낚시 대체수입으로 보지 않는다.

훈련 비용은 병사별 성급×100/200/400, 어혼도 소비. 3성 병사3마리 전체 훈련 비용은6,300비늘+어혼. 합성·주머니 구매 비용은 별도. 현재 최초 보상 총1,430은 이 훈련비의22.7%뿐이다.

## 실제 Godot 전투 모형 1,500회
현재 model.gd를 그대로 사용. 10구역×성급1/2/3×훈련0/3×역할균형25팀. 개체값4, 일반 등급, dt0.1초, 기존 전투/회복시간. 모든 팀 조합이나 실제 유저 분포를 대표하지 않는다. 표의 반복 시간당 수입은 표본 중 가장 빠른 승리팀이 매번 성공하고 회복30초 직후 즉시 재출정하는 상한 성격 수치다. UI 조작/접속 공백을 제외하므로 현실 평균으로 사용하면 안 된다.

## 권고 후보: 첫 돌파 보상 크게, 반복 보상은 시간당 기준으로

| 구역 | 현재 최초 | 후보 최초 | 현재 반복 | 후보 반복 | 승리 전투 중앙초 | 후보 반복 시간당 상한 |
|---:|---:|---:|---:|---:|---:|---:|
'''
for r in rows:text+=f"| 1-{r['stage']} | {r['current_first']} | {r['proposed_first']} | {r['current_repeat']} | {r['proposed_repeat']} | {r['median_win_seconds']:.1f} | {r['proposed_repeat_max_hour']:.0f} |\n"
text+=f'''
최초 전체 후보합 **{sum(first):,}비늘**. 계곡 해금3배(19,800)와 비교해 약{sum(first)/19800:.2f}배지만, 10구역 전체를 깨야 받는 누적금액이다. 최초1~3구역 합1,000,1~5구역 합3,000으로 초반 보상이 한꺼번에 지급되지는 않는다.

주머니 최초 보상/반복 확률은 유지, 실패0·회복30초 유지, 새 일일제한이나 복잡한 환전 규칙 추가 없음. 고난도 보상을 높게 두어 성장 유인을 준다. 표본 기준 구역별 최대 반복수입이 대체로 증가하지만 모든 개인 팀에서 최후 구역이 최적이라는 뜻은 아니다. 마지막 구역 반복180은 현재20의9배이며, 빠른 승리팀 기준 약{rows[-1]['proposed_repeat_max_hour']:.0f}/시간이다.

## 판단
현금 보상이 너무 작다는 사용자 지적은 실제 수치와 일치한다. 최초 돌파 보상은 훈련/장비/해금에 기여하는 규모로 올리는 것이 합리적이다. 반복 보상은9~수십배 숫자만 보고 판단하지 말고 전투+회복시간과 병사 획득비까지 함께 봐야 한다. 제시안은 검토 후보이며 승인·적용값이 아니다.

탐험은 보조 수입을 늘리는 변경이라 해금3배/장비4배에서 나온 약28일을50~100일로 늘려주지 않는다. 다른 조건이 같으면 오히려 단축 방향이다. 실제 단축폭은 병사 획득 시점·수동 재출정 빈도·훈련/합성·주머니 소비를 캠페인에 통합해야 계산할 수 있다. 이번에는 이를 완료했다고 주장하지 않는다.

재현: campaign-100-200h/three_four.py, 이 폴더 expedition_cash_probe.gd(게임프로젝트 tests에 복사 후 Godot headless 실행), analyze.py. 원자료 three_four.json, battles.json, reward_comparison.json. 캠페인5조건 표본합 및 전투1,500건의 기존 지급식 일치 검사 통과. 게임코드 변경/배포 없음.
'''
(P/'REPORT.md').write_text(text)
print('first total',sum(first),'last hourly',rows[-1]['proposed_repeat_max_hour'])
