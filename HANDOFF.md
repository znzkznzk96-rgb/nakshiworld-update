# 0.65 계측·윤곽 오라·몸짓도감 수정
기준 main116761f / 공개 v0.64. work/measure-aura-065.
사용자0.64 화면에서 가로/세로 비율 왜곡 및 %g 눈금 확인. 높이 단독 제한 제거, 상단 중복 물고기 제거. 어종별 눈금과 물고기 비율을 함께 유지하고 계측 공간 확대. 등급 알림이 계측을 가리지 않도록 차단.
기존 타원 오라를 실제 애니메이션 실루엣의 다중 외곽 레이어로 변경. 등급 색상 유지, 바깥쪽으로 확장하며 투명해짐, 본체는 마지막에 그려 보호. 신규 이미지 생성 없이 기존 알파 실루엣 활용.
도감 웅크림 curl -1.65→-0.28. 착수 시범0.8초→3.2초, 실제 플레이 대응 시간은 변경 없음.
Godot4.4.1 import 및 guide/equipment/visual 검사 failures=[]; 숫자눈금/전어종 비율 공간/착수 읽기 시간 회귀 검사 추가. 화면 검증 진행, 아직 미배포. 세이브 형식/경제 변경 없음.
다음: 화면 검증 완료 후 main으로 공개0.65, Actions와 운영 다운로드 및 ZIP/PCK 해시 검증. 휴대폰 적용은 별도 사용자 확인 필요.

## 최종 검증 및 배포 차단
Godot import, equipment/guide/visual/shop 4개 검사 failures=[] 및 Android PCK export 성공. 붕어25.9cm/88g 원본 비율·정상 숫자·계측창 알림 미중첩, 도감 전조/착수, 신화 외곽 오라 렌더링 직접 확인.
로컬 PCK 26318896bytes SHA256 239bbafbd6218049ca52e350eddcc7d5122706d84dfe01b103c52af3fffb65a3 (CI 배포본과는 별개).
소스 checkpoint eaac95c3dd53e1e39cd8c9cb11f9fe13a9e396b4 원격 work/measure-aura-065 확인. main 갱신은 자동승인검토가 실제 배포에 대한 명시적 사용자 승인이 부족하다고 거절. 우회하지 않음. 공개 버전은0.64 유지,0.65 미배포. 다음: 사용자 배포 승인 후 main 반영, CI와 운영 다운로드/소스ZIP 검증, 문서 갱신.

## 추가 요청 적용 (배포 승인 확보)
사용자 "적용하고 배포까지 가자 지금까지내용" 승인 후 타이틀 사운드 추가 요청. 과거 배포 차단 사유는 이번 명시 승인으로 해소.
새 audio_feedback.gd: 기존 drag_recording.ogg 그대로, 물고기 행동별 물살/기포 및 텐션 상승음·짧은 진동. 도감 동일 단계 전환 체험. 진동 끄기/약/중/강, 효과음/음악 독립 설정. 타이틀 폭풍 번개 event/cycle에 천둥 한번씩, 비/Ancient Mysteries 반복곡 페이드. 앱 백그라운드 음원/진동 중지.
원본 녹음: Skippy Fish water collection(jcpmcdonald), Rain on Window Loop(alxl), Ancient Mysteries(Sperry Lion), UI(Kenney), 모두 CC0 선택. 천둥/줄 긴장/캐스팅은 이번 절차적 합성. CREDITS.txt와manifest.json 참조. 직접 청음 품질 및 Android 진동 세기는 사용자 휴대폰 확인 필요.
settings65.gd: 진행 초기화 예/아니오, 거절 시 무변경. reset.pending 재시작 처리, save/rec/tut 및 백업만 삭제; 설정 및 업데이트 파일 유지. 실제 사용자 세이브를 초기화하지 않았음; 격리 테스트만 수행.
save_store.gd: tmp에 완성 후 rename, 이전 정상 JSON 백업, 주 파일 없거나 파손 때만 백업. 강화는 기존대로 비용/결과를 연출 전 저장. 오프라인 정산 후 즉시 저장. 로컬 파일 변조 방지 서버는 미구현.
Godot import, equipment/guide/shop/visual/audio_save 검사 통과. audio_save는 음원 시작과 정지를 같은 프레임에서 반복해 종료 자원 경고가 발생했으며 실제 프레임 간격을 둬 정상 종료 확인. 설정/초기화/타이틀 화면 확인. 배포 CI에 audio_save 추가. 아직 새 Release 검증 전.

CI39538132380은 기능 검사 통과 후 guide 종료 시 자동 시작된 타이틀 음악 자원 경고로 중단(미배포). 비오디오 테스트는 root 추가 이전에 음소거/타이틀 해제하도록 초기화 순서 수정. 오디오 전용 검사는 실제 프레임 간격 재생을 유지. 검사 게이트는 완화하지 않음.

## 공개 완료 및 직접 확인
Release https://github.com/znzkznzk96-rgb/nakshiworld-update/releases/tag/v0.65
소스 e1f5b7a4ee82b1b47f36e8e75435a4eabb1a6f8a, 빌드39538305343 success, 운영검사39538383953 success. 로컬에서도 version.json code65, patch.pck?v=65.0 HTTP200/GDPC/28168368bytes/SHA256 814894c89024358eaba33dbc908929d9b0ee4274d597455a7dd14ebc698d1b12 확인.
전체소스 ZIP27183411bytes/SHA256 e1c832daebec57b6f865aa5ad2374dbf5e67e273ee285c95e51c6483716ded22 무결성 검사 및 코드/이미지/음원58파일 로컬 일치. 드랙 원본 해시 보존 확인. 배포 PCK 음악·크레딧·오디오 스크립트 포함 검사 통과. APK 재설치 필요 없는 콘텐츠 패치. 휴대폰 업데이트·청음·진동 체감은 사용자 확인 전. 증거 docs/RELEASE_065_VERIFICATION.json.
다음 채팅은 최신 main과 공개 Release 기준으로 진행. 과거 승인 대기/CI 실패 문단은 이력이며 현재 배포 성공 상태임.
