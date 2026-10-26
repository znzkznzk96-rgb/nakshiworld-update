# 업데이트 확인 지연 조사·0.81 준비

운영 로더는 매시작 HTTPRequest timeout8초로 version.json을 기다린 뒤 PCK와 main.gd를 동기 로드한다. 서버는 매요청 GitHub latest 리다이렉트를 cacheTtl0/no-cache로 조회(timeout5초). 업데이트가 없더라도 이 경로를 거쳤다. 설치 APK root.gd는 PCK 적용 전에 실행되므로 일반 게임패치로 로더 대기시간 변경을 적용했다고 주장하지 않는다.

수정: 검증된 manifest의 edge cache 30초 신선도/최대600초 보존, 오래된 캐시 응답 뒤 waitUntil 갱신. 캐시 없음은 기존 원본조회. 요청 패치 버전 불일치 시 원본 재조회; 크기/해시검증 유지. 응답 Server-Timing에 manifest 처리시간 표시. 서버 변경은 기존APK에도 적용되지만 게임 로딩/기기/네트워크 대기와 별개다.

초기 외부 측정3회 5.73/5.17/5.03초; 측정환경 프록시가 포함되며 마지막 upstream-service-time293ms였다. 이 숫자를 모두 서버 처리시간이나 휴대폰 체감으로 해석하지 않는다. 운영 개선 후 Server-Timing과 동일환경 측정을 기록한다.

Node 테스트: cache miss/hit/HEAD/stale refresh/원본실패시캐시유지/82.0호환/버전불일치409/invalid path/method/다운로드오류503 통과. 게임전체39검사는실행중. 시안3종은생성도구로직접제시했으며미선택/게임미적용. 10R 라이선스 미적용.
