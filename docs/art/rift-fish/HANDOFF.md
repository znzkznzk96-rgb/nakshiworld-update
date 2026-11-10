# 균열해역 모션 현재 인수인계
2026-11-11 — [현재선택](CURRENT_SELECTION.json): 모션19종 내부통과·14거울날개날치1종보류. 이전20종회차 상세·검증·요청 이력은 [원문](HANDOFF_before_held3_result_20261111.md)에 보존.

## 보류3종 재개 결과
사용자 ‘3종은?마저만들자’ 후 07금간정어리/14거울날개날치/20폭풍다랑어를 각각1모션씩 순차 생성. 승인HD원화는 변경하지 않았고 기존통과17종도 보호. 07외부금빛점·20외부전기파편이 사라져 통과. 14는 날개사이/바깥 회색불투명영역 반복으로 거절, 적용금지.
이번3POST/실제5회분. 기존HD회차47POST/56회분과합계50POST/61회분. 과거96x64파일럿1회분은별도. 모델animate-pixminimax,16frame·좌향·native232폭·고정캔버스. first/last에동일검증원화,drift_threshold0,enhance_prompt=false. 원화재생성0·추가자동POST0.

[이번명세](motion-held3-r3-20261111/SPEC.json) · [요청/차감](motion-held3-r3-20261111/LEDGER.json) · [결과](motion-held3-r3-20261111/MANIFEST.json) · [원격원본검증](motion-held3-r3-20261111/REMOTE_VERIFICATION.json) · [패키지검증](motion-held3-r3-20261111/DELIVERY_VERIFICATION.json).
기존실패기록은모두보존. 이번원본17PNGZIP(입력1+생성16)도종별별도저장. 07모든프레임폭185px이상/20은175px이상으로파이팅상한156논리픽셀대비확인. 원격ZIP/SHA/17PNG디코드/캔버스·원본frame0일치검증통과. native/128/96 atlas는원본픽셀/nearest축소일치검증. 작은LOD를확대하지말고clip의안전표시폭에따라원본선택.
지역4실제종별길이MEANS는미구현이므로아트준비만으로크기값/밸런스임의확정하지않음. 현재선택파일은원화20종/모션19종을추적하며과거회차SPEC를덮지않는다.

## 다음
19종모션사용자검토. 거울날치14는생성모션의회색영역해결전적용금지,추가유료호출없음. 게임적용/배포/폰검증미착수·공개v1.25유지. 게임연결지시때최신Release전체소스+overlay/삭제명세와크기별실제화면검증진행.
