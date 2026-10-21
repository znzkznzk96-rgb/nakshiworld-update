# 0.65 오디오/진동 및 저장
타이틀: storm 연출의 cycle:event 전환에 천둥, 별도 rain/music 루프와 진입·퇴장 페이드. 보컬 없는 Ancient Mysteries 원곡 사용(8비트로 강제 변환하지 않음). 타이틀 이외 배경음은 추가하지 않음.
효과음: Skippy Fish 실제 물/기포 녹음, Kenney 인터페이스 원본, 프로젝트 합성 천둥/캐스팅/장력. game/sfx/refresh65/CREDITS.txt에 원본 페이지 및 CC0 정보, manifest.json에 가공본 해시. automation/build_audio_assets.py는 audio65에 원본 파일을 준비한 후 실행하는 가공 스크립트.
기존 drag_recording.ogg SHA256 7e77701b2c7db2bc611439157944222117e5289e216eeea0258ff93a609571cb 보존. 기존 사운드 play 진입점을 새 파일로 매핑. 행동 소리 최대6동시, 반복간격0.48~0.8초, 장력 상승음0.28~1초. 도감은 단계당 한 번만 소리/진동.
진동은 Godot handheld duration/amplitude 사용. 실제 기기에서 amplitude 지원과 체감 강도는 달라질 수 있음. 새 APK의 추가 네이티브 모듈 없음.
진행 초기화는 설정→확인 예/아니오. save.json/rec.json/tut.json과 .bak/.tmp만 삭제. settings.json 및 patch.pck/patch_ver.txt 유지. marker로 중단된 초기화 재시도.
강화 비용/결과는 기존대로 연출 전 함께 저장. 자동저장은 완성된 tmp를rename하고 이전 정상파일을백업, 정상본 우선 읽기. 오프라인 수익 지급 직후 정산시각 저장. 악의적 파일변조/기기시계변조를 서버처럼 방어하지는 않음.
검사: Godot4.4.1 import, equipment/guide/shop/visual/audio_save, Android PCK export 및 pack 내 음악/스크립트/크레딧 포함 검사. 격리 경로에서만 초기화 검사. 실제 휴대폰 청음/진동 체감 미확인.
