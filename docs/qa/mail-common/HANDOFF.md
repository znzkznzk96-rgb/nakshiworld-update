# 우편 공통화·검사 통합 — 진행 중
2026-11-07 KST. 기존 승인: GAME_BIBLE의 작업 간소화 방향.

- 공개 기준 v1.08, 소스ZIP SHA/CRC 검증 후 전체 복원+활성 overlay/삭제명세 적용.
- mail_gifts.gd에 기존3종 ID·payload·버튼/수령표시/토스트를 통합. 기존3개 claim 진입점·상수는 호환 wrapper로 유지. 과거 우편 원문 불변.
- 기존 valley/arrival/testing/reader 및 새3종 공통 지급·실제쓰기실패/원본save보존·연속수령 검사 통과. 전체71개 검사 진행 중.
- verify-work에 관련검사·독립 재접속·3종/3높이 우편렌더 통합. 옛 valley-gift108 workflow는 수동 이력재현용으로 보존해 push 중복 실행 제거.
- 로컬 실제렌더는 X11 display 연결 실패. 기능검사 실패나 PNG 손상이 아니며 원격CI 렌더로 확인할 예정.
- 새 패치 배포 미승인·미배포. 공개v1.08·기존 사용자 휴대폰 수령 확인대기는 유지.
- 다음: 전체검사 결과와 통합CI run을 기록하고 실제우편 화면을 확인한다.
