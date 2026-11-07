# 타일바다 v1.07 — 공개·다운로드 검증 완료
2026-11-07 KST. [공개 v1.07](https://github.com/znzkznzk96-rgb/nakshiworld-update/releases/tag/v1.07), 소스 `4883f05868142f8bcbbfe5b1edb4adc4f36f8a02`, PR39. 활성 `work/tile-release-107`. [WORK_STATE](../../../WORK_STATE.json).

## 공개 결과
승인 배경 원본(801×1962), 최종20종(최신12/17 포함), 메인6/서브6/주인1 번들, 계곡 메인 보상 수령 후312000비늘 입장을 공개했다. 균열해역 준비중 유지. 기존 세이브/승인UI/밸런스 유지, 새 유료생성0.
[실제 공개3파일·소스·운영 다운로드 검증](PUBLISHED.json)에 크기·SHA·태그·소스커밋·Actions 원본을 모았다. 실제 공개 ZIP CRC 및 저장소 overlay555개 일치, 앱 업데이트 주소 manifest/PCK/test.txt 확인 완료.

## 검사 범위
- 승인 PNG21개 디코드/크기/SHA 정상. [원본/전송](https://github.com/znzkznzk96-rgb/nakshiworld-update/blob/ebdb67293522c91c750945ee56cacd645d72f444/docs/transfers/tile-png-stage2/VERIFICATION.json), [배경 실화면](../../qa/tile-background-stage2/results/VERIFICATION.json), [물고기/도감](../../qa/tile-fish-stage3/REVIEW.json).
- 번들 기증/보상·해금·v1.06 가상 세이브 호환·실제 파일쓰기 실패6종 롤백·별도 프로세스 재개/중복수령 방지 통과. [4단계](../../qa/tile-bundles-stage4/REVIEW.json). 실제 사용자 세이브 미사용.
- 5단계 공통 화면13그룹/221장 생성·대표24장 확인. [사전 검수](../../qa/tile-release-stage5/PREFLIGHT.json).
- 배포 workflow 전체 게이트 성공:68개 headless suite,계곡 native,기존PCK아트,승인배경·20종PCK로드 및 손상된 옛 경로 제외. 기존동일소스 tier3_motion 근거 포함69개 suite 범위 확보.
- 과거 표준 verify-work 단일실행 실패 기록은 보존한다. 이번 실제 release workflow와 public verification은 둘 다 성공했다.

## 다음
휴대폰에서 기존 앱의 v1.07 적용·타일바다 실제 플레이 확인만 남았다. 공개 다운로드 성공과 휴대폰 적용 성공은 별개다. 앱 삭제/데이터 초기화 금지. 새 업데이트/유료생성/별도보류브랜치 병합을 자동 진행하지 않는다.
다음 게임 작업의 전체소스 기준은 v1.07 game-source.zip이며 overlay/삭제명세를 적절히 적용한다. 배포 재현 workflow는 검증한 v1.06 기준 복원 방식을 그대로 보존했다.

## 이력
[배포 전 상태 원문](../../historical/2026-11-07-stage5-before-publish/HANDOFF.md), [4단계 검사 준비 실패·경계](../../qa/tile-bundles-stage4/REVIEW.json). 이전 importer native 종료 오류의 정확한 원인 및 ChatGPT 읽기전용 전환 원인은 미확정. 이번 실제 배포의 import/검사/공개/운영 검증은 성공했다.
