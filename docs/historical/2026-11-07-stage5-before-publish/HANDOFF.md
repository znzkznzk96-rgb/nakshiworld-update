# 타일바다 v1.07 — 현재 인수인계
갱신: 2026-11-07 KST. 활성 `work/tile-release-107`. 공개 v1.06 유지, v1.07 미배포. 사용자 2026-11-07 “5단계 진행 배포까지 진행해줘 ㅇㅇ”로 이번 v1.07 공개 배포 명시 승인. [WORK_STATE](../../../WORK_STATE.json).

## 완료·근거
- 2단계 승인 배경 원본 검증·전체소스 복원·두 화면 적용·3높이 검수 완료. [검증](../../qa/tile-background-stage2/results/VERIFICATION.json).
- 3단계 승인 최종20종 및 최신12/17 대조·도감 검수 완료. [검증](../../qa/tile-fish-stage3/REVIEW.json).
- 4단계 메인6/서브6/주인1, 계곡 자격 충족 후312000비늘 입장, 선택 개체 기증·명시 보상 수령·중복방지·실제 파일쓰기 실패6종 롤백·별도 프로세스 재개 검증 완료. v1.06 실제 코드로 만든 가상 save.json+rec.json을 새 작업본에서 읽어 지갑·가방·기록·부분기증 보존 확인. 실제 사용자 세이브 미사용.
- odds_rewards의 옛 지역2 미구현 기대값을 지역3으로 교정하고 관련18개 검사 통과. 게임 동작·밸런스·아트 변경 없음.
- [4단계 상세 검증](../../qa/tile-bundles-stage4/REVIEW.json), [화면·기계결과](../../qa/tile-bundles-stage4/results/VERIFICATION.json), [실제 보상 화면](../../qa/tile-bundles-stage4/results/bundle_rewards_comparison.png), [성공 실행](https://github.com/znzkznzk96-rgb/nakshiworld-update/actions/runs/42319985467).
- 전체69개 headless suite 통과 근거: 기존 전체실행49개 + 이번18개 + 2단계 regional + 3단계 personal_dex. 테스트 기대값만 변경했으며 게임 소스·Godot 버전 기준 동일. 표준 전체 workflow 자체는 이전 odds_rewards 실패 상태이므로 전체 CI 성공으로 부르지 않는다.

## 5단계 사전 검수 완료·공개 배포 진행
- 남은 공통 렌더13그룹 성공·221PNG 생성, 주요24화면 수동 확인. 승인 PNG21개 SHA/디코드/크기 정상. [사전 검수](../../qa/tile-release-stage5/PREFLIGHT.json).
- 4단계 검수 이후 게임 트리 불변. 배포 workflow에서 동일 game 트리·복원/삭제명세·성공 렌더 run을 확인하고 전체 배포 검사 및 PCK 실물 자산 확인 후 게시한다.

## 다음: 공개 배포 검증
1. 표준 전체 workflow에서 실행되지 않은 공통 화면 렌더 검사와 배포 조건을 확인한다. 이미 통과한 동일 조건 검사는 재사용한다.
2. 전체 소스 ZIP·PCK·version.json을 구성하고 버전·소스 커밋·실제 크기·SHA·자산 포함·세이브 호환을 점검한다.
3. 최신 사용자 명시 승인으로 이번 v1.07 공개 배포까지 진행한다. 실제 운영 다운로드 검증과 휴대폰 적용 확인은 각각 기록한다.

## 검사 준비 오류·보호
- 첫 전용검사는 검사용 이전 세이브에서 rec.json 저장 누락으로 실패했다. _save_rec() 호출 및 public accessor 사용으로 교정했다. 게임의 기록 손상으로 해석하지 않는다.
- 이후 두 실행은 수정본의 에디터 import 종료에서 exit134 / double free or corruption을 기록했다. 단일스레드 scene/명시 GL 설정만으로는 재현이 없어지지 않았다. 일회용 검사용 스크립트를 에디터 문서화/import 단계 뒤에 복사한 실행은 준비·실제 실행·회귀검사까지 성공했다. 정확한 native 원인은 미확정이며 게임/PNG 손상이나 ChatGPT 읽기전용 전환 원인으로 단정하지 않는다.
- 원본/전송/복원 해시 실패 없음. 새 유료생성0, 실제 사용자 세이브0, 공용UI/밸런스 변경0, 공개배포0. 균열해역 준비중 유지.
- 직전 HANDOFF 원문은 [4단계 이전 원문](../../historical/2026-11-07-stage4/HANDOFF.md)에 보존했다.
