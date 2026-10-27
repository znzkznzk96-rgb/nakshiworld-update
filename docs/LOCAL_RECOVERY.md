## 최신 복구 기준 — 2026-10-27 공개 v0.88

v0.88 전체 game-source.zip과 최신 작업브랜치를 사용한다. 수족관·도감 변경은 GitHub에 저장되고 공개됐다. 검증: [v0.88](../analysis/release-088/PUBLISHED.json). 이전 배포 중단 기록은 과거 이력이다. 휴대폰 적용 확인만 남았다.

## 2026-10-24 최신 기획 패키지
저수지 백룸 기획·선택3안·진행3안은 활성브랜치 [design/backrooms-reservoir/PLAN.md](design/backrooms-reservoir/PLAN.md)에 보관. review.html은 그림을 내장한 독립 비교본이며 model.py/preview.gd/QA.json으로 재현·검증 범위를 확인한다. 게임 구현/배포 없음. 현재 진행은 HANDOFF/WORK_STATE를 따른다.

# 현재 복구 기준 — 공개 0.72

v0.72 game-source.zip + 활성 작업브랜치 최신 overlay/삭제명세를 사용한다. 강화오라의 실제연결/은백·청색교정과 누적환경연출 모두 전체소스/원격에 포함. 해시/실제 공개검증은 docs/RELEASE_072_VERIFICATION.json. 과거 시안/미적용 문구는 단계별 이력이며 현재 상태는 WORK_STATE/HANDOFF 우선. 마을음악 미구현·휴대폰확인 대기.

## 최신 작업 — 저녁·조우·낚아올림 개선 (미배포)

v0.71 전체소스 + 활성 작업브랜치 overlay/삭제명세로 복원. 환경/angler_scene/main 및 신규 encounter_text.gd, 관련 검사/재현 스크립트가 원격에 보존된다. 신규 이미지 생성 없음. 검증/다음 작업은 WORK_STATE와 docs/qa/atmosphere-encounter/VERIFICATION.json 우선.

# 현재 복구 기준: 공개 0.71

0.71 실제 통합·배포·운영 다운로드 검증 완료. v0.71 릴리스의 game-source.zip을 기준으로 작업 브랜치의 최신 변경을 적용한다. 캐릭터·고양이·의자·낚싯대 코드는 전체 소스와 Git에 포함된다. 예전 HTML 검토본은 역사 자료다. 해시/소스 커밋은 docs/RELEASE_071_VERIFICATION.json, 현재 상태는 WORK_STATE.json 참조. 휴대폰 확인만 대기.

---

## 최신 — 실제Godot통합 원격보존 (2026-10-23)
이제 승인된네이티브캐릭터/낚싯대/스툴/고양이의 실행코드와 실제에셋전체는 활성브랜치 game/addons/reservoir/angler_scene.gd 및 game/art/angler_b/에 보존됐다. PNG는base64텍스트로 정확한원본바이트를보존하고 런타임에서로드, pack포함검사통과. Release v0.70전체소스 + 활성overlay/삭제명세로복원가능. 이전 '게임미적용/아트는별도패키지만'은 과거검토단계기록이며 검토용HTML/생성원본보존처로만 참고. 0.71공개/휴대폰확인상태는WORK_STATE/HANDOFF 및 실제Release를따른다.

## 최신 스툴 교정본 — 2026-10-23
NAKSHIWORLD_SCENE_STOOL.zip 저장성공/CRC확인. 최신 통합HTML/영상/GIF/목재스툴분리레이어/기준HTML/재현소스/에셋/검수 포함. 이전통합패키지는보존하되 최신좌판/배경중앙전면기둥수정은이패키지. docs/proposals/scene-stool/README.txt. 실제게임/공개배포변경없음.

