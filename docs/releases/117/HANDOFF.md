# v1.17 공개·운영 검증 및 APK 전달 완료 — 2026-11-09
쨍한파랑/청록·크림/노랑로더,PixelLab흰고양이9장/주황물고기원형추격·굵은로고±1.5도흔들림·실제십진MB/단계별진행표시. 기존세이브/경제/보상유지.

소스31e8924487b91bc1f6f5d3fb4c56b8d30807efc1·[전체CI](https://github.com/znzkznzk96-rgb/nakshiworld-update/actions/runs/42621403752) 성공93종/native/PCK. 동일후보13676398457 재빌드없이공개,PR55병합5064c7349c87a17eaf645e92c88d6a233fe67299. 공개42627907414 attempt2성공(초안목록지연후같은초안재개). 운영42628222139 첫시도성공:APK업데이트주소manifest/PCK다운로드·해시와공개3파일/소스ZIP CRC/overlay641파일대조. [공개파일증거](PUBLISHED.json),[모션검증](../../qa/updater-redesign/MOTION_VERIFICATION.json).

새로더는APK부트스트랩이므로NAKSHIWORLD_1.17.apk도제작해사용자에게전달. 83,124,743bytes·원본제공APK(0.11)와인증서SHA256일치,동일com.sangjun.dotfishing·versionCode117/name1.17. v1/v2/v3서명·16KB ZIP정렬·PNG/ZIP CRC·승인아이콘24종·원본native2파일/classes.dex/resources.arsc동일성·Godot4.4.1실제APK자원미러부트스트랩실행검사통과. [APK검증](APK_VERIFICATION.json).
APK는봉인PCK전체자원에APK전용root.gd.remap/추가[apk_bootstrap117.gd](apk_bootstrap117.gd)만적용해BUILD117/1.17로맞춤. 동일버전불필요다운로드/구패치마운트방지. [정확한차이](APK_RESOURCE_DELTA.json). 공개PCK/전체소스는봉인바이트그대로. 원서명키/비밀번호/개인설정미포함.

APK는사용자파일NAKSHIWORLD_1.17.apk로보존·전달했고,기존앱삭제없이덮어설치안내완료. 휴대폰실제설치/실행·세이브확인은아직미확인. 다음사용자휴대폰피드백,새기능/새패치배포미승인.
