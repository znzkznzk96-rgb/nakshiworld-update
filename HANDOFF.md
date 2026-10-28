# v0.89 — 도감과 수족관 UI 최종검증·배포 준비

사용자 직접 승인: 기존 도감 v0.89에 수족관 UI 높이 정리만 추가 후 공개 저장·배포. 수조 위치/크기 유지, 하단 버튼 높이40/45→32/34, 바닥여백10→34. aquarium_b 검사는480/660에서 수조가 기존직사각형과 동일함을 확인. 실제4화면검수통과.
도감21아이콘/목록·상세완료, 기존51검사통과후 이번수정전체검사중. 공개v0.88 유지. 추가유료생성0(앞선재개3회분).
다음: work브랜치저장→CI→승인v0.89공개→ZIP/PCK/manifest/운영다운로드검증. [상세](analysis/codex-089/REPORT.md), [검증](analysis/release-089/VERIFICATION.json). 이전인계 docs/historical/HANDOFF_pre_codex089.md.

서버검사40707506022에서 도감/수족관 통과 후 기존 expedition_result 테스트 종료시2리소스잔류 오류로 실패. 테스트에서 음향끄기/참조해제/추가프레임으로 종료를 안정화;게임코드/콘텐츠변경없음. 재검사후진행.

재검사에서 expedition_result 통과, bag_formation에서 동일음향종료오류. 전체검사파일을 점검해 나머지음향미차단 UI테스트2종(bag_formation/bag_interaction)에만 무음설정추가. 음향검사·게임코드는변경없음.
