# v1.03 적용 후 공개 업로드 차단

사용자 적용·업데이트·배포 지시 후 로컬 구현·전체검사·41화면 렌더·패치빌드 완료 준비. 공개GitHub로 private아트전송은 자동승인검토가명시목적지/공개승인부족으로거절. 우회금지. 사용자에게 해당저장소 공개업로드 승인필요를설명한뒤기다린다.

완성2성15종 game/art/expedition/tier2/에실PNG·manifest. view.gd 성급선택·기존battle UID성급복원,관리/합성/편성UI의실제unit.star전달. 2성별도볼트중복제거. 효과너비가몸체축소시키지않는전투기준점정렬. 세이브/능력치/1성/3성변경없음. 도감은1성기본레시피표시유지.

원격기준 work/valley-runtime ab042ffd990083996a2d0b692fd1199cd1e772b3. 최신문서체크포인트가추가될수있음. 로컬deploy-work에는미커밋구현. `uploadEntries`에앞5이미지blob해시만있고게임commit/ref아직없음. private키/전체response/개인세이브업로드금지. 자동심사거절을다른경로로우회하지않는다.

승인후:최신head확인→패키지overlay를최신work에적용→전체원격blob/tree/commit저장+SHA대조→work CI검증/렌더→PR main병합→Release v1.03 asset3개확인→실제설치앱주소 manifest/PCK다운로드·크기해시검증→HANDOFF/WORK_STATE완료. 현재공개v1.02. 재생성없음.

정확한baseline v1.02 game-source.zip SHA256와업데이트후반영파일목록/해시는VERIFICATION와패키지manifest참조. 최초로컬재검사중재사용된테스트전용데이터로capture_robot실패;새격리디렉터리로다시검사,실제사용자데이터와무관.
