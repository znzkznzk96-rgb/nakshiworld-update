# PixelLab — 새 대화 이어하기

## 먼저 읽을 규칙
PixelLab은 이 프로젝트에서 계속 사용해 왔으며, 기존 **API v2 경로로 실제 접속과 이미지 수신까지 검증**했다. 플러그인 검색부터 다시 시작하지 않는다. 도구 목록에 안 보인다는 이유만으로 미설치/사용불가라고 판단하거나 사용자에게 @태그/재설치/키재전달을 기본 요구하지 않는다.

## 고정 이어하기 순서
1. WORK_STATE의 활성 브랜치에서 이 문서와 최신 HANDOFF를 읽는다. 이전 채팅의 '연결부재' 문구보다 아래 실제호출 증거를 우선한다.
2. 사용자 개인 보관 문서 **NAKSHIWORLD_PIXEL_ACCESS_PRIVATE.md**를 Library 스킬로 정확한 제목 검색 후 읽는다. 그 문서가 기존 설정 재사용과 새 작업공간 복원 방법의 원본이다. 본문/비공개 식별자/인증정보/복구상세는 이 공개 저장소나 채팅에 옮기지 않는다.
3. 유효한 기존 설정이 있으면 재사용한다. 새 작업공간이면 개인 안내 절차를 따른다. 과거 대화 전체나 여러 원본 ZIP을 다시 뒤지지 않는다.
4. 실제 아트 작업에 필요할 때만 GET /v2/balance로 읽기 확인을 한다. 이어하기 문서 수정/상태 확인만으로 유료 생성하지 않는다. 잔액은 과거 수치로 단정하지 않는다.
5. 연결 성공이면 승인된 작업을 계속한다. 실패하면 해당 HTTP코드/네트워크/설정 단계만 구분해 조사한다. 실제 오류 없이 '이 환경에서는 안 된다'고 말하지 않는다.
6. 유료 POST는 단일요청이며 jobID를 먼저 보존하고 기존작업을 GET으로 조회한다. 동시1개/자동재시도금지/불합격후중단/실제차감 기록은 PROJECT_INSTRUCTIONS와 FISH_ART_RULES를 따른다.

## 확인된 공개 근거
- API 기본주소: https://api.pixellab.ai/v2/
- 실제 읽기 확인: GET /balance HTTP200.
- 실제 주인게이지 생성: POST /generate-ui-v2 HTTP202 → background-jobs/<id> completed → 단일PNG 수신.
- 현재 공식 스키마: https://api.pixellab.ai/v2/openapi.json
- 이전 제작 기록: [0.64](PIXELLAB_064.json), [0.67](PIXELLAB_067.json), [0.68](PIXELLAB_MAIL_068.json).
- 실제 요청/결과/작업ID/차감/품질검수: [첫 게이지 검수](qa/owner-gauge/pixellab/REVIEW.json), [요청](qa/owner-gauge/pixellab/request.json).

## 현재 아트 상태
기존첫불합격본과별개로, 사용자의 후속6장승인에따라 지역별1장/총6장 생성·검수·등록을 완료했다. 단일요청6회/결과6장/60회분/추가재생성0. [6종검증](qa/owner-gauge-six/VERIFICATION.json), [모음](previews/owner-six-applied.png)은저장소루트의 docs/previews/owner-six-applied.png를참조한다. 현재상태는 WORK_STATE/HANDOFF를우선한다. 연결복원만으로추가유료생성하지않는다. 가격보류·배포금지유지.

## 기록 보호
공개 문서에는 공개 API 사용법과 연결 성공 근거만 남긴다. 실제 인증값·개인 복구정보는 개인 안내와 승인된 비공개 설정에만 둔다. 설치/연결 확인, 생성완료, 품질통과, 게임적용, 배포를 구분한다.
