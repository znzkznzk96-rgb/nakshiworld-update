# 현재 상태 요약 (세션 시작 시 이것만 먼저 읽는다)

갱신: 2026-11-24. WORK_STATE.json이 바뀌는 체크포인트마다 이 문서도 같이 고친다. 이 문서와 WORK_STATE가 다르면 WORK_STATE가 우선이다.

## 한눈에
- 작업 브랜치: work/forge-138 (main에서 작업하지 않는다)
- 마지막 공개본: v1.45(펫 오두막 전 탭 글자 또렷하게 + 뽑기 슬롯 그림 폰에서 빈 칸으로 나오던 문제 수정, 2026-11-24). 공개 완료, 휴대폰 실기 확인 미완료. 원인 두 가지를 기억할 것: (1) UI 글자는 text_layer.gd처럼 화면 배율(get_viewport_transform) 크기로 그린다. 작은 크기로 그려 늘리면 한글이 깨진다 (2) 폰(APK)에는 원본 PNG가 없다. Image.load_from_file 대신 load()로 읽는다. 컴퓨터 테스트는 통과해도 폰에서 비는 이유다. 확인은 godot --export-pack으로 포장한 뒤 --main-pack으로 돌려서 한다
- 업데이트 방식(v1.50, 2026-11-24 개편): 켜기 화면(root.gd, APK 안)이 version.json을 한 번 읽고, 새 버전이면 patch.pck 하나를 받는다(5초 안에 끝나면 켜기 화면에서 바로 적용, 아니면 게임을 먼저 켜고 백그라운드로 받아 다음 실행 때 적용). sha256·크기·GDPC 머리가 맞을 때만 user://upd/ 에 저장. 예전 Range 조각 업데이터(incremental_update.gd)는 삭제됨.
- patch.pck은 "APK와 달라진 파일만" 담는다(automation/delta_pack.py). 기준은 automation/apk_base.json(APK에 든 파일 md5). APK를 새로 만들 때만 그 APK의 full.pck(후보 artifact에 들어 있음)로 apk_base.json을 다시 만든다(delta_pack.save_base). apk_base.json이 없으면 후보는 delta=false라 공개가 막힌다. 새 이미지·소리가 늘면 patch.pck이 커지므로, 커지면 APK를 새로 만든다.
- 서버(Cloudflare 문)는 건드리지 않았다: version.json(code,name,size,sha256)과 patch.pck?v=code 계약 유지. 구형 APK는 새 patch.pck을 받으면 안 되므로, 새 APK 설치 전에는 공개하지 않는다.
- 공개 절차 메모: main에 work와 같은 game·automation·verify-work.yml 등 입력 트리로 커밋을 올리면 공개되고, 초안 조회 지연으로 실패하면 release-patch를 workflow_dispatch로 다시 실행한다(v1.45에서도 그랬음)
- v1.44는 v1.45에 포함되어 공개됨. 같은 번호로 내용만 또 고치면 폰이 받지 못하니 다음 수정은 1.46으로 올린다
- 새 배포·PixelLab 유료 호출은 사용자 승인 전까지 하지 않는다. 공개 배포는 사용자가 폰에서 확인하고 승인한 뒤에 한다
- 이어서 할 일: (1) 사용자 폰 확인 피드백 반영 (2) 대표 외 장착 펫 2마리 일꾼·시너지(GAME_BIBLE 미결정)
- 진행 규칙: AGENTS.md "시간·전달 방식은 시작 전에 말한다". 첫 답에 무엇을/기다릴 시간/필요한 것을 한 줄로 말한다

## APK 만들기 (되묻지 않고 바로 한다)
- 언제 필요한가: 업데이터·아이콘·앱 구조를 바꿀 때만. 게임 내용만 바꾸면 패치(버전 올림)로 충분하다
- 재료(모두 여기서 구한다): 껍데기 APK = migration/shell/nakshiworld_v0.11.apk(키 없음, 저장소에 있음) / 서명키 = 사용자가 이 Claude 프로젝트(낚시게임)의 파일로 올린 debug.keystore 또는 nakshiworld_handoff.zip(Projects 도구 project_info로 목록 확인 → project_read original:true로 받기, 없으면 작업 첫머리에 사용자에게 요청. 별칭 androiddebugkey, 비밀번호 android) / 빌드 도구 = curl https://dl.google.com/android/repository/build-tools_r34-linux.zip 압축을 풀면 android-14 / 봉인 후보 patch.pck = 해당 검증 빌드 run의 release-candidate 아티팩트(gh api repos/znzkznzk96-rgb/nakshiworld-update/actions/artifacts/<id>/zip)
- 실행: python3 migration/make_apk.py --pck patch.pck --code 144 --name 1.44 --shell migration/shell/nakshiworld_v0.11.apk --ks debug.keystore --out NAKSHIWORLD_1.44.apk --bt <android-14 경로>
- 확인: 인증서 SHA-256이 5939b259…b763(기존 앱과 동일)이어야 한다. 아이콘은 스크립트가 승인 세트 24종을 적용한다. 새 키는 절대 만들지 않는다(세이브가 날아감)
- 키 보관 규칙: 저장소는 공개라 키를 넣지 않는다. PixelLab 키는 클라우드 환경의 네트워크 시크릿(api.pixellab.ai)으로 자동 적용되며 어디에도 저장하지 않는다
- 11/22 펫 외형 새 화풍 시험 승인(수달 A/B, PixelLab 2회). 개인 안내 문서(Drive) 접근 불가로 생성 대기. 상세는 GAME_BIBLE 최상단
- 수달 시험 진행 절차(사용자 지시 11/22): (1) 인증은 클라우드 환경의 네트워크 시크릿(api.pixellab.ai, Bearer)로 등록, 키는 채팅·GitHub·로그에 출력 금지 (2) 새 세션에서 GET /balance 읽기 확인 후 결과 먼저 보고 (3) edit-image-pixen, 96x96, no_background, 확정 수달 otter-A.png(base64) 입력, 설명·seed는 전송 전 확인 (4) 수달 A 1회만 생성 후 원본·정수 확대·SHA-256·실제 차감량을 사용자에게 먼저 제시 (5) 사용자 확인 전 B 금지, 자동 재시도 금지, 부적합하면 중단 (6) 기존 otter-A.png 덮어쓰기 금지, 후보는 별도 폴더 (7) 게임 적용·모션·배포 금지

