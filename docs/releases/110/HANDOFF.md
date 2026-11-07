# v1.10 배포 진행 — 2026-11-08

사용자 업데이트/배포 명시승인. 최종 게임 소스12dfd5d1b96aa2ecfee558d491991d123950700a, 전체CI42423468177, PR46. 승인 타일 시안 전체를 실제 game/에21개 기존PNG와 importedTexture2D loader로 연결. 기존 미배포 난이도·표시·공통빛·타일수면 포함. 우편ID1.10/과거편지/세이브 유지, 신규유료생성0.

완료: TILE_SCENERY_VERIFY failures=[] (4구름·양방향순환·3크기×9새프레임·1성4종·타일만표시·숨김시정지·RNG보존·dispose), 실제본편540×1320 90프레임 렌더와 육안검수. 미리보기 로더와 달리 ResourceLoader/Texture2D.get_image를 사용해 export 검사를 추가.

현재: 원격전체CI Import/full regression 단계. 최종소스 검증후보 신규생성 필요(옛584e3ee9후보 재사용금지). 실행환경 연결이 이후 unavailable로 바뀌었으나 소스/자산은 이미 원격 보존됐고 GitHub Actions는 독립실행 중. GitHub API로 검증/배포 이어갈 수 있음. main과PR은 mergeable=true 확인, 모든검사성공 전 merge금지.

다음: CI42423468177 성공/후보artifact 확인→PR46 expected head로 merge→Build and publish game patch 성공→Verify deployed update gateway 성공→v1.10 공개3파일/크기SHA/소스커밋/운영다운로드 proof 기록. 공개현재v1.09, 새배포/휴대폰 적용은 아직미완료.
