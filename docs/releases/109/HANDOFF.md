# v1.09 배포 재개
2026-11-08 KST. PR42 source e8e6935, CI42384392014 성공. 최초 Build42384973558은 packed_art 우편버전 고정1.08 assertion으로 공개 전 대기. 새 소스/아트 손상 없음. 구 build는 assertion 중단으로 publish 불가,25분 제한 종료 예정.
- packed art 검사 버전을 release.json 인자로 대조하도록 수정하고90초 제한 추가. publish 동시성은 false 유지, 알려진 정지 run과 분리한 v109 group 사용.
- 게임트리/최종73검사 소스는 기존 PREFLIGHT와 동일. 검사도구/배포workflow만 수정, 게임 검사 반복 불필요.
- 다음: 이 수정 PR을 main에 병합 → 새 build/run과 공개3파일 및 운영검증 확인. 휴대폰 적용 별도.