## 최신 통합 검토본 복구 — 2026-10-23
NAKSHIWORLD_SCENE_FINAL.zip 저장성공/CRC확인. 새고양이 대기/행동 통일·의자 앞뒤레이어·캐릭터·낚싯대6종이 함께있는 독립HTML/53.6초영상/GIF/분리에셋/기준소스/재현코드/검수 포함. 이전패키지 유지. 공개GitHub는 소스스크립트/검수/문서이며 전체아트 바이트는 별도패키지다. 실제게임적용·배포완료가 아님. 상세 docs/proposals/scene-final/README.txt.

## 고양이 새두동작 패키지 — 2026-10-23
NAKSHIWORLD_CAT_SMOOTH_TWO_MOTIONS.zip 저장성공/CRC확인. 생성원본시트·24분리PNG·기존참조·재현소스·GIF/MP4·검수 포함. 이전고양이/캐릭터 원본보존. 새작화시각승인전·게임미적용. 공개GitHub는소스/검수/문서, 아트바이트는별도패키지로 구분.

## 고양이 검토본 복구 — 2026-10-23
NAKSHIWORLD_CAT_MOTION_REVIEW.zip 저장성공/CRC확인. 원본16PNG·GIF/MP4·재현소스·검수 포함. 이는 캐릭터최종패키지를 교체하지 않는 별도검토본. 고양이후보/의자마감/게임통합 미완료, 최신WORK_STATE/HANDOFF 참고.

## 현재 최종 전달 패키지 — 2026-10-23
정확한 파일명 NAKSHIWORLD_B_FINAL.zip을 찾아 복원한다. 사용자 채택표정v2·동작·낚싯대6종·독립HTML·영상·원본레이어·얼굴PNG·상점참조·재현코드·검수가 함께 포함되고 저장성공/CRC확인. 이전패키지 유지. 공개GitHub에는 문서/코드/검수 보존, 전체아트 바이트는 별도패키지이며 실제게임적용·배포없음.

## 표정v2 복구 포인터 — 2026-10-23
최신 표정 교정패키지 NAKSHIWORLD_B_EXPRESSIONS_V2.zip 저장성공/CRC확인. 이전 전체 character-rods 검토본을 유지하며 이ZIP은 교정된 독립HTML·얼굴10PNG·표정함수·검수/비교본을 제공한다. 상세는 CHARACTER_MOTION_GUIDE 첫 절. 코드/문서 원격보존과 패키지 아트보존 구분.

## 2026-10-23 새 복구본
기존 OUTLINE_EXPRESSIONS ZIP 손상을 확인해 CRC정상 ARM_DEPTH_BREATHING 승인본에서 후속 제작. 완전한 새 에셋·HTML·영상·재현소스는 NAKSHIWORLD_B_CHARACTER_RODS_REVIEW.zip으로 저장 성공·CRC확인. 정확한 파일명으로 찾아 복원한다. 최신 윤곽 바이트를 복구한 것은 아니다. 최신 단계는 HANDOFF 및 CHARACTER_MOTION_GUIDE 첫 절. 공개GitHub는 소스 스크립트·검수·문서를 보존하며 아트 전체 바이트 보존과 구분한다.

