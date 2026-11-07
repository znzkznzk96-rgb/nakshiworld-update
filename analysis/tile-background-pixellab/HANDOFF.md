# PixelLab 타일배경13장 제작·검수 결과
2026-11-08 KST. 사용자가배경필요자산전부PixelLab제작승인.

총13단일요청/13원본수신. 내부통과5·보류8. 실제13회분차감,기술재시도0/품질재생성0/동시최대1. 모든잔여작업완료(유료요청in-flight0). 전체기획의완성은아니며8항목은미완성으로보류.

## 사용가능시안
덩굴·바닥수초2·벽수초·은청색장식어1. 실제native원본/nearest4x/실화면검토. 은청색어류는특정게임어종이아닌장식용일반물고기로만사용. 원경구름초기확대pass는실화면에서구슬윤곽판정으로hold로대체,QA에원인보존.

## 보류

- cloud-far: Initial native/4x geometry review passed, then actual-screen review failed: bead-like lobes and outline too prominent against approved tile sky. Prior pass is superseded; no regeneration.
- cloud-near: Three round ball-like lobes with heavy outline read as spheres rather than natural cumulus; withheld, no regeneration.
- horizon-mist: Solid wavy ribbon/lightning silhouette with hard contour, not soft sparse water mist; left edge contact. Withheld.
- ledge-grass: Generated a square stone-floor scenery tile around the grass, not an isolated transparent plant; cannot safely overlay on approved background.
- fish-far: Single complete fish/alpha/tail are usable, but output copied pink/amber reference stripe and fins rather than specified turquoise/coral; left-facing. Color target not met, withheld rather than silently accepted.
- fish-near: Body became lumpy/spotted with yellow-green wash, cream bands/coral fins missing; not the intended clear reef-fish design. Withheld; no regeneration.
- bubble-cluster: Five bubbles rendered, but gray checkerboard-like pixels are baked inside rather than transparent interiors. Not safe to use as requested; withheld without extra generation.
- water-specks: Full32x32 opaque alpha255 with baked checkerboard and one central mote instead of sparse transparent flecks; not usable overlay.

## 파일과검증
SPEC.json/AS_SENT_*/RESPONSE_* 실제입력/응답·seed/model·참조·차감,QA.json 항목별검수,MANIFEST.json 원본해시,LEDGER.json 실잔액차감. NATIVE_REVIEW/USABLE_REVIEW/PREVIEW 시각자료,VERIFICATION.json 화면/GIF. 보류원본은성공참조/게임적용금지. staging은통과5장만있음.

## 적용상태
기존본편의3지역빛/타일수면유지. 신규13장아트는analysis에서만제작·검수,게임반영/배포없음. 그림검토용프리뷰에통과5장만연결. 메인game폴더/버전/소스ZIP/PCK를이번에변경하지않음.

## 다음
품질보류8장과기존사용가능5장을구분해사용자검토. 자동추가유료생성없음. 과거실패요청그대로반복금지. 필요시항목별구체입력수정안을준비하고허용범위확인후수정.
