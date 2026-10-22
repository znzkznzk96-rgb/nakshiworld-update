> 활성브랜치 WORK_STATE.local_recovery.entry가 있으면 먼저 읽는다. 이전 절대경로가 새 환경에 존재한다고 가정하지 말고 명시된 실제 보존처를 사용한다.

# 새 채팅 이어하기

1. main의 START_HERE/AGENTS/PROJECT_INSTRUCTIONS와 WORK_STATE를 읽는다. work_branch가 가리키는 원격 브랜치의 최신 지침·WORK_STATE·HANDOFF를 우선 확인한다. GAME_BIBLE의 확정/미정 결정을 읽는다.
2. CHANGELOG 최신 항목, 실제 최신 Release 및 관련 Actions, 현재 workflow의 배포 조건을 확인한다. 상태 충돌은 최신 사용자 결정과 실제 원격 증거로 판단한다.
3. 같은 세션에서 읽은 자료는 SHA/관련 diff가 바뀐 경우에만 해당 부분을 갱신한다. 이력은 HANDOFF의 링크나 문제 추적에 필요할 때만 읽는다.
4. 게임 수정이 필요하면 최신 Release 전체소스ZIP을 검증해 복원하고 활성 브랜치 overlay/삭제 명세를 적용한다. 소스·도구·import 캐시는 기준이 맞으면 재사용한다. 문서 작업만이면 게임을 복원/빌드하지 않는다.
5. PixelLab 작업이면 활성 브랜치의 [PIXELLAB_CONNECTION](PIXELLAB_CONNECTION.md)을 먼저 읽고 검증된 기존 경로를 사용한다. 비공개 이어하기 안내를 통해 필요한 설정을 재사용하며, 사용자가 다시 설명/첨부/설치하게 만들지 않는다. 연결 확인만으로 유료 생성하지 않는다.
6. HANDOFF의 다음 작업을 진행한다. 확정사항을 재질문하지 않고, 사용자 준비 중 항목은 임의 설정하지 않는다. 실제 미정 결정이 작업을 막을 때만 관련 질문을 묶어 제시한다. 가능한 독립 작업은 계속한다.
7. 결과/현재 상태를 짧게 보고하고 PROJECT_INSTRUCTIONS의 검사·저장·배포 규칙을 따른다.

## 기록 위치
- 지속되는 기획과 확정/변경 근거: GAME_BIBLE.
- 활성 작업과 다음 단계: WORK_STATE. 상세 현재 인수인계: 활성 브랜치 HANDOFF.
- 변경 결과: CHANGELOG. 상세 검증/로그/해시: HANDOFF가 연결하는 검증 문서.
- 과거 작업은 docs/historical. 모든 파일에 동일 진행 문장을 복사하지 않는다.

## 다음 채팅에 보낼 문구
```text
낚시월드 이어서 하자. https://github.com/znzkznzk96-rgb/nakshiworld-update 의 최신 START_HERE.md와 docs/CONTINUE_HERE.md부터 읽고 WORK_STATE.json이 가리키는 원격 브랜치 작업을 이어가. docs/PROJECT_INSTRUCTIONS.md의 개선된 절차를 따르고 GAME_BIBLE.md의 확정사항은 다시 묻지 마. 실제 원격·배포 상태를 확인한 뒤 진행 상황만 짧게 알려줘.
```
