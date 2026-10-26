# 현재 작업 — 탐험 표기 수정·밸런스 분석 완료

공개 버전은 v0.80이며 새 배포는 하지 않았다. 단계 표기를 `1-2 · 3/3전투`로 수정했고 출발/상세/결과도1-N으로 통일했다. 실제 전투 model.gd/catalog.json의 밸런스 수치는 변경하지 않았다.

분석: 1,261,250회 전수/경계 전투 +600조건의 빠른 실행/실제 업데이트 비교(모두일치). 현재 초반 보호막 무피해와 보스/일반방 난도 역전 확인. curve 후보는 성장단계가 더 고르게 드러나지만 미적용 상태다.

- [상세 결과·후보·한계](docs/analysis/expedition-balance-080/REPORT.md)
- [집계표](docs/analysis/expedition-balance-080/summary.csv)
- [재현·원본해시](docs/analysis/expedition-balance-080/manifest.json)
- 재현: `automation/expedition_balance_analysis.py`
- 표기·모션·0.80 회귀 검사와480/660 렌더링 통과. 작업 브랜치 전체CI는 이 변경 커밋에서 확인한다.

다음: 결과 기반으로 밸런스 수치 확정 시 실제 모델에 적용하고 새 배포 범위를 결정한다. 계곡은 기존 입장 준비중 유지.

[이전0.80 공개 검증](docs/historical/before-expedition-balance-081/HANDOFF.md)
