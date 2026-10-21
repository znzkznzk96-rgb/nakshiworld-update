# 낚시월드 0.62 시각 개선
갱신 2026-10-21. 작업 브랜치 work/visual-polish-062. 원본 main 10b2516 및 v0.61 전체 소스.

## 구현 완료
- 승인된 민트 복어+낚시바늘 아이콘: game/art/icon_main.png. Android legacy/adaptive/themed PNG 교체, 원본 일러스트 변경 없이 크기/마스크 변환.
- 마을 수익 알림 top_y+164: 확대·축소 버튼/배 도착 알림 아래.
- 낚시 캐릭터 1논리픽셀 어두운 외곽선.
- 행동별 짧은 픽셀 물결/기포: 평상시·휴식은 소량, 돌진은 꼬리 방향, 잠수는 상승 기포, 회전/몸부림은 분산. 수면 이동/점프의 기존 물방울 유지.
- 레어 파란 반짝임, 유니크 보라 궤도, 전설 금빛 도트 광선, 신화 무지갯빛 이중 궤도. 몸통/장력 HUD 보호, 전투 파티클90개 상한. 수치/경제/세이브 형식 변경 없음.

## 직접 검증
Godot4.4.1 import 및 PCK export 성공. equipment_verify failures=[], visual_verify failures=[] (5등급×11행동×600프레임; 정상좌표/예산/노멀 물 효과/idle 정지). 짧은 화면과 540×1320 화면에서 수익 알림/캐릭터/등급/행동 렌더 확인. 종료 시 기존 ObjectDB/리소스 잔존 경고 있음; Android 실기기/성능 검증은 아직 없음.

## APK
NAKSHIWORLD_0.62.apk: code62/name0.62, 51,658,608bytes, SHA256 7e6f7e0726124b91a8476e3e4a0bf062ab078e00735f5f67f1eb69daacd03eef. v1/v2/v3 서명 검증 성공, 기존0.60과 서명 인증서 SHA256 5939b25954f72e4aaf2703d5f5f3bf99e400b6ee9891c66af8e4ff2773feb763 일치. ZIP무결성/내장 아이콘 바이트 확인.
다운로드: https://chatgpt.com/api/library/files/libfile_7062a452b7d48191b344365edc2472e2/download
기존 앱 위에 설치. 삭제/세이브 초기화하지 않는다. 기존0.60 APK는 PCK만으로 런처 아이콘 변경 불가. APK0.62는 오래된 patch61을 로드하지 않고 내장62 사용, 향후63+ 업데이트 유지. 실제 휴대폰 설치 확인 전.

## 재현
최신 Release 전체 game-source.zip + 이 브랜치 game/ 덮어쓰기. Godot4.4.1 --headless --editor --path game --import; 별도 XDG_DATA_HOME에서 tests/equipment_verify.gd 및 tests/visual_verify.gd 실행; --export-pack Android patch.pck.
APK: automation/repack_apk.py --baseline patch.pck --original-apk 원본0.60_R2.apk --output build --icon game/art/icon_main.png --code 62 --name 0.62. ImageMagick6 convert 사용. zipalign -p 4 후 apksigner31.0.2로 원래 키 서명 및 verify. 원본 APK/키스토어는 git에 보관하지 않음. 개인 키/비밀번호 공개 금지.
화면 검사: Xvfb와 Godot를 같은 셸에서 실행해야 이 환경의 로컬 디스플레이 접근 가능. --shot 경로 village_income / fight1..4 / beh_run / beh_dive / beh_thrash, 전투는 --vfx-check 사용.

## 배포 상태 / 다음 단계
현재 이 체크포인트에서 미배포. main 반영으로 Actions가 v0.62 전체 소스/PCK/version.json을 생성·게시하도록 진행 예정. 로컬 pack SHA256 49bcc432f337674c49d93c1634e49b1bc6da40a60c41b2f5148dfb53546e6b52, 26,231,168bytes는 로컬 산출물이며 Actions 배포 해시와 구분. 공개 후 Releases/운영 Cloudflare 다운로드·해시 검증, 이 문서 갱신.
이전0.61의 v=61.0 오류는 Worker수정 및 사용자 성공확인 완료. 이번에 Worker 변경 없음.
