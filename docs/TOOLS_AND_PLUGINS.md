# 도구·플러그인 인수인계 — 2026-11-06

플러그인은 ChatGPT 세션의 연결이며 저장소 파일과 함께 자동 설치/인증되지 않는다. Codex에 같은 이름의 MCP 도구가 없으면 아래 실제 API/CLI 경로를 사용한다. 없는 도구를 있다고 가정하지 않는다. 이 문서는 프로젝트에 관련된 도구만 다루며 무관한 메일·캘린더 등은 필요 없다.

| 도구 | 사용처 | Codex에서 재개 방법 | 인증/검증 |
|---|---|---|---|
| GitHub | 읽기·checkpoint·Actions·Release | git clone/fetch는 공개 읽기 가능. 쓰기는 연결된 GitHub API 또는 인증된 git/gh | 현재 세션은 API 경로 우선, 실패한 push 반복 금지 |
| PixelLab | 물고기·UI·병사 모션 | 아래 API v2 절차와 기존 요청 JSON 재사용 | 비공개 개인 안내를 통해 복원; 이번 신규 생성0 |
| 내장 이미지 생성 | 배경 시안/편집 | 지원되는 image generation 도구 사용; 없으면 기존 원본으로 작업 | 타일 B 확정본 재생성 금지; PixelLab으로 대체하지 않기 |
| ChatGPT Library | 기존 원본·비공개 도구 안내 | Library 연결이 있는 환경에서 정확한 제목으로 검색/읽기/다운로드 | Codex에서 자동 접근 가능하다고 보장하지 않음 |
| Godot/셸/Python/Pillow | import·검사·렌더·파일 무결성 | CODEX_HANDOFF와 workflow의 고정버전/명령 | Pillow는 검사에 사용, 승인 이미지 임의 보정 금지 |
| Cloudflare | 앱 업데이트 gateway | deployment/releases-worker.mjs와 운영검증 workflow 확인 | 콘텐츠 PCK는 GitHub Release 경로. gateway 수정·재배포는 이번 작업에 불필요 |
| 웹/공식 문서 | API 스키마 확인 | PixelLab 공식 openapi.json/llms.txt, 해당 제품 공식 문서 | 오래된 요청의 옵션을 최신 지원 사실로 단정 금지 |

## GitHub 저장법
1. `git ls-remote origin refs/heads/work/tile-release-107`로 원격 head 확인.
2. 변경 경로를 명시하여 비밀키/사용자 세이브를 제외하고 검증.
3. 연결된 API의 create_blob → create_tree(base_tree) → create_commit(parent=head) → update_ref(expected_sha=head, force=false)로 하나의 checkpoint 생성. 텍스트는 tree content로, 바이너리는 base64 blob으로 저장.
4. 원격 head·변경 파일 내용을 확인. 충돌하면 새 head와 diff를 읽고 다른 변경을 보존한다.
`tools/checkpoint.py`는 git push를 수행하므로 인증이 정상인 환경에서만 사용. 현재 환경에서 실패한 경로를 반복하기 위한 도구가 아니다.

