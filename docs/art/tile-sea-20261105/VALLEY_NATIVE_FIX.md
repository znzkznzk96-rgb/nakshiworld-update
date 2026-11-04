# 계곡 해상도 복구 작업본 — 2026-11-05
## 변경
계곡 배경/기존 효과를 외부 출력 Viewport의 CanvasLayer(-1)에 배치한다. 저해상도 게임 SubViewport는 투명 배경으로 위에 합성한다. 캐릭터/UI 해상도·앵커·승인 배경 원본·세이브·가격은 변경하지 않았다. 게임 노드 종료 시 외부 CanvasLayer도 해제한다. 외부 텍스트/게임 Viewport가 분리되지 않은 테스트 경로는 기존 world-canvas fallback 유지.
타일바다 직전 단일 시안은 사용자 확정, 레이어 작업 보류.
## 검증
- Godot4.4.1 headless 실제 root.gd _start/_fit 경로 신규 검사 통과: 1080×1920/2160/2640 출력, 내부270×480/540/660 유지, 배경은 외부 Viewport 소속, CanvasLayer -1, 수면앵커 오차0.5 이하, 저수지/마을 왕복 및 종료정리.
- 기존 valley093, valley094, regional, reservoir_layers, fish_surface 검사 5개 모두 failures=[].
- tests/valley_native_root.gd는 업데이트 네트워크만 비활성화하고 실제 앱 _start를 상속해 사용한다. 각 테스트 XDG_DATA_HOME 분리, 사용자 실제 세이브 접근 없음.
- 실제 그림 전후 캡처는 미완료: 로컬 Xvfb 환경에서 Godot 그래픽 실행이 디스플레이 초기화/세그멘테이션 오류로 종료됐다. headless 구조 검사 통과를 실화면 검수 완료로 간주하지 않는다. 다음 단계는 그래픽 가능한 환경에서 동일 신규검사를 실행하여 before/after 3높이 이미지 검수.
## 상태
작업 브랜치에 코드/검사 저장. 게임 버전 변경·공개배포·휴대폰 적용 없음. 운영v1.05 유지. 실제 UI 합성/캐릭터 가림의 이미지 검수 및 배포 전 필수 전체검사는 남아 있다.
