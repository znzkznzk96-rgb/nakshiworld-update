## 최신 상태 — 2026-11-07
사용자가 5단계부터 v1.07 공개 배포까지 명시 승인했고, 승인된 새 PNG 원본 검증 및 공개·운영 다운로드 검증을 완료했다. 현재 상태는 WORK_STATE와 docs/releases/tile-107/HANDOFF.md를 따른다. 아래 2026-11-06의 손상 저장본 복구 취소/당시 배포 보류는 과거 기록이며, 새 승인 배경·이번 v1.07 배포 완료 상태를 취소하지 않는다. 파일 손상·승인 해시 불일치 발견 시 즉시 중단 규칙은 계속 유효하다.

## 최우선 — 2026-11-06 최신 사용자 지시
PNG 등 파일 손상·디코드 실패·승인 해시 불일치를 발견하면 모든 진행 작업과 자동 재시도·추가 생성·검사 확장·배포를 즉시 멈추고, 사용자에게 파일명·확인된 증상·영향·완료/미완료를 먼저 알린다. 원인 미확인 상태를 숨기거나 새 채팅방 개설을 반복 권하지 않는다. 사용자 후속 지시 전 임의 복구·대체·재생성하지 않는다.
이번에는 `game/art/bg/tile_sea_clean.png`의 손상된 GitHub 저장본만 삭제한다. 이전 원본 복구 승인은 철회되었다. 별도 승인 원본의 손상 여부는 미확인이며 원본·다른 에셋은 삭제하지 않는다. v1.07 검사·배포는 보류한다.

# 낚시월드 에이전트 진입 규칙

- 작업 절차와 보호 규칙의 원본은 [docs/PROJECT_INSTRUCTIONS.md](docs/PROJECT_INSTRUCTIONS.md)다. 반드시 읽고 따른다. 사용자 최신 지시가 우선한다.
- 새 작업은 [START_HERE.md](START_HERE.md) → [docs/CONTINUE_HERE.md](docs/CONTINUE_HERE.md). 현재 상태는 WORK_STATE, 기획은 GAME_BIBLE, 활성 브랜치 상세는 HANDOFF다.
- 세션 시작은 [docs/STATE_BRIEF.md](docs/STATE_BRIEF.md) 한 장만 읽는다. WORK_STATE·HANDOFF·GAME_BIBLE은 전체를 읽지 않고 필요한 부분만 찾아 읽는다. 체크포인트마다 STATE_BRIEF도 같이 갱신한다.
- 단순 작업 위임(사용자 지시, 2026-11-22): 단순 질문 답변, 문서 정리, 파일 검색·요약처럼 판단이 가벼운 일은 Agent 도구로 haiku 모델 서브에이전트에 맡겨 토큰을 줄인다. 코드 수정·배포·아트·기획 결정·검증 판정은 직접 한다. 위임 결과는 한 줄로만 받아 쓰고, 중요한 사실은 원본과 대조한다.
- 게임 결정 즉시 원격 저장, 세이브 보호, 승인 아트/유료 호출 제한, 배포 전 전체 검사와 실제 공개파일 검증을 생략하지 않는다. 작업 효율 개선은 반복 읽기·중복 기록·불필요한 재검사를 줄이는 것이다.
- 의미 있는 변경은 work/*에 저장하고 원격 SHA/내용 확인. 실제 workflow의 배포 조건을 확인한다. 저장 실패/미검증/휴대폰 미확인을 숨기지 않는다.
- 물고기 제작 전 [docs/FISH_ART_RULES.md](docs/FISH_ART_RULES.md) 전체를 읽는다. 기존 제작 실패를 반복하지 않는다.

- PixelLab은 기존 API v2 경로의 실제 호출이 검증되어 있다. 새 대화에서는 [PixelLab 이어하기](docs/PIXELLAB_CONNECTION.md)를 먼저 읽고 기존 경로를 재사용한다. 도구 목록 검색 실패만으로 사용 불가를 선언하거나 재설치/@태그/재첨부를 기본 요구하지 않는다.

## 도구 자동 사용 (사용자 지시, 2026-11-22)

사용자가 따로 명령하지 않아도 에이전트가 알아서 적용한다.
- 포니테일: `.claude/settings.json`으로 자동 활성화된다. 에이전트는 항상 그 원칙(새 코드 최소화, 기존 것 재사용)을 따른다. 사용자 요청·검증·에러 처리는 줄이지 않는다.
- 그래피파이: 세션 시작 시 `graphify`가 없으면 `pip install --break-system-packages graphifyy`로 직접 설치한다. 사용자에게 설치를 시키지 않는다. 단 게임 코드(.gd)는 지원되지 않아 `game/` 그래프는 만들지 않는다(2026-11-22 시험: 332개 중 16개만 추출). 문서 지도는 토큰을 쓰므로 사용자가 요청할 때만 만든다.
- 헤드룸: PC에서 claude를 감싸는 프록시라 클라우드 세션에서는 적용할 수 없다. 에이전트가 대신 긴 출력은 파일 로그로 저장하고 핵심만 보여 토큰을 줄인다.

## 작업 원칙 추가 (사용자 지시, 2026-11-22)

정보 없이 코딩 금지와 테스트만으로 완료 금지는 위 기존 규칙(원격·HANDOFF 확인 후 수정, 수정/검증/공개/휴대폰 구분)이 담당한다. 아래 두 가지만 추가한다.
- 무조건 동의 금지: 사용자 요청에 위험·충돌·더 단순한 대안이 있으면 작업 전에 근거와 함께 말한다. 알린 뒤 사용자가 결정하면 그 결정을 따른다.
- 같은 실수 반복 금지: 실수나 실패를 확인하면 원인을 짧게 HANDOFF에 기록하고, 같은 방식으로 다시 시도하지 않는다. 새 작업 전에 HANDOFF의 기존 실패 기록부터 확인한다.

## 검증은 최소 출력 (사용자 지시, 2026-11-22)

- 범위: 개발 중에는 바꾼 부분의 관련 검사만, 전체 검사는 배포 직전·세이브·공통 시스템 변경 때 한 번만 돌린다. 문서만 바꾸면 링크·JSON 확인만 하고 게임 검사는 하지 않는다.
- 출력: 검사 결과는 로그 파일에 저장하고 대화에는 "통과 n/n, 실패 n" 한 줄만 쓴다. 실패했을 때만 해당 로그 부분을 읽는다.
- 재실행: 코드가 안 바뀌었으면 같은 검사를 반복하지 않는다. 실패하면 원인을 먼저 확인하고 실패한 검사만 다시 돌린다.
- 보고: 수정 / 검증 / 공개 / 휴대폰 네 칸을 한 줄씩만 쓰고 근거는 링크로 둔다. 해시·로그를 길게 풀어 쓰지 않는다. 휴대폰 확인 여부는 숨기지 않는다.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. When the answer is under a Markdown heading, `graphify section "<heading>"` prints that section's text, so the .md need not be opened. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.
