# A형 홈 · C형 상세 길잡이 — 구현/로컬 검증 완료, 미배포

2026-10-29 사용자 승인에 따라 PixelLab을 중단하고 내장 imagegen 그림으로 구현했다. 기존 실패 아이콘 미사용. 홈8카드/기본조작5그림카드/별·등급/25주제·동적수치/스크롤/뒤로가기/닫기. 글자와 버튼은 Godot 네이티브, 이미지에 글자굽기없음.

[검증](analysis/guide-ac/REPORT.md), [58검사](analysis/guide-ac/checks/results.json), [아트해시](analysis/guide-ac/ART_MANIFEST.json), [홈실화면](analysis/guide-ac/screens/home_480.png), [상세실화면](analysis/guide-ac/screens/basics_660.png).

공개 운영은v0.94유지. 사용자 “배포해줘 확인하게”로 v0.95 공개 배포 승인. 버전/PCK/세이브/게임수치변경없음. 휴대폰적용미확인. 다음: v0.95 버전/우편 준비, CI 통과 후 배포 및 공개파일 검증.

이전상태와실패이력은 [보존문서](docs/historical/HANDOFF_pre_guide_ac.md).

## 원격 업로드 차단
2026-10-29 사용자 배포 요청 후 create_tree가 자동 승인 검토에서 거절됨. 공개 저장소에 올릴 소스·아트·검증기록 및 목적지를 사용자가 명시 승인해야 한다는 사유. 우회하지 않았으며 원격 head는5636922 유지. v0.95 준비는 로컬에만 존재하고 공개 운영은 v0.94.

사용자가 위 공개 저장소와 파일 범위 안내에 “업로드하고 배포해”로 추가 승인. 원격 저장 및 v0.95 배포 재개.
