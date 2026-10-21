# 낚시월드 0.63 시각 개선
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
NAKSHIWORLD_0.63.apk: code63/name0.63, 51,658,608bytes, SHA256 e2b5e3884cc51f2d9136f171d2d3d5e7722dacea2a5fc062638972d33551ea13. v1/v2/v3 서명 검증 성공, 기존0.60과 서명 인증서 SHA256 5939b25954f72e4aaf2703d5f5f3bf99e400b6ee9891c66af8e4ff2773feb763 일치. ZIP무결성/내장 아이콘 바이트 확인.
다운로드: https://chatgpt.com/api/library/files/libfile_96d9456e4a2c81919e76cb4c2d828ac5/download
기존 앱 위에 설치. 삭제/세이브 초기화하지 않는다. 기존0.60 APK는 PCK만으로 런처 아이콘 변경 불가. APK0.63는 오래된 patch61을 로드하지 않고 내장63 사용, 향후64+ 업데이트 유지. 실제 휴대폰 설치 확인 전.

## 재현
최신 Release 전체 game-source.zip + 이 브랜치 game/ 덮어쓰기. Godot4.4.1 --headless --editor --path game --import; 별도 XDG_DATA_HOME에서 tests/equipment_verify.gd 및 tests/visual_verify.gd 실행; --export-pack Android patch.pck.
APK: automation/repack_apk.py --baseline patch.pck --original-apk 원본0.60_R2.apk --output build --icon game/art/icon_main.png --code 63 --name 0.63. ImageMagick6 convert 사용. zipalign -p 4 후 apksigner31.0.2로 원래 키 서명 및 verify. 원본 APK/키스토어는 git에 보관하지 않음. 개인 키/비밀번호 공개 금지.
화면 검사: Xvfb와 Godot를 같은 셸에서 실행해야 이 환경의 로컬 디스플레이 접근 가능. --shot 경로 village_income / fight1..4 / beh_run / beh_dive / beh_thrash, 전투는 --vfx-check 사용.

## 배포 상태 / 다음 단계
v0.63 공개 완료. 소스 커밋 c232e0deac2b21d3f2fb104d642ddd9d178bc216. Actions 39528181818 success. 전체 소스 ZIP/patch.pck/version.json 공개 확인. 운영 Cloudflare version.json code63/name0.63 및 /patch.pck?v=63.0 HTTP200 다운로드, GDPC 헤더/크기/SHA256 일치 검증 완료.
공개 PCK: 26,701,872bytes, SHA256 6bb316e1cf85f280fe80f9438c2afcb0d5fd4497482a90bbec43423af0ff9ab3.
전체 소스 ZIP: 25,884,151bytes, SHA256 328e330410c2542217ff8441ac341f25e8b83c8a40b93190f6f6a6ef28cef6c1. 실제 압축 검사 및 변경 main/root/icon/visual_verify가 로컬 검증본과 같은지 확인.
APK는 로컬 복구 프로젝트로 만들었으므로 내장 pack 바이너리와 CI 공개PCK는 import환경 차이로 해시가 다름. 변경 소스/아이콘은 정확히 일치. APK의 패키지 com.sangjun.dotfishing, native versionCode63/versionName0.63 확인.
남은 일: 사용자 휴대폰에서 기존 앱 위에 APK0.63 설치 후 아이콘/실제 동작 확인. 이미0.60/0.61/0.62 앱을 쓰면 게임 콘텐츠는 재실행 자동업데이트, 런처 아이콘은 APK 필요. 휴대폰 성공 여부를 아직 확인한 것으로 기록하지 않는다.
이전0.61의 v=61.0 오류는 Worker수정 및 사용자 성공확인 완료. 이번에 Worker 변경 없음.

## 0.62 → 0.63 보완
0.62는 b2ef49be37b7aac3a056f3cb76aed1f3bb677ee3에서 게시됨. 마지막 검토에서 전투 수면 clip이 공중 drop도 숨기는 것을 발견. 0.63은 drop 예외 처리 및 회귀 테스트 추가. 공개된0.62를 덮어쓰지 않음. 0.63 540×1320 수면 스치기 렌더 및 기포/공중 물방울 회귀 검사 통과. 새 APK0.63이 최종 권장본이며 이전APK0.62는 중간 산출물.
