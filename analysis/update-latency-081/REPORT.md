# 업데이트 확인 지연 조사·0.81 준비

운영 로더는 매시작 HTTPRequest timeout8초로 version.json을 기다린 뒤 PCK와 main.gd를 동기 로드한다. 서버는 매요청 GitHub latest 리다이렉트를 cacheTtl0/no-cache로 조회(timeout5초). 업데이트가 없더라도 이 경로를 거쳤다. 설치 APK root.gd는 PCK 적용 전에 실행되므로 일반 게임패치로 로더 대기시간 변경을 적용했다고 주장하지 않는다.

수정: 검증된 manifest의 edge cache 30초 신선도/최대600초 보존, 오래된 캐시 응답 뒤 waitUntil 갱신. 캐시 없음은 기존 원본조회. 요청 패치 버전 불일치 시 원본 재조회; 크기/해시검증 유지. 응답 Server-Timing에 manifest 처리시간 표시. 서버 변경은 기존APK에도 적용되지만 게임 로딩/기기/네트워크 대기와 별개다.

초기 외부 측정3회 5.73/5.17/5.03초; 측정환경 프록시가 포함되며 마지막 upstream-service-time293ms였다. 이 숫자를 모두 서버 처리시간이나 휴대폰 체감으로 해석하지 않는다. 운영 개선 후 Server-Timing과 동일환경 측정을 기록한다.

Node 테스트: cache miss/hit/HEAD/stale refresh/원본실패시캐시유지/82.0호환/버전불일치409/invalid path/method/다운로드오류503 통과. 게임전체39검사는실행중. 시안3종은생성도구로직접제시했으며미선택/게임미적용. 10R 라이선스 미적용.

## 실제 주요 원인·수정
main._ready 단계별계측: expedition.setup9,655ms, 물고기26ms, 마을41ms. 18일반×7프레임+보스4시트=130장에매실행opaque_body.prepare의frame별flood-fill이발생. 기존PC패키지시작은PCK mount5ms,script324ms,ready9954ms(합10283ms).

prepare의동일보정결과를빌드때PNG130장으로미리생성하고런타임은그대로로드. 원본PNG불변,준비PNG와기존처리결과RGBA바이트동일검사통과. 소스ZIP에생성PNG포함,저장소엔생성기와검증기보존. 준비이미지누락개발환경은기존보정fallback. 재검증PC ready1031ms(다른검사동시실행),script645ms. Android기기시간측정은아님. 사용자세이브/기존APK교체불필요한게임패치수정.

서버캐시운영배포71f244acde4344448c556de21aad9770: 426ms origin→6ms edge캐시. 30초신선도/뒤갱신확인. 이전CI mock누락수정, 조기공개검사는0.81게시전이라실패. 첫배포40327640590은전체39검사/pack검사성공후releasePOST403; 빌드도중main의workflow가변경돼구커밋target에추가workflow권한요구. 최신main에서재빌드후게시동안main유지. 권한확대/개인토큰사용안함.
