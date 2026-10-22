## 최신 우선 — 48px 공통스타일 재시안 완료
우주바다의 곡선/타원·장식 프레임을 실제 스타일·형태 참조로 사용해 지역별1장·6종을 새로 제작했다. 256×48px로 기존보다 높이25% 축소. 총6요청/6결과/60회분·재생성0. **이번은 시안만이며 게임은 기존64px 상태, 배포 없음.**

[모음](docs/previews/owner-v2-proposals.png), [높이비교](docs/previews/owner-v2-height-comparison.png), [보고서](docs/proposals/owner-gauge-v2/REPORT.md), [시안검증](docs/proposals/owner-gauge-v2/VERIFICATION.json). 원본/요청/영수증/지역검수는 docs/proposals/owner-gauge-v2/0~5/. 모음은 좌우투명여백을 표시폭에 맞춘 합성시안이며 실제게임화면이 아니다. 사용자 검토 후 다음 지시를 따른다. 임의추가 유료생성/게임교체/배포 금지.

# 현재 인수인계 — 2026-10-22

## 현재 결과 (미배포)
**주인게이지 PixelLab 프레임6종 완료/등록/검증.** 사용자 '각낚시터컨셉6개한개씩' 승인에 따라 지역별1장 순차생성/검수, 유료요청6회·결과6장·60회분·추가재생성0. 저수지청룡비늘, 계곡역류/붉은무늬, 타일바다도자기, 균열해역선박금속/보라균열, 심해잠긴사무실/배관, 우주바다성운/별빛.

- 게임원본PNG: game/art/ui/owners/region_0.png~region_5.png. 256×64 네이티브 PixelLab 반환바이트 그대로.
- 프레임별 이름/숫자/진행바 좌표: game/data/ui/owner_gauges.json. 엔진이 실제진행률에 맞춰0~100% 채움과문자를독립렌더. 저수지/계곡 기존승인주인그림을틀안에배치. 후속4지역은빈주인그림칸을유지하며외형/이름/입장임의추가없음.
- 소스 de1faddb0ab29071f4dbc6209247c5dad7d01bc6. [14검사/33화면 검증](docs/qa/owner-gauge-six/VERIFICATION.json), [Actions](https://github.com/znzkznzk96-rgb/nakshiworld-update/actions/runs/39730517829) 성공.
- [6종73%모음](docs/previews/owner-six-applied.png), [저수지/계곡 실제적용](docs/previews/owner-runtime-applied.png). 6종0/73/100%에서이름/퍼센트/채움범위를직접검수. 주인경고와훅판정글자위치를분리하고짧은화면도확인.
- 요청/seed/실제전송참조/원본/receipt/지역별품질검수는 docs/qa/owner-gauge-six/0~5/. [전체아트검증](docs/qa/owner-gauge-six/ART_VERIFICATION.json). 앞선불합격1장은별도보존하며재사용하지않음.

## 유지되는 기능
지역전파츠장착시표시/실제포획 최종등급1/1/1/2/3%p·최대100, 다음성공훅에서해당주인확정/3초경고, 입질/훅MISS100유지·주인포획0/실패70·중복정산방지·지역별세이브유지. 가방목록/번들독립낱개기증/숫자보상/최근10개재구매도기존14검사통과.

## 다음 작업과 연결
사용자6종검토/다음지시를기다린다. 각지역1장요청완료이므로 임의추가생성/재생성금지. 계곡가격후보는보류. 계곡나머지전투/경제수치미정으로 실제입장비활성, 이후4지역번들/주인확정/주인업적은기존미정유지.
PixelLab은 **실제API호출경로검증완료**. 새대화에서목록검색을반복하지말고 [고정이어하기](docs/PIXELLAB_CONNECTION.md)를먼저읽는다. 비공개접속안내는사용자개인문서에보존,공개저장금지.

## 배포
work/valley-runtime 저장만, 사용자배포금지유지. main/버전/Release/PCK 미변경, 실제공개0.69. Android실기기적용/검증없음. 다음배포는새지시와production workflow의v0.68 baseline갱신/검증필요. 현재검사기준은v0.69 검증전체소스+작업overlay+삭제명세.
[직전HANDOFF원문](docs/historical/2026-10-22-before-six-frames/HANDOFF.md)은보존.

## 직전 제작착수 기록 — 우주바다 기준 공통스타일 재시안
사용자는 우주프레임 분위기를 선호, 높이를조금줄이고6지역공통골격으로다시시안요청. GAME_BIBLE최신항목과같이256×48px·지역별1장순차제작. 이번은시안만,기존게임프레임미교체/배포금지. 참조는기존우주프레임이며실제스타일/형태입력에사용한다.
