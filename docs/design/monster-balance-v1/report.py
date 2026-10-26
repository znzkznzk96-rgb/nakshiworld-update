import json,csv,html
from pathlib import Path
p=Path(__file__).parent;d=json.loads((p/'balance.json').read_text());r=json.loads((p/'results.json').read_text())
def table(headers,rows):return '<div class="scroll"><table><thead><tr>'+''.join('<th>'+html.escape(str(v))+'</th>' for v in headers)+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+html.escape(str(v))+'</td>' for v in row)+'</tr>' for row in rows)+'</tbody></table></div>'
def csvout(name,headers,rows):
 with (p/name).open('w',encoding='utf-8-sig',newline='') as f:w=csv.writer(f);w.writerow(headers);w.writerows(rows)
soldiers=[]
for u in d['soldiers']:
 for star,v in u['stars'].items():soldiers.append([u['id'],u['name'],u['soul_combination'],u['role'],star,v['hp'],v['atk'],v['def']])
csvout('soldiers.csv',['ID','병사','어혼조합','역할','별','체력','공격','방어'],soldiers)
enemies=[[u['id'],u['name'],u['hp'],u['atk'],u['defense']] for u in d['enemies']];csvout('enemies.csv',['ID','몬스터','체력','공격','방어'],enemies)
roles={'attack':'공격','defense':'방어','support':'지원'}
text='''<!doctype html><html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>낚시월드 전투 수치 v1</title><style>body{background:#142031;color:#eee4d0;margin:0;font:16px system-ui;line-height:1.65}main{max-width:1100px;margin:auto;padding:24px}h1,h2{color:#edc77e}h1{font-size:28px}h2{font-size:22px;margin-top:34px}table{border-collapse:collapse;width:100%;white-space:nowrap}td,th{padding:9px 12px;border-bottom:1px solid #465266;text-align:right}td:nth-child(2),th:nth-child(2){text-align:left}th{background:#283b50;color:#edc77e}.scroll{overflow:auto}.note{padding:18px;background:#26374c;border-left:4px solid #d7aa60}small{color:#b8c3d0}code{color:#a6dfdb}</style><main><h1>낚시월드 · 전투 수치 v1</h1><p>병사15종 · 일반18종 · 보스4종 / 게임 미적용</p><div class="note"><strong>목표: 2성 방어병 + 2성 공격병 + 1성 지원병으로 10R 돌파.</strong><br>같은 육성조건, 장비·속성·레벨 보정 없음. 출발체력100%에서 10R 일반2마리와 보스를 연속 상대한다. 3인 편성과 앞병사 우선피격은 기존결정. 아래 속도·회복·별배율은 이번 초기튜닝에 쓰는 제안값이다.</div><h2>전투 계산 기준</h2><p>1.5초마다 살아있는 병사 모두 행동. 적은 살아있는 맨앞 병사를 공격. 피해는 <code>max(1,반올림(공격×100÷(100+방어)))</code>. 같은 시점의 피해는 동시에 처리하고, 사망한 병사는 다음 행동부터 제외한다. 지원병은 세 번째 행동마다 공격 대신 현재 선두 생존병사를 자기 공격력의80%만큼 회복한다. 부활은 없다.</p><p>1성 대비 2성은 체력×1.75·공격×1.65·방어×1.35, 3성은 ×2.65·×2.55·×1.75. 정수 반올림. 3성 희귀도별 추가배율·레벨강화·장비·속성상성·치명타·회피는 아직 넣지 않았다. 3성표는 희귀도 보정 전 기준값이다.</p><p>같은 라운드의 3조우 사이에는 체력회복/부활 없음. 라운드별 실험은 체력을 채워 별도로 시작한다. 이것은 무료 즉시회복을 확정한 규칙이 아니며, 라운드 사이 치료시간·비용은 기존 미정 상태를 유지한다.</p><h2>10R 시뮬레이션</h2>'''
rows=[]
for stars,v in r['balanced_role_compositions'].items():rows.append([stars,v['clears'],v['tested'],str(v['composition_clear_pct'])+'%',str(v['min_remaining_pct'])+'~'+str(v['max_remaining_pct'])+'%'])
text+=table(['별순서: 방어/공격/지원','돌파조합','총조합','돌파조합비율','성공시 잔여체력'],rows)
text+='<p><strong>위 비율은 확률형 승률이 아니라 125개 편성 중 성공한 조합의 비율이다.</strong> 같은 편성은 같은 결과가 나온다. 모든 역할·순서·동일종 중복까지 허용한 3,375개 조합에서도 1성만 또는 2성1마리 편성은10R돌파0개였다. 2성2마리라도 방어병을 앞세우고 공격병을 강화하는 순서가 중요하다. 모든 무작위 편성이 자동성공하는 설계는 아니다.</p>'
text+='<p>대표편성: 황금붕어 방패병2성 + 코발트퍼치 창병2성 + 미꾸라지 의무병1성 → 10R일반2+보스 39초, 총체력11.1% 남기고 돌파. 전원2성은34.5초·36.5%남음. 지원회복을 끄면 같은125개2/2/1편성의 성공비율은83.2%로변하므로 회복정책 변경시 재조정해야한다. 3성방어병+1성2명도돌파가능: 별2성두마리를시스템상강제하는잠금은아니다.</p>'
for star in ('1','2','3'):
 text+=f'<h2>병사 {star}성 · 체력/공격/방어</h2>'+table(['병사ID','병사','어혼조합','역할','체력','공격','방어'],[[u['id'],u['name'],u['soul_combination'],roles[u['role']],u['stars'][star]['hp'],u['stars'][star]['atk'],u['stars'][star]['def']] for u in d['soldiers']])
text+='<h2>몬스터 능력치</h2>'+table(['ID','몬스터','체력','공격','방어'],enemies)
text+='<h2>라운드 배치</h2>'+table(['라운드','첫 조우','둘째 조우','셋째 조우'],[[i+1,*v] for i,v in enumerate(d['rounds'])])
text+='<p>추가17독슬라임은4R,18그림자박쥐는9R에배치. 모든일반종포함,같은라운드동일종최대2마리. 3/5/7/10은일반2마리뒤보스. 7R은중간성장벽이며그뒤8~9R은상대적완충구간. 대표1성팀은1~6R,2성방어1마리팀은1~9R까지연속해금가능.</p><h2>검증 범위</h2><p>결정론적 전투모형의수치검증이며실제Godot전투플레이테스트는아니다. 새로작성한 simulate.py, balance.json, results.json,CSV를함께보존한다. 어혼공급·연성비·성장일수·보상·회복대기시간은이번검증대상아님. 실제게임적용/배포없음.</p></main></html>'
(p/'BALANCE_REVIEW.html').write_text(text)
print('HTML + 45 soldier-star rows + 22 enemy rows exported')
