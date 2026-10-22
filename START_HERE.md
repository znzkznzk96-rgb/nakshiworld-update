# 낚시월드 — 새 채팅 시작점

**새 대화에서 첨부 ZIP이나 긴 설명을 다시 요구하지 않는다.** 최신 상태와 기획은 이 GitHub 저장소에서 읽는다.

1. 이 문서 → `AGENTS.md` → [`docs/PROJECT_INSTRUCTIONS.md`](docs/PROJECT_INSTRUCTIONS.md) → [`docs/CONTINUE_HERE.md`](docs/CONTINUE_HERE.md) → [`docs/GAME_BIBLE.md`](docs/GAME_BIBLE.md) 순서로 읽는다.
2. `WORK_STATE.json`의 작업 브랜치를 확인하고 해당 브랜치 최신 `HANDOFF.md`를 읽는다. 브랜치가 여럿이면 최근 커밋만으로 고르지 말고 문서의 목표/상태를 비교한다.
3. GitHub 실제 최신 Release, Actions 및 현재 workflow를 확인해 구현/검증/배포/실기기 확인을 나눈다.
4. 게임 코드 변경은 최신 Release 전체 `game-source.zip`에 유지보수 overlay를 적용한다. `game/`은 전체 프로젝트가 아니다.
5. 이미 기록된 사용자 결정을 묻지 않는다. 누락 자료 요청은 저장소/Release/기존 원격 작업 브랜치 모두에 없는 구체 파일이 있을 때만 한다.

## 지속성 약속

게임 결정과 세계관의 원본은 게임 코드 밖의 `docs/GAME_BIBLE.md`다. 사용자가 새로 확정하거나 바꾼 게임 결정은 코드 수정 여부와 무관하게 같은 작업에서 즉시 날짜·상태·근거와 함께 바이블에 기록한다. 그 결정에 의존하는 구현 전, 관련 변경물·`HANDOFF.md`·`WORK_STATE.json`을 `work/*`에 원격 checkpoint로 저장하고 새 SHA와 파일 내용을 다시 읽어 확인한다. 같은 메시지의 여러 결정은 한 checkpoint로 묶어도 된다. 원격 저장을 전부 시도해도 실패하면 미저장 대기로 명시하고 사용자에게 알린다. 매 작업은 인수인계 지점을 남기며, 작업 완료와 공개 배포는 구분한다.

## 기준 버전

과거 0.61 백업은 복구 자료일 뿐 최신이 아니다. 실제 운영 버전은 매 작업 시 GitHub Release에서 확인하고 `WORK_STATE.json`과 대조한다.
