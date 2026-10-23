"""Build offline review gallery and screenshot contact sheets; needs Pillow."""
import base64,json,pathlib,re,html
from PIL import Image,ImageDraw,ImageFont
P=pathlib.Path(__file__).parent
SCREENS=[('map-trail','A · 연결 지도','다음 목표가 잘 보이는 기본 추천안'),('map-doors','B · 문이 늘어선 복도','백룸 분위기를 강조하는 배치'),('map-journal','C · 탐사 기록부','제작량이 적고 목록을 읽기 편한 배치'),('progress-compact','A · 작은 진행창','낚시·마을 화면을 덜 가리는 기본 추천안'),('progress-party','B · 병사 카드창','키운 병사의 별과 레벨을 함께 표시'),('progress-corridor','C · 작은 복도 장면','공략을 보는 재미, 추가 애니메이션 필요')]
# Set NW_PREVIEW_FONT to the existing project's font/Galmuri11.ttf.
import os
fontpath=pathlib.Path(os.environ.get('NW_PREVIEW_FONT','simulation-source/font/Galmuri11.ttf'))
font=ImageFont.truetype(str(fontpath),26)
for start,name in [(0,'selection-overview'),(3,'progress-overview')]:
 sheet=Image.new('RGB',(1680,1190),'#182f34');d=ImageDraw.Draw(sheet)
 for i,(stem,title,caption) in enumerate(SCREENS[start:start+3]):
  x=10+i*560;d.text((x+10,15),title,font=font,fill='#fff1cf');sheet.paste(Image.open(P/'screens'/f'{stem}.png').convert('RGB'),(x+10,60))
 d.text((20,1150),'구조 시안 · 병사/마을 임시 표현 · 실제 게임 미적용',font=font,fill='#fff1cf')
 sheet.save(P/'screens'/f'{name}.png',optimize=True)

def inline(s):
 s=html.escape(s)
 s=re.sub(r'\*\*(.*?)\*\*',r'<strong>\1</strong>',s)
 s=re.sub(r'`([^`]+)`',r'<code>\1</code>',s)
 # Documentation relative links point to the durable project source.
 s=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',lambda m:'<a href="https://github.com/znzkznzk96-rgb/nakshiworld-update/blob/work/valley-runtime/docs/design/backrooms-reservoir/'+m[2]+'">'+m[1]+'</a>',s)
 return s

def markdown(s):
 lines=s.splitlines();out=[];i=0
 while i<len(lines):
  l=lines[i]
  if l.startswith('|'):
   rows=[]
   while i<len(lines) and lines[i].startswith('|'):
    cells=lines[i].strip('|').split('|')
    if not all(re.fullmatch(r'[ :\-]+',c) for c in cells):rows.append(cells)
    i+=1
   out.append('<div class="table-scroll"><table>'+''.join('<tr>'+''.join(f'<{"th" if n==0 else "td"}>'+inline(c.strip())+f'</{"th" if n==0 else "td"}>' for c in row)+'</tr>' for n,row in enumerate(rows))+'</table></div>');continue
  if l.startswith('#'):
   level=len(l)-len(l.lstrip('#'));out.append(f'<h{min(level+1,6)}>'+inline(l[level:].strip())+f'</h{min(level+1,6)}>')
  elif l.startswith('- '):out.append('<p class="bullet">• '+inline(l[2:])+'</p>')
  elif l.strip():out.append('<p>'+inline(l)+'</p>')
  i+=1
 return '\n'.join(out)
sections=[]
for start,label,desc in [(0,'던전 선택 화면 3안','추천 A · 10개 방을 연결하고 다음 목표를 한눈에 보여주기'),(3,'공략 진행 화면 3안','추천 A · 작은 하단 창을 기본으로, 상세 편성은 필요할 때 열기')]:
 cards=[]
 for stem,title,caption in SCREENS[start:start+3]:
  data=base64.b64encode((P/'screens'/f'{stem}.png').read_bytes()).decode()
  cards.append(f'<article class="card"><h3>{title}</h3><p>{caption}</p><button class="zoom" aria-label="{title} 크게 보기"><img src="data:image/png;base64,{data}" alt="{title} 저수지 백룸 UI 시안" width="540" height="1080"></button></article>')
 sections.append(f'<section><h2>{label}</h2><p>{desc}</p><div class="cards">'+''.join(cards)+'</div></section>')
