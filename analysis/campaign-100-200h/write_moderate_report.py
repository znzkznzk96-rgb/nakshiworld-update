import json, pathlib, math
P=pathlib.Path(__file__).resolve().parent
names=['moderate','moderate_investment','moderate_curve','moderate_confirm']
data={n:json.loads((P/(n+'.json')).read_text()) for n in names}
allrows=sum(data.values(),[])
checks=[]
for name,rows in data.items():
 for r in rows:
  assert r['end_hours']['observed']+r['censored']==r['n']
  assert abs(sum(r[k] for k in ['within_100_200h','below_100h','above_200h_or_censored'])-1)<1e-9
  vals=[v['p50'] for v in r['region_hours'] if v['p50'] is not None]
  assert vals==sorted(vals)
  for k in ['mean_manual_sale','mean_robot_sale','mean_aqua_income','mean_spending']:assert math.isfinite(r[k]) and r[k]>=0
 checks.append(f'{name}: {len(rows)} scenarios passed output invariants')
(P/'moderate_verification.json').write_text(json.dumps(checks,indent=2))
def table(rows):
 s='| 수족관 지급률 | 주민 최대 | 해금 배수 | 장비/파츠 배수 | 중앙 완료일 | 10–90% | 최장 구매 공백(h) | 수족관 비중 |\n|---|---:|---|---:|---:|---:|---:|---:|\n'
 for r in rows:
  c=r['config'];e=r['end_hours'];total=sum(r[k] for k in ['mean_manual_sale','mean_robot_sale','mean_aqua_income'])
  s+=f"| {300/c['aqua_div']:.0%} | {c['visitor_max']} | {c.get('fee_curve',c['fee_scale'])} | {c['gear_scale']} | {e['p50']/2:.1f} | {e['p10']/2:.1f}–{e['p90']/2:.1f} | {r['median_upgrade_gap_hours']:.1f} | {r['mean_aqua_income']/total:.1%} |\n"
 return s
text=f'''# 수족관 완만 조정 재시뮬 — 2026-10-30

사용자 요청: 수족관1/8 삭감 추천 철회. 유지/25% 감소/50% 감소 비교, 주민 배율과 분리. 해금비·시설·장비 투자도 비교. **게임 수치 미변경·미배포.**

총 {len(allrows)}개 조건, {sum(r['n'] for r in allrows):,}개 경로. 기본64회/조건, 지역별 해금곡선128회, 최종 후보 민감도128회. 하루2시간, 오프라인 수족관8시간 지급, 로봇 접속중만. 목표 마지막 지역 주인 포획100–200시간. 240일 상한에서 우측 검열 집계.

## 판단
- 수족관을1/8로 줄여야만 기간을 맞출 수 있는 것은 아니다. 지급률을75%로 유지하고 다른 투자비로 분산하는 방법도 있다.
- 그러나 단순 가격 인상은 성장 간격·보상 구조를 개선하지 않는다. 고가 장비를 사도 성능은 기존 그대로이며, 아래 배수는 경제 민감도 실험이지 권장 판매가격이 아니다.
- 지급률만 완만하게 조정한 상태에서는 수족관이 전체 수입을 대부분 차지한다. 오프라인8시간 포함 수치이므로 접속중 수입 비중과 혼동하지 말 것.
- 목표 완료일에 들어온 시나리오도 긴 구매 공백이 존재한다. **기간 적합과 재미/밸런스 적합을 구분하며 이번에도 확정 적용안으로 판정하지 않는다.**

## 실험 통제
모든 신규 안은 이전 보고서의 단계별 시설 가격곡선·지역 상한을 동일하게 사용한다. 수족관 지급률 외에는 실제 물고기 판매가격을 그대로 두었다. 주민 배율5.25와2.5를 따로 비교하여 두 삭감을 합쳐 놓고 '25% 감소'라고 부르지 않는다.

`campaign_moderate.py`는 이전 `campaign.py`를 복사해 장비/파츠 가격 배수와 지역별 해금 배수 옵션을 추가했다. 이전 모형에서 생략한 로봇 보관함 가격300/800/1800/4000을 이번에는 지급하도록 보완했다. 그 외 같은 근사와 한계를 유지한다. 과거 결과와 미세한 차이는 이 수정 및 표본수 때문일 수 있다.

## 수족관 × 주민 × 해금비 분리 비교
{table(data['moderate'])}

## 해금비4배 + 장비/파츠 투자 분산
장비/파츠 배수는 전 지역에 동일 적용. 따라서 초기 투자 부담까지 증가하는 실험이며, 최종안에서는 초반을 별도 보정해야 한다.

{table(data['moderate_investment'])}

## 초반 해금비 유지·후반 증가
배열은 첫 지역부터 마지막 지역까지 각 기존 해금비의 배수다. 예: `[1,1,2,4,8,16]`은 계곡6,600 유지, 이후208,000 / 6,180,000 / 80,400,000 / 679,200,000. 미래 어종과 수입 가정에 의존하므로 실제 가격으로 승인한 것이 아니다.

{table(data['moderate_curve'])}

## 25% 감소·주민 유지·해금8배·장비/파츠8배 후보 재검증
중앙 목표에 접근하는 투자 분산 후보의 반례/민감도 검사. 새로운 seed20261031 사용.

| 조건 | 완료 중앙일 | 10–90% 완료일 | 목표50–100일 내 비율 |\n|---|---:|---:|---:|\n'''
for r in data['moderate_confirm']:
 e=r['end_hours'];text+=f"| {r['label']} | {e['p50']/2:.1f} | {e['p10']/2:.1f}–{e['p90']/2:.1f} | {r['within_100_200h']:.1%} |\n"
