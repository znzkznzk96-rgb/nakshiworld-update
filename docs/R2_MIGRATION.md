# 낚시월드 R2 이전 상태

## 확인된 사항
- 저장소 main에는 README.md, patch.pck, version.json만 있다. 전체 게임 소스나 tools/publish_patch.sh는 없다.
- 마지막 배포 패치는 code 57 / name 0.57, 24,988,912 bytes.
- SHA-256: 8905e55b141bb6f5411e3644c648c844bd86031fe8ce66dbc296c0603ff296b8.
- R2 bucket: nakshiworld-updates. Worker binding: GAME_PATCHES.
- 사용자가 Worker를 배포하고 /test.txt에서 ok 응답을 확인했다.
- 보유한 별도 소스 ZIP은 0.49다. 0.57 PCK에는 원본 .gd 대신 .gd.remap과 컴파일된 리소스가 있어 최신 원본 소스로 간주할 수 없다.

## 아직 완료되지 않은 사항
게임 APK의 부트스트랩(root.gd)은 패치를 로드하기 전에 실행된다. 현재 확인한 root.gd는 GitHub의 고정 version.json, patch.pck를 읽는다. PCK 안의 root.gd만 변경해도 이미 실행 중인 부트스트랩은 교체되지 않는다. 따라서 기존 앱을 R2로 완전히 이전하려면 최신 원본 프로젝트와 기존 서명으로 만든 전환 APK가 한 번 필요하다. 이후 호환 가능한 게임 내용 변경은 PCK 자동 업데이트로 계속 배포한다.

원본 서명키나 토큰은 공개 저장소에 넣지 않는다. 기존 배포 파일과 GitHub version.json은 전환이 검증될 때까지 그대로 보존한다. 0.58/0.59 소스가 확인되지 않았으므로 해당 버전이 복구되었다고 간주하지 않는다.

## 준비된 명령
실제 최신 프로젝트가 확보된 후 실행:

```sh
python3 tools/configure_r2_updates.py /path/to/project/game/root.gd
python3 tools/configure_r2_updates.py /path/to/project/game/root.gd --check
```

이 명령은 UPDATE_BASE 한 줄만 변경한다. 전환 APK의 BUILD_CODE, BUILD_NAME, Android version/code와 version/name을 마지막 적용 패치보다 큰 값으로 함께 올려야 한다. 기존 패치가 전환 APK를 덮지 않게 버전 규칙을 확인한다. 세이브 파일을 삭제하거나 앱을 제거하지 않는다.

실제 PCK를 검증·빌드한 후 배포 계획 확인:

```sh
python3 tools/publish_r2_patch.py build/patch.pck 60 0.60 --dry-run
```

60은 예시이며 최종 버전 예약이 아니다. 이 도구는 빌드 도구가 아니며 최신 게임 파일을 생성하지 않는다.

배포 시 AWS CLI v2와 R2의 해당 버킷에만 Object Read & Write 권한을 가진 인증이 필요하다. R2_ACCOUNT_ID, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY는 로컬 환경 또는 CI secrets로 설정한다. 채팅이나 git에 비밀값을 붙이지 않는다.

```sh
python3 tools/publish_r2_patch.py build/patch.pck 60 0.60
```

스크립트는 이전 manifest 보관, 버전 역행 차단, 해시 경로에 PCK 보관, 고정 patch.pck 업로드, 원격 크기·메타데이터 확인, version.json 마지막 업로드 순서로 동작한다. 배포는 동시에 실행하지 않는다. R2 인증과 실제 업로드는 아직 실행하지 않았다. 전환 APK에서 다운로드, 재실행, 세이브 유지, 오프라인 시작을 실기기로 확인한 뒤 완료 처리한다.