## 최신 재개 — 2026-10-23 채팅 이동
현재 상태는 [HANDOFF](../HANDOFF.md)와 WORK_STATE의 최신 항목을 따른다. 아래 과거 “B안 밀도/크기 비교부터” 기록은 현재 재개 단계가 아니다.
- 어시장 전체 목록 스크롤·한글 설명 줄바꿈은 원격 코드에 저장됐고 CI 39876552230의 17개 검사 및 화면 캡처 생성 통과. 공개 배포 없음. 캡처 육안 검토·실기기 확인은 별도다.
- 캐릭터는 개선 B 채택 → 앞뒤 팔/독립 어깨/호흡 긍정 확인 → 윤곽·표정 연결 검토본까지 진행한 상태. [캐릭터 가이드](CHARACTER_MOTION_GUIDE.md) 첫 절 참조. 정확12% 수치, 무게4구간, 장비 외형/오라는 확정·구현으로 간주하지 않는다.
- 캐릭터 검토본 파일명: NAKSHIWORLD_B_OUTLINE_EXPRESSIONS.zip. 이전 가이드의 사용자 파일 보존 기록은 있으나 이 환경에서 실파일/원격 아트 바이트는 확인하지 못했다. 기존 사용자 파일/Library 보존처를 먼저 찾아 실제 내용을 확인한다. 원격 문서만으로 완전 복구됐다고 하지 않는다.
- 제공된 FULL_HANDOFF(1).zip은 이번 첨부 전달 실패. 읽지 않았고 이번 작업에는 불필요했다. 원격 게임 작업은 Release v0.70 + work/valley-runtime으로 재개 가능하므로 무조건 재첨부를 요구하지 않는다.
- 로컬 절대경로/도구 설치/캐시 존재를 새 환경에 가정하지 않는다. 이번 정리는 문서만 원격 저장. 게임 코드·아트·유료 생성·배포 변경 없음.

### 아래는 당시 상태를 보존한 이전 기록
## 최신 재개 — B안 선택 후 밀도/크기 재검토 (2026-10-22)
활성work/valley-runtime의WORK_STATE/HANDOFF 및 [캐릭터·모션기준](CHARACTER_MOTION_GUIDE.md)부터 이어간다. B원본참조2개는 proposals/character-b/에 원격보존,기존A/B비교는 previews/character-seated-ab.png. 일반이미지생성 디자인참고이며 PixelLab게임스프라이트/모션/실제적용본과구분. 사용자 재첨부불필요. 다음은밀도개선·소폭확대 비교,약12%는추천. 확정후 대기/캐스팅시험영상. 새생성/수정/배포승인은 단계별기존범위준수.
저수지확률·박물관보상수정도work에보존·로컬/CI통과했으나미배포. 공개0.70/휴대폰확인대기 유지. 아래는이전시점기록.

## 최신 재개 기준 — 0.70 공개 완료 (2026-10-22)
이제 선택저수지base/moon·환경레이어·main정렬·최종48px주인프레임은 GitHub코드와v0.70 game-source.zip에 포함돼 있다. 전체소스ZIP+작업브랜치overlay/삭제명세 기준으로 이어간다. [공개검증](RELEASE_070_VERIFICATION.json),화면은previews/reservoir-070-day-night.png 및previews/owner-070-six.png. 원본12장 전체와 과거복구자료는 기존RESUME_PACKAGE에 유지된다. 아래의 GitHub미반영/배포전 문구는 당시기록이다. 휴대폰0.70 적용은 미확인.

### 아래는 이전 재개 기록
## 2026-10-22 — 0.70 통합검증 후 배포 준비
기존 밝은저수지 base/moon·환경레이어·main 정렬 변경과 최종48px주인프레임을 이번 작업브랜치 저장에 포함한다. 과거 “이미지/미커밋게임작업 GitHub미반영”은 아래 기록 시점 기준이며 이번 포함파일은 검증문서 참조. 기존12장 전부를 원격보존하는 것은 아니다. 15검사·실제화면검수 통과,공개배포는 아직 진행 전. [검증](qa/release-070/VERIFICATION.json).

# 작업 재개와 보존 상태 — 2026-10-22

## 현재 범위와 다음 행동
이번 반영은 작업 방식/인수인계 문서만이다. 게임 코드·아트·다른 미커밋 파일·이미지는 이번 커밋에 포함하지 않는다. 공개 v0.69 유지, 게임 적용·배포 없음.
다음 작업은 기존 저수지 시안 및 미커밋 환경레이어 결과를 활용하는 것이다. 이미 확인한 기획·백업·진단을 반복하지 않는다. 구체적인 게임 수정/배포는 최신 사용자 지시 범위를 따른다. 서비스 비정상 응답의 원인은 미확인이고 절차 개선을 완전 해결로 해석하지 않는다.