text+='''
## 해석·권고
수족관 지급률75% 유지안을 다음 설계 출발점으로 둘 수 있다. 주민 최대 배율은 이번 결과만으로 하향 확정하지 않는다. 해금비·장비8배는 실험용 압축 표현이며 그대로 게임에 넣지 않는다. 지역별로 초반 비용을 보호하고, 후반 큰 지출 사이에 실제 성능 성장을 주는 기존 강화/파츠 단계를 배치한 뒤 같은 목표를 재검증해야 한다.

'작은 성장 1–2세션, 큰 목표 여러 세션'은 설계 목표다. 현재 구매 공백은 강화·탐험 등 모형 밖 소비를 제외한 경고 지표로, 실제 유저가 아무것도 못 하는 시간과 동일하지 않다.

## 주요 한계
- 실제 완성 지역은 저수지·계곡뿐. 미래4지역 어종가격 배수6/15/40/100·기증·주인 성공을 가정. 주인 성공60%, 수동 성공90%, 기본 시도35초에 가방/대기 보정. 실제 액션/장비효과를 시뮬레이션한 결과가 아니다.
- 강화·탐험 지출은 수동 매출15%로 단순화. 강화 판매보너스/승률 개선, 탐험수입·혼·진주 공급 미통합. 상세 강화 확률은 이전 enhancement_audit.py 결과 참조.
- 로봇 구매는 속도 단계를 지역별 묶음으로 처리하며 세부 수거 동선 생략. 어장 경쟁은 장기율 근사. 물고기 체장 상한/정확한 무게/미끼 재고 동작은 단순화.
- 10분 경제 업데이트. 10–90%는 동일 조건의 난수 범위이며 미래 콘텐츠 불확실성 범위가 아니다. 미구현 후반 가격 민감도 결과를 함께 볼 것.
- 원본 분석의 자세한 한계는 REPORT.md. 이번 보고서는 추천을 대체하며 원본 결과는 이력으로 보존한다.

## 재현
`moderate.py`, `moderate_investment.py`, `moderate_curve.py`, `moderate_confirm.py`. `write_moderate_report.py`는 모든 JSON 출력의 인원 합계/확률 합/지역 진입 순서/유한 비음수 수입을 검사한 후 이 문서를 생성한다. 정확한 실행별 설정·seed·지출·수입·지역별 진입시간은 해당 JSON에 보존했다. 게임 코드 검사나 실제 플레이테스트를 통과했다는 뜻이 아니다.
'''
(P/'MODERATE_REPORT.md').write_text(text)
print('scenarios',len(allrows),'paths',sum(r['n'] for r in allrows))