results=json.loads((P/'model-results.json').read_text())
labels=['저수지 1성 Lv.1','저수지 1성 Lv.5','저수지 2성 Lv.8','저수지 3성 Lv.10','계곡 비교 1성 Lv.5','계곡 비교 2성 Lv.8','계곡2명 Lv.8 + 저수지1명','계곡2명 Lv.10 + 저수지1명']
options=''.join(f'<option value="{key}">{label}</option>' for key,label in zip(results['cases'],labels))
styles='''*{box-sizing:border-box}body{margin:0;background:#f3efdf;color:#263c3e;font-family:system-ui,-apple-system,sans-serif;line-height:1.7}main{max-width:1240px;margin:auto;padding:32px 22px 60px}h1{font-size:clamp(26px,4vw,42px);line-height:1.25}h2{margin-top:42px;font-size:26px}h3{font-size:19px}a{color:#16736d}p{max-width:90ch}small,.note{color:#5a6662}.badge{display:inline-block;background:#215d59;color:#fff;padding:4px 12px;border-radius:5px;font-size:14px}.cards{display:grid;grid-template-columns:repeat(3,1fr);gap:20px}.card{padding:16px;background:#fffaf0;border:1px solid #d4c8ab;border-radius:12px}.card h3{margin:0}.card p{font-size:14px;min-height:48px}.zoom{padding:0;border:0;background:none;cursor:zoom-in;width:100%}.zoom img{width:100%;height:auto;display:block;border-radius:5px;image-rendering:pixelated}button,select{font:inherit}select{max-width:100%;padding:8px;background:#fffaf0;border:1px solid #8b9b8c;border-radius:5px}button.action{background:#215d59;color:white;border:0;padding:9px 16px;border-radius:6px;cursor:pointer}.compare{padding:22px;border:1px solid #b7c4b2;border-radius:12px;background:#e5eddf}.stages{display:grid;grid-template-columns:repeat(10,1fr);gap:6px;margin:20px 0}.stage{text-align:center;padding:10px 0;background:#d1cbc0;border-radius:5px}.stage.pass{background:#286e61;color:white}.meter{height:18px;background:#c2cbbf;overflow:hidden;border-radius:4px;margin:6px 0 14px}.meter span{display:block;height:100%;width:0;background:#318f84}.hp span{background:#769f45}.sim{max-width:620px;padding-top:16px}.table-scroll{overflow-x:auto;margin:18px 0}table{border-collapse:collapse;min-width:620px;width:100%;font-size:14px}td,th{text-align:left;padding:10px 12px;border-bottom:1px solid #d2d0bf}th{background:#e3e8db}details{margin-top:32px;border-top:1px solid #b3bba9;padding-top:20px}summary{font-size:22px;cursor:pointer;font-weight:700}code{background:#e3e6db;padding:1px 4px}#fullplan h2{font-size:28px}#fullplan h3{margin-top:36px;font-size:24px}dialog{border:0;padding:14px;background:#182f34;max-width:95vw;max-height:95vh;border-radius:8px}dialog::backdrop{background:#000b}dialog img{display:block;max-width:85vw;max-height:82vh;width:auto;height:auto;image-rendering:pixelated}dialog button{display:block;margin:0 0 10px auto}.bullet{margin:6px 0 6px 10px}@media(max-width:720px){main{padding:24px 14px}.cards{grid-template-columns:1fr}.card{max-width:420px;margin:auto;width:100%}.card p{min-height:0}.stages{grid-template-columns:repeat(5,1fr)}}@media(prefers-reduced-motion:reduce){*{scroll-behavior:auto}}'''
script='''const DATA=MODEL_DATA;let timer=null;const $=id=>document.getElementById(id);function stop(){if(timer!==null)clearInterval(timer);timer=null;$('play').disabled=false;}function show(){stop();const c=DATA.cases[$('team').value];$('stages').innerHTML=c.stages.map((s,i)=>`<div class="stage ${s.win?'pass':''}">${i+1}<br>${s.win?'돌파':'실패'}</div>`).join('');const last=c.stages[9];$('result').textContent=`1-10 ${last.win?'성공':'실패'} · 전투 ${last.battle_seconds}초 · 종료 체력 ${last.hp_pct}% · 본체 레벨 강화비 ${c.level_gold.toLocaleString()}비늘`;$('progressbar').style.width='0%';$('hpbar').style.width='100%';$('state').textContent='1-10 계산 재생 대기. 2초 전투 틱을 0.2초로 압축해서 보여줍니다.';}
function play(){stop();$('play').disabled=true;const c=DATA.cases[$('team').value];const t=c.team;let full=t.reduce((a,b)=>a+b.hp,0),hp=full,enemy=4300,tick=0;const attack=t.reduce((a,b)=>a+b.atk,0)*100/132,armor=t.reduce((a,b)=>a+b.defense,0)/3,incoming=175*100/(100+armor),heal=t.reduce((a,b)=>a+b.heal,0);$('state').textContent='출발 → 도착 (이동5초는 재생에서 생략)';timer=setInterval(()=>{tick++;enemy=Math.max(0,enemy-attack);if(enemy>0)hp=Math.min(full,hp-incoming+heal);hp=Math.max(0,hp);const progress=100*(1-enemy/4300),health=100*hp/full;$('progressbar').style.width=progress+'%';$('hpbar').style.width=health+'%';$('state').textContent=`전투 ${tick*2}초 · 공략 ${progress.toFixed(1)}% · 부대 체력 ${health.toFixed(1)}%`;if(enemy===0||hp===0||tick>=45){$('state').textContent+=(enemy===0?' · 돌파 성공':' · 귀환');stop();}},200);}
$('team').addEventListener('change',show);$('play').addEventListener('click',play);document.querySelectorAll('.zoom').forEach(b=>b.addEventListener('click',()=>{$('large').src=b.querySelector('img').src;$('large').alt=b.querySelector('img').alt;$('dialog').showModal();}));$('close').addEventListener('click',()=>$('dialog').close());show();'''.replace('MODEL_DATA',json.dumps(results,ensure_ascii=False))
page=f'''<!doctype html><html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>낚시월드 · 저수지 백룸 기획과 6개 시안</title><style>{styles}</style></head><body><main><span class="badge">기획 초안 · 게임 미적용</span><h1>어혼으로 만든 탐험대,<br>저수지 너머의 열 개 방</h1><p>낚시 → 어혼 수집 → 연성·육성 → 3마리 파견. 저수지에 머물러 마지막 방을 깨거나, 계곡 병사를 데려와 다시 도전하는 작은 백룸 콘텐츠.</p><p class="note">명칭·방향은 대화 기준. 수치·병사 이름·화면 선택은 검토안입니다. 기존 게임 폰트/패널을 사용했으며, 물고기 병사와 마을은 임시 표현입니다. 이미지를 누르면 크게 볼 수 있습니다.</p>{''.join(sections)}<section class="compare"><h2>성장 경로 비교</h2><p>고정 수치로 계산한 돌파 가능 구간입니다. 실제 플레이 시간이나 승률 시뮬레이션이 아닙니다. 계곡은 기본 능력치 1.6배의 비교용 가상 병사입니다.</p><label for="team">편성 선택 </label><select id="team">{options}</select><div id="stages" class="stages" aria-live="polite"></div><p id="result"></p><div class="sim"><button id="play" class="action">1-10 전투 계산 재생 · 10배속</button><p id="state" aria-live="polite"></p><label>공략률</label><div class="meter"><span id="progressbar"></span></div><label>부대 체력</label><div class="meter hp"><span id="hpbar"></span></div></div></section><details open><summary>전체 기획 읽기 · 분류, 연성, 능력치, 보상, 10개 던전</summary><div id="fullplan">{markdown((P/'PLAN.md').read_text())}</div></details><p class="note">2026-10-24 KST · 공개 배포 없음 · 모든 자료는 작업 브랜치의 docs/design/backrooms-reservoir에 보관.</p></main><dialog id="dialog"><button id="close" class="action">닫기</button><img id="large" alt="확대 시안"></dialog><script>{script}</script></body></html>'''
(P/'review.html').write_text(page)
(P/'review-script.js').write_text(script)
print('Built review.html and two contact sheets')
