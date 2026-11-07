# 타일바다 레이어 시안 2단계
2026-11-08 KST. 원경 어군 2장은 품질 문제로 보류. 사용자가 나머지 독립 항목 진행 승인.

- 기존 배경 원본은 그대로 두고 native plate 하위 12개 레이어 분리: 수면 잔물결/반사/빛줄기/물빛 무늬/부유물/흐름/기포/발판 파문/중경 물고기/근경 물고기/바닥 수초/벽 식물.
- 기존 최종 승인 타일 물고기 00/02/05 재사용. 좌향 원본을 렌더에서 우향 전환, 원본 변경 없음. 원경 군집 신규 아트 보류.
- 신규 식물 원본·요청·비용·개별 검수는 ../tile-layer-art-v1/PLANT_QA.json. 바닥 수초2장+벽식물02 총3장 내부/화면 통과. 벽식물01은 하단 잘림 의심으로 보류. 식물4장 실차감4회분, 추가재생성0.
- 480/540/660 화면 높이에서 표시/장면전환/clock/disposal 검사 통과. native540x1320에서 0/3/6초 변화 및 상단555px 픽셀 동일. 관련 VERIFICATION.json.
- 본편 게임 코드·배경·세이브·난이도 미변경. v1.10 검증 후보 유지, 운영v1.09 유지, 배포 없음. 시안 검토 전 후보 교체하지 않음.

## 재현
전체 runtime의 tests/에 이 디렉터리 gd3개를 복사(미리보기 이름은 tile_layers_all_preview.gd, 검사 tile_layers_all_verify.gd), 통과한 식물3원본을 tests/tile_layer_assets/에 둔다. runtime은 검증된1.09 전체소스+활성overlay 기준. headless tests/tile_layers_all_verify.gd, native tests/tile_layers_all_preview.gd -- 출력폴더. 원본PNG는 변형하지 않음.
