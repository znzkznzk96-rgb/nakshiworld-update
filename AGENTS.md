# 낚시월드 에이전트 진입 규칙

- 작업 절차와 보호 규칙의 원본은 [docs/PROJECT_INSTRUCTIONS.md](docs/PROJECT_INSTRUCTIONS.md)다. 반드시 읽고 따른다. 사용자 최신 지시가 우선한다.
- 새 작업은 [START_HERE.md](START_HERE.md) → [docs/CONTINUE_HERE.md](docs/CONTINUE_HERE.md). 현재 상태는 WORK_STATE, 기획은 GAME_BIBLE, 활성 브랜치 상세는 HANDOFF다.
- 게임 결정 즉시 원격 저장, 세이브 보호, 승인 아트/유료 호출 제한, 배포 전 전체 검사와 실제 공개파일 검증을 생략하지 않는다. 작업 효율 개선은 반복 읽기·중복 기록·불필요한 재검사를 줄이는 것이다.
- 의미 있는 변경은 work/*에 저장하고 원격 SHA/내용 확인. 실제 workflow의 배포 조건을 확인한다. 저장 실패/미검증/휴대폰 미확인을 숨기지 않는다.
- 물고기 제작 전 [docs/FISH_ART_RULES.md](docs/FISH_ART_RULES.md) 전체를 읽는다. 기존 제작 실패를 반복하지 않는다.

- PixelLab은 기존 API v2 경로의 실제 호출이 검증되어 있다. 새 대화에서는 [PixelLab 이어하기](docs/PIXELLAB_CONNECTION.md)를 먼저 읽고 기존 경로를 재사용한다. 도구 목록 검색 실패만으로 사용 불가를 선언하거나 재설치/@태그/재첨부를 기본 요구하지 않는다.