main 또는 codex/r2-migration의 game/**·automation/**·release-patch.yml 변경은 게임 배포를 시작한다. 문서만 변경하면 배포되지 않는다. `workflow_dispatch`는 수동 배포 가능하므로 상태조회 용도로 실행하지 않는다. work/tile-release-107의 게임 변경은 검증 CI만 실행한다. 새 work/* 이름이 자동으로 검증 대상인 것은 아니다.

## PixelLab 실제 사용 순서
[PIXELLAB_CONNECTION.md](PIXELLAB_CONNECTION.md)와 물고기 작업이면 [FISH_ART_RULES.md](FISH_ART_RULES.md) 전체를 읽는다. 개인 보관 문서 `NAKSHIWORLD_PIXEL_ACCESS_PRIVATE.md`는 이번에 존재와 내용을 확인했다. 공개 저장소에는 그 문서의 본문·비공개 식별자·복원 경로·키를 복사하지 않는다. 해당 안내의 기존 클라이언트 `pl.py`/`pl_async.py`는 이 공개 저장소 tools/에 없다. 파일이 있는 척 실행하지 말고 개인 안내로 복원한다. 옛 클라이언트의 자동 POST 재시도는 비활성화해야 한다.

- 기본 URL: `https://api.pixellab.ai/v2/`.
- 스키마: `https://api.pixellab.ai/v2/openapi.json`, `https://api.pixellab.ai/v2/llms.txt`. 실제 호출 직전에 해당 endpoint와 입력 필드를 확인한다.
- 인증은 비공개 파일에서 메모리로 읽어 Authorization Bearer 헤더로만 전달. 키를 URL·명령 인자·stdout·로그·커밋에 넣지 않는다.
- 읽기: `GET /balance` 1회. 이전에 HTTP200 검증됨. 이번 인수인계에서는 API 접속/잔액 재확인을 수행하지 않았다.
- 기존 UI 경로: `POST /generate-ui-v2` → HTTP202의 jobID 보존 → `GET /background-jobs/<id>`로 완료 조회 → 응답의 결과 다운로드 → PNG 디코드/해시/육안검수. 필드명은 실제 스키마/응답 기준. 공식 모델 선택과 요청 JSON은 기존 공개 제작 기록을 참조한다.
- 모션 경로: GAME_BIBLE의 2026-10-31 `estimate-skeleton` / `animate-with-skeleton-v3` 기록과 해당 제작 요청을 먼저 조사. 과거 15프레임/비용을 현재 가격·한도로 보장하지 않는다. 기준 이미지·관절·무기·효과·캔버스·앵커를 프레임별 검수한다.
- 동시 유료작업1개, POST 단일요청, 첫1종 검수 후 다음종. timeout은 실패 확정이 아니므로 기존 job/차감 확인 전 재제출 금지. 요청1회와 과금1회분은 다르다.
- 공개 기록은 모델/seed/요청 JSON/참조 역할과 SHA/결과 SHA/jobID/실제차감/검수 결과. 인증 헤더·개인 복구내용 제외.

검증된 예제: [UI 요청](qa/owner-gauge/pixellab/request.json), [UI 검수](qa/owner-gauge/pixellab/REVIEW.json), [라이선스 제작](PIXELLAB_067.json), [6지역 게이지](qa/owner-gauge-six/VERIFICATION.json). 이 예제의 생성 성공은 현재 미사용 아트의 승인이나 유료 재생성 승인이 아니다.

## Cloudflare와 배포
운영 업데이트 주소는 `https://nakshiworld-update-kr.znzkznzk96.workers.dev`. `version.json`과 `patch.pck?v=<code>`를 실제 설치 앱 방식으로 받는 검사는 verify-deployment.yml에 있다. R2 이전용 tools/publish_r2_patch.py 등을 최신 배포 절차로 임의 선택하지 않는다. 현재 release-patch.yml은 검증된 전체소스 복원→검사→PCK/manifest/source ZIP→draft 업로드→공개 순서다. 배포 완료 후 운영검증 성공과 휴대폰 성공을 별개로 기록한다.

## 2026-11-07 — PNG 읽기 경로 확인
작은 PNG에 fetch_blob을 사용하면 바이너리를 UTF-8로 해석하는 UnicodeDecodeError가 발생한 사례가 있다. PNG 손상 판정과 구분한다. 이번20종은 fetch_file의 encoding=base64로 읽어 원래 바이트를 복원했고 승인 원본/ASSETS SHA 및 PNG 디코드가 일치했다. 큰 PNG 쓰기의39조각 전송·원격 재조립·재다운로드 검증은 WORK_STATE의 background_verification 링크 참조. 이 결과를 대화 읽기전용 장애 해결로 해석하지 않는다.
