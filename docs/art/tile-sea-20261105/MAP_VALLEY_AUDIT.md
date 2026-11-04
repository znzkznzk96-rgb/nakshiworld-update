# 계곡 도트 표시 조사 및 타일바다 맵 검토 — 2026-11-05

## 결과
계곡 승인 배경 자체는 변경되지 않았다. 현재 앱의 저해상도 SubViewport 경유가 세부 픽셀 손실을 일으키는 구조임을 확인했다. 실제 사용자 휴대폰 스크린샷 비교는 수행하지 않았으며, 이번에는 배포 소스·원본 해시·Godot 엔진 크기 검사로 확인했다.

## 근거
- 최신 실제 Release v1.05, 소스 커밋 a83a6c1850f2ed07b76fb02ddf58579137db2061. 관련 배포/운영검증 Actions 성공.
- game-source.zip 61640649 bytes, SHA256 7dbc745c001d56c84a438cbba867d913055564d80c8fd91640c8e6d6ff0c91de. ZIP CRC 정상. 작업 브랜치 game/ 모든 blob과 공개 소스가 일치. 삭제 명세 확인.
- 계곡 원본 1080×2640, SHA256 8f754000173c7602a2d247cf735b5aa9dd053881ead79f76ea548bc453c37a8a. data/valley/scene_spec.json 승인 해시와 동일.
- root.gd _start(): SubViewportContainer stretch=true; 내부 SubViewport에 main.gd를 넣음. _fit()은 논리 화면 크기를 container에 적용.
- valley_environment.gd setup(): native=false, m.add_child(root). 따라서 배경도 내부 SubViewport에서 그려짐.
- Godot4.4.1 실제 headless 크기 검증: 출력1080×2640, 논리화면270×660, 내부SubViewport270×660. 배경 가로/세로 각각4픽셀분이 중간화면1픽셀로 샘플링된 후4배 확대된다. 필터nearest는 잃어버린 세부정보를 복구하지 않는다.
- 회귀 변경: ad09a22894775c26a1dadc15ede35bb801f8dd88 (계곡입장/B2 작업, v0.93). 기존 text_layer 부모의 외부 렌더 경로를 제거하고 캐릭터 가림 해결을 위해 m의 자식으로 옮겼다.
- 별도 부드러움 원인: valley_life.gd TEXTURE_FILTER_LINEAR; 구름 shader filter_linear. 이것은 배경 전체 축소 문제와 구분한다.
- 기존 valley093_preview.gd/valley094_preview.gd는 main을 root에 바로 붙여 실제 root.gd의 내부 SubViewport를 재현하지 않는다. 따라서 해당 스크린샷 검증으로 앱 경로의 세부손실을 잡을 수 없었다.

## 수정 방향 (이번 조사에서 게임코드 수정·배포 없음)
고해상도 배경을 외부 렌더 경로로 분리하되 낮은 CanvasLayer에 두고, 투명한 게임 SubViewport를 위에 합성한다. UI와 캐릭터 가림이 재발하지 않도록 실제 앱 진입 경로로 짧은/긴 화면 및 지역전환을 검증해야 한다. 단순히 native=true로 되돌리거나 전체게임 해상도를 바꾸는 수정은 하지 않았다. 승인 배경 재생성 불필요.

## 타일바다
저수지/계곡 실제 원본 두 장을 참조해 세로형 배경 검토본1장 제작. 왼쪽 짧은 타일 낚시 자리, 수면, 넓은 수중공간, 하단 타일바닥/배수구 구성. 캐릭터·물고기·UI 없는 배경. 이번 결과는 구도/아트 방향 시안이며, 최종 픽셀 격자·앵커 정합·실제 게임 합성 검증 전이다. 승인 기존 두 배경은 변경하지 않았다. 운영 v1.05 유지.