## 확정된 것 (상세는 GAME_BIBLE 최신 항목)
- 펫 16종 정지 원본 확정, 모션 16종 완료(게임 미적용)
- C·D급 4종은 백룸 엔티티 A안으로 교체(PixelLab 원본 제작 전)
- SS·SSS는 완제품 직획득이 아니라 도면 획득(제작 조건·재료·경로 미설계)
- C~SSS 뽑기 시안은 독립 Godot 시안, 게임 미연결

## 필요할 때만 읽을 곳
- 최신 이력: docs/qa/record-photo/HANDOFF.md 위쪽 30줄만 읽는다(최신순 정렬). 전체를 읽지 않는다
- WORK_STATE.json: 전체를 읽지 않고 필요한 키만 찾는다(예: grep으로 해당 키)
- 기획 결정: docs/GAME_BIBLE.md에서 날짜 제목으로 해당 항목만 찾는다
- 규칙 원본: docs/PROJECT_INSTRUCTIONS.md. 물고기 제작 때만 docs/FISH_ART_RULES.md
- 게임 수정이 필요할 때만 최신 공개본(v1.43) 전체 소스 ZIP을 복원한다(릴리스 game-source.zip). 문서·기획 작업은 복원하지 않는다
- docs/CODEX_HANDOFF.md는 2026-11-06 시점 내용이라 현재 기준이 아니다
- 11/22 수달 A/B 시험 완료(PixelLab 2회 소진). 방향 확정: 백룸 컨셉, 22종 전부 교체, 등급 상승 시 그림자 침식(SSS=완전 그림자). 다음: 침식 단계 설계와 추가 생성 재승인. 키는 저장소 밖(~/.pixellab_key)
- 11/22 침식 시안(수달, 프로그램 제작) 확인 요청 중. 모션은 침식부가 불꽃처럼 일렁이게(후속). 22종 전부 재개선 결정, 추가 PixelLab 호출은 재승인 필요
- 11/22 펫 리메이크 기준 확정(수달·해룡, 절차는 GAME_BIBLE 최상단). 나머지 19종 3단계 절차로 진행 중, 3종씩 확인
- 11/22 펫 컨셉: 침식 폐기, 백룸+동물(A안)로 19종 재설계 중(수달·해룡 유지). 컨셉 확정 전 호출 금지. 키는 ~/.pixellab_key
- 11/23 최신 펫 방향: 사용자 레퍼런스 분위기 22종(보라·흰색·금색, 후광, 상자 소품). 위의 침식·백룸+동물 항목은 대체됨. 현재 시안 bk44(SSS 악마 재생성 1회 완료, 잔액 4407). 다음: 사용자가 bk44 시트 확인 후 나머지 보완 또는 확정. 추가 PixelLab 호출은 재승인 필요
- 11/23 최신(위 항목 대체): 펫 22종 최종 확정(숲 요정 교체), PixelLab 애니메이션·오라/발광/파티클 합성 완료, 성능 초안·장착 구조(대표 1+일꾼 2) 확정 방향. 상세는 GAME_BIBLE 최상단·docs/analysis/pet-balance-20261123. 게임 미적용, 키는 ~/.pixellab_key(저장소에 두지 말 것)
- 11/23 펫 획득=진주 슬롯 가챠(SSS 0.2%)·분해·도면·제작 구조 확정(GAME_BIBLE 최상단), 슬롯 릴 모듈 docs/qa/slot-module-20261123 시험 통과, 게임 미적용.
- 펫 작업 전 필독: HANDOFF 최상단 '펫 작업 실패 원인' 5개 규칙
