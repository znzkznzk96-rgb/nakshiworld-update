# 현재 인수인계 — v0.77 공개 배포 완료

2026-10-26 사용자 ‘배포해줘 ㅇㅇ’ 명시승인 후 PR #10 병합. 확정 UI·6메뉴 아이콘·노선도·연성 복구와 보스 전체 프레임, 병사 피격/퇴장, 지원 대상 효과, 3성 희귀도 표시 수정 공개 완료. B안 업데이트 화면은 사용자가 별도 APK 수령을 확인했으며 이번 패치에서 로더는 변경하지 않았다.

- 소스 커밋: `c12dd4258f5ca0758d54d5bf42e501fcf36da15d`. 공개 [v0.77](https://github.com/znzkznzk96-rgb/nakshiworld-update/releases/tag/v0.77).
- 작업 CI 및 배포 전체31검사/패키지아트 검사 통과. 빌드 40276445468, 운영검증 40276608550 성공.
- 공개 game-source.zip/PCK/version.json을 직접 다운로드하여 크기·SHA256·소스커밋 대조, ZIP CRC와 프로젝트 파일 확인. 설치 APK 주소의 운영 다운로드도 Actions에서 해시 일치 확인.
- 상세 근거: [공개 검증](docs/qa/release-077/PUBLIC_VERIFICATION.json), [구현 검사](docs/qa/release-077/README.md).
- 기존 아트·밸런스·저장 데이터 보존. 계곡 입장은 준비 중 유지. 휴대폰 적용 성공은 아직 사용자 확인 전.
- 다음 작업: 사용자 실제 화면 확인 및 구체 문제 대응. 현재 복원 기준은 v0.77 전체소스와 후속 작업브랜치 overlay/삭제 명세.
- 배포 전 기록 원문: [이력](docs/historical/before-release-077-public/HANDOFF.md).

## 다음 수정 승인 — 연성/병사 도감
조합-미리보기 간격 축소, 제작한 종만 미리보기, 도감 병사 탭 추가. GAME_BIBLE 최신 결정 참조. 구현/검증 전, 운영0.77 유지.
