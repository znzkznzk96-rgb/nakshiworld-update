# 우편 공통화·검사 통합 — 로컬 검증 완료·CI 진행 중
2026-11-07 KST. 기존 승인: GAME_BIBLE의 작업 간소화 방향.

- 공개 기준 v1.08, 소스ZIP SHA/CRC 검증 후 전체 복원+활성 overlay/삭제명세 적용.
- mail_gifts.gd에 기존3종 ID·payload·버튼/수령표시/토스트를 통합. 기존3개 claim 진입점·상수는 호환 wrapper로 유지. 과거 우편 원문 불변.
- 기존 valley/arrival/testing/reader 및 새3종 공통 지급·실제쓰기실패/원본save보존·연속수령 검사 통과. 전체71개와 별도 프로세스 재접속 검사 통과.
- verify-work에 관련검사·독립 재접속·3종/3높이 우편렌더 통합. 옛 valley-gift108 workflow는 수동 이력재현용으로 보존해 push 중복 실행 제거.
- 로컬렌더 초기 X11 연결 실패 후 같은 프로세스 환경에서 Xorg/Godot 실행으로 해결. 우편3종×3높이×수령전/후/상세27장 생성, 기존구현 대비 우편영역 픽셀27/27 동일. [화면비교](SCREEN_COMPARISON.json), [실화면](mail-overview.png).
- 새 패치 배포 미승인·미배포. 공개v1.08·기존 사용자 휴대폰 수령 확인대기는 유지.
- 원격 코드 checkpoint `272e5f466901109c111111910a7505d59404f6fc` 내용 확인. 통합CI [42379577723](https://github.com/znzkznzk96-rgb/nakshiworld-update/actions/runs/42379577723) 진행 중.
- 다음: 통합CI의 전체회귀·공통화면 결과 확인 후 최종 기록 저장. 검증 상세는 [VERIFICATION](VERIFICATION.json).
