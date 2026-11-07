# v1.10 게시 보완 — 2026-11-08

최종소스12dfd5d1b96aa2ecfee558d491991d123950700a 전체78/모든화면/실제PCK검사 CI42423468177 성공. 후보artifact13594114063, fingerprint6ffaa8c8854dd132aa070b8e7d383be682c38d6d22a3c09313dbf0206558414a. PR46 main merge38f7b311.

게시42424163257에서 동일후보 다운로드/검증·v1.10초안 및3파일 업로드 완료. 마지막 REST releases/tags/v1.10 조회가 초안에404를 반환해 공개 전 중단. 초안ID437904558, target=검증소스12dfd5d1. 파일손상없음. 신규빌드/전체검사 반복 불필요.

새 resume-verified-publication workflow는 원본 fingerprint/validate를 그대로 사용하고 성공workCI 후보의 실제ZIP/PCK/manifest SHA·크기와 초안3파일 digest/target을 재검증한 뒤 release ID로 PATCH draft=false. 게임/도구검증입력은 변경하지 않음. 공개후 원래게시실패job128558737831을 재실행하면 already_published 확인 경로가 성공하며 기존 자동gateway검증이 이어짐. 휴대폰미확인.