## 새 환경에서 가져올 위치
- 저장소의 START_HERE.md → docs/CONTINUE_HERE.md → main WORK_STATE.work_branch → 활성브랜치 WORK_STATE/HANDOFF와 이 문서를 읽는다. 이후 main의 오래된 상태로 돌아가지 않는다.
- 활성브랜치: work/valley-runtime. 원격 코드 기준은 이 브랜치 HEAD이며 배포 전체소스는 v0.69 game-source.zip + 해당 브랜치 overlay/삭제명세다. 문서만 다룰 때는 게임을 복원/빌드하지 않는다.
- 백업/생성이미지/미커밋파일의 별도 보존본 파일명: NAKSHIWORLD_RESUME_PACKAGE.zip. 새 대화에서는 사용자가 연결한 파일 도구로 이 정확한 파일명을 검색하고 권한 범위에서 내려받는다. 비공개 파일ID나 보관경로는 공개 저장소에 기록하지 않는다. 사용자 재업로드를 기본 요구하지 않는다.
- 패키지 내부 backup/NAKSHIWORLD_RECOVERY_BEFORE_CHANGES.zip에 MANIFEST.json(원본경로/크기/SHA256), tracked-changes.patch, 기존 이미지12장, 미커밋 작업과 당시 문서/로그가 있다. current-docs는 패키지 제작 시점 문서이므로 현재 원격 문서가 우선이다.
- 패키지는 전체 게임소스가 아니다. Library 접근이 불가하면 오류를 보고하고 원격 문서/코드로 가능한 부분만 이어간다. 원본 이미지가 GitHub에 없다고 유실 또는 재생성 필요로 단정하지 않는다.

## 보존 범위
- 원격 GitHub: 확정 기획·기존 커밋 코드·이번 재개/절차 문서.
- 별도 패키지: 기존 생성PNG12장, 미커밋 작업, 기존 문서/검사로그 등49개 파일. ZIP CRC와 파일별SHA256 일치 검사 완료.
- GitHub 미반영: environment.gd/main.gd/regional_verify.gd의 로컬 변경, reservoir_layer.gd/관련셰이더/레이어PNG/검사파일. 이미지12개의 동일blob은 확인한 원격HEAD 트리에 없었다. 이번 문서 커밋으로 이미지/미커밋게임작업까지 원격보존됐다고 주장하지 않는다.
- 발견된 후보3장: 패키지 백업 안 87fc6f84a2fb/generated_images/의 exec-ee8e5050-3d28-4722-ad8c-b19cac7a19ba.png, exec-71014235-11c9-44f9-8cbf-ef78909afe97.png, exec-5e5a053f-3931-447e-9714-3f124f75083e.png. 각802×1961. 최초3시안인지 미확정, 후속2시안과 혼동하지 않는다. 재생성하지 않는다.
- 기존 layers 포함15개 로그에서 failures=[]를 확인했으나 현재 소스와 정확한 대응 검증은 남아 있다. 이번에 게임검사를 다시 실행한 것은 아니다.

## 오래된 로컬 경로 — 참고용
/workspace/scratch/86d0abeff8b0/repo 및 /workspace/scratch/{87fc6f84a2fb,86d0abeff8b0,c683934bc1d8}/generated_images 는 이전 작업공간 경로다. 새 환경에서 존재한다고 가정하지 않는다. 패키지를 새 작업폴더로 풀고 MANIFEST 경로와 대조한다. 원본을 덮어쓰거나 historical 소스를 최신에 통째로 적용하지 않는다.

## 완료와 남은 일
완료: 원본백업·해시검증, 문서일부읽기→기존이미지1장열기→한국어설명 흐름1회 성공, 후보3장 비교 제시. 작은 단계와 제한출력으로 작업방식 개선.
남은 일: 필요할 때 기존생성결과와 최초/후속시안 기록 연결, 미커밋레이어 소스와 검증로그 대응 확인. 추가진단/백업/문서정리는 새 근거 없이 반복하지 않는다.
