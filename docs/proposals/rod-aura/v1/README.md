# 강화 오라 — 검토용 Godot 시안

실제 게임 연결/공개 배포 없음. 사용자 요청은 +2/4/6/8/10마다 색/품질 차이, 높은 단계의 뚜렷한 보상감이다. 색은 검토용 은백/하늘/보라/금/무지개이며 최종 확정 아님.

v0.71 전체소스 + 활성 작업브랜치 overlay/삭제명세를 복원한다. 이 폴더의 gd파일4개를 복원 프로젝트의 review_aura/로 복사한다. game/addons/reservoir/angler_scene.gd를 변경하지 않는다. rig_review.gd는 승인 리그의 시안용 복사본으로 오라 뒤/앞 호출만 추가했다. 기존 art/angler_b/ 및 원본 배경/환경 tint/shader/폰트를 사용한다.

Godot4.4.1 그래픽 디스플레이에서 `--path <project> --script review_aura/render_review.gd -- <output>`로 실행하면 1080×800, 336장/24fps 프레임을 만든다. 추가 인자 `still`은 첫 한 장만 생성. `ffmpeg -framerate 24 -i <output>/%04d.png -c:v libx264 -crf 18 -pix_fmt yuv420p -movflags +faststart NAKSHIWORLD_ROD_AURA_REVIEW.mp4`로 인코딩한다.

낮0~7초/밤7~14초. 각 구간 대기2초→캐스팅1.6초→감기/버티기3.4초. 동일 원투낚싯대/곡선/동작/강화외 성능. 곡선을 따라 흐르는 입자와 띠, 세계좌표 곡선 잔광, 최대단계 초릿대 주변 별빛. fishing RNG 호출 없음. 실제폰 성능/전체6종 검수/실제 강화수치 연결 전.

첫 낮 시안에서 상위단계가 약해 보여 +8/+10의 띠폭·채도·경계밝기를 보강했다. game/·automation/·workflow 변경 없이 검토자료만 저장. 검증은 VERIFICATION.json 및 render.log.
