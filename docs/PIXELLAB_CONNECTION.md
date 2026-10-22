# PixelLab 호출 확인 — 2026-10-22

기존 PixelLab API v2 호출 경로를 찾아 실제 재사용했다. 공개 API `GET /v2/balance`는 HTTP200, UI 생성 `POST /v2/generate-ui-v2`는 HTTP202를 반환했고 결과 조회가 completed로 끝났다. 따라서 이전의 '이 환경에서 PixelLab 사용 불가' 판단은 최신 실제 호출 증거로 대체한다. 플러그인 목록 검색 실패만으로 미설치/인증 부재를 단정하지 않는다.

- 기존 제작 기록: [0.64](PIXELLAB_064.json), [0.67](PIXELLAB_067.json), [0.68](PIXELLAB_MAIL_068.json).
- 현재 공식 API 스키마: https://api.pixellab.ai/v2/openapi.json
- 주인게이지 신규 아트 결과: [검수 기록](qa/owner-gauge/pixellab/REVIEW.json).
- 이번 UI Pro는 단일요청/단일결과였으며 사용량10회분이 기록됐다. 자동 재시도 또는 다음 지역 생성은 하지 않았다.
- 비공개 접속정보/복구자료/인증 복구 절차는 이 공개 저장소에 기록하지 않는다. 계정/권한 변경도 수행하지 않았다.
- 기능검증 완료와 아트품질 통과를 구분한다. 신규 프레임은 글자/진행바 공간 부족으로 보류, 게임용 에셋으로 채택하지 않았다. 게임코드·가격·Release 변경 없음.
