> 최신 지시(2026-11-06): 아래 과거 복구→검증→배포 절차는 실행하지 않는다. 사용자가 복구를 취소하고 손상 저장본만 삭제하도록 지시했다. 현재 상태는 WORK_STATE 및 최신 HANDOFF가 우선한다.

# Codex에서 바로 이어하기 — 2026-11-06 KST

다운로드/프록시 오류가 나면 [네트워크 오류 이어하기](CODEX_NETWORK_RECOVERY.md)를 먼저 따른다. 새 Codex 환경의 연결·인증이 검증됐다는 의미가 아니다.

## 첫 행동
WORK_STATE가 지정한 `work/tile-release-107`의 최신 원격 HEAD를 사용한다. 1.07 구현 기준은 `c18f28d3be7c3dbe2486c9bc87de53e333a7059e`. 이 문서 커밋은 게임을 변경하지 않는다. Git clone 후 main에 머물면 1.07을 놓친다.

```bash
git fetch origin
git switch work/tile-release-107
```
로컬 동명 브랜치가 없으면 `git switch --track origin/work/tile-release-107`. 수정된 작업공간에는 강제 checkout/reset을 사용하지 않는다. 후속 구현은 이 브랜치에서 저장해야 기존 작업 CI의 브랜치 필터가 적용된다.

## 현재 상태와 재개 순서
- 공개 최신은 v1.06, Release 3파일과 배포/운영 검증 Actions 성공을 직접 확인했다. 계곡 개선은 사용자가 휴대폰에서 확인한 기록이 GAME_BIBLE에 있다.
- v1.07: 깔끔한 B 배경/native 표시, 물고기 최종20종(12/17 교체), 번들·입장·기록·저장실패 롤백 구현은 원격에 있다. 기능검사 통과는 직전 HANDOFF 보고이며 이번에 게임 검사를 재실행하지 않았다.
- **막힌 곳:** 원격 `game/art/bg/tile_sea_clean.png`가 PNG 디코드 실패이며 ASSETS.json의 승인 원본 SHA와 불일치한다. 물고기20종은 디코드와 기록 SHA 일치 확인. 상세 해시는 [증거](handoff/2026-11-06/EVIDENCE.json).
- CI 42071213782는 Import and full regression checks에서 실패했고 후속 native 화면 검사/렌더는 실행되지 않았다. 전체검사 통과나 1.07 공개 완료로 보고하면 안 된다.

1. 승인된 깨끗한 B 원본을 기존 보존처에서 찾아 ASSETS.json의 SHA256과 PNG 전체 디코드를 확인한다. 이름·썸네일만으로 선택하지 않는다. 원본 SHA `8149e81a427aaa87a47b460dacbcee4deb293615cf3560c22b3bc6c359c089b7`, 809×1944. 이미지 재생성/저해상도 확대는 금지. 원본 검색 후보는 2026-11-06 생성된 깔끔한 청록 수중 배경이며 파일명은 원본 선택 근거가 아니다. 일치 원본을 찾지 못하면 이 한 항목만 차단으로 보고한다.
2. 원본 바이트를 손상 없이 복원해 해당 파일만 교체한다. 원격 binary blob 업로드 후 재다운로드 SHA와 PNG 디코드를 검사한다. JSON/문자열 경유로 바이너리를 손상시키지 않는다.
3. 아래 절차로 전체소스를 복원하고 import, tile107 관련검사, 전체 회귀 및 native 화면을 확인한다. 실패했던 검사는 복구된 소스에서 다시 수행할 근거가 있다.
4. 기존 사용자의 1.07 배경·번들 적용/배포 승인 범위에서 배포한다. 새 장식 레이어·라이선스 재생성·다른 게임 변경은 포함하지 않는다. 유료 호출 필요0.
5. Release의 소스 ZIP/PCK/version.json 크기·SHA·source_commit 및 실제 앱 다운로드를 검증하고 기록한다. 휴대폰 적용 성공은 별도다.

## 전체 게임 복원·실행
현재 기준 v1.06 전체소스 ZIP은 61,642,915bytes이며 SHA256은 `3c4b1a317955fa53f2f8351d9fbd1d0978502cafd0f6655a969132b6ab064dd5`. 원격 Release가 갱신됐다면 최신 상태와 차이를 먼저 확인한다.

```bash
curl -fL https://github.com/znzkznzk96-rgb/nakshiworld-update/releases/download/v1.06/game-source.zip -o ../source-v106.zip
printf '%s  %s\n' 3c4b1a317955fa53f2f8351d9fbd1d0978502cafd0f6655a969132b6ab064dd5 ../source-v106.zip | sha256sum -c -
python3 automation/restore_source.py ../source-v106.zip ../runtime-107
```
복원 대상은 존재하지 않는 새 폴더여야 한다. 스크립트가 ZIP CRC/경로를 검사하고 `automation/deleted-game-files.json` 적용→game/ overlay→탐험 에셋 준비까지 실행한다. `.godot`는 복사하지 않는다.

Godot **4.4.1 stable**, Python3, Git, 렌더용 Xvfb/Mesa가 필요하다. 설치 명령/버전 고정 URL은 [.github/workflows/verify-work.yml](../.github/workflows/verify-work.yml)이 실행 원본이다. `GODOT`에 해당 실행파일 절대경로를 지정한다.

```bash
"$GODOT" --headless --editor --path ../runtime-107 --import
XDG_DATA_HOME="$PWD/../isolated-tile107" "$GODOT" --headless --path ../runtime-107 --script tests/tile107_verify.gd
XDG_DATA_HOME="$PWD/../isolated-native" xvfb-run -a "$GODOT" --audio-driver Dummy --rendering-method gl_compatibility --path ../runtime-107 --script tests/tile107_native_verify.gd -- "$PWD/../tile107-preview"
```
전체 검사/베이크/렌더 순서와 로그 판정은 verify-work.yml 그대로 따른다. 단순 exit0만 보지 않고 `VERIFY failures=[]` 및 오류문구 부재를 확인한다. 테스트별 XDG_DATA_HOME을 분리한다. PCK 배포는 APK 재설치와 다르며 앱 삭제/데이터 초기화 금지.

## 파일 지도
| 목적 | 원본 |
|---|---|
| 기획·승인·미정·폐기 | [GAME_BIBLE](GAME_BIBLE.md), 날짜별 최신 결정이 옛 문구를 대체 |
| 현재 상세/자산 해시 | [1.07 HANDOFF](releases/tile-107/HANDOFF.md), [ASSETS](releases/tile-107/ASSETS.json) |
| 번들 선정/라이선스 | [BUNDLE_AUDIT](art/tile-background-new-20261106/BUNDLE_AUDIT.md), 마지막 적용 승인과 함께 읽기 |
| 코드·리소스 overlay | game/; 전체 실행본은 Release ZIP과 결합 |
| 전체 소스 복원/삭제 | automation/restore_source.py, automation/deleted-game-files.json |
| 배포 버전/노트 | automation/release.json, automation/prepare_release.py, CHANGELOG.md |
| 공개 배포/운영검증 | .github/workflows/release-patch.yml, verify-deployment.yml, deployment/verify_public_release.py |
| 아트 정책 | [FISH_ART_RULES](FISH_ART_RULES.md), [PixelLab 연결](PIXELLAB_CONNECTION.md) |
| 오래된 복구물 | docs/historical, docs/LOCAL_RECOVERY.md, 이전 브랜치; 최신에 통째로 덮지 않기 |

## 이전 범위와 한계
`work/skills-105`는 미합류/보류 이력이 있는 별도 브랜치다. 전체 병합하면 이번에 제외한 타일 레이어 등이 섞일 수 있으므로 필요한 diff만 조사한다. 승인 아트·밸런스는 임의 변경하지 않는다. 거절 물고기20종과 최종20종을 혼동하지 않는다.

이번 첨부 `NAKSHIWORLD_FULL_HANDOFF(1).zip`은 전달 실패로 읽지 않았다. 현재 게임 기준은 원격 Release/브랜치이며 해당 옛 ZIP은 재개 필수자료가 아니다. 미저장 과거 채팅·다른 환경 scratch가 모두 복구됐다는 의미가 아니다. PixelLab의 비공개 인증과 일부 제작 원본은 공개 GitHub에 포함하지 않는다. GitHub 접근만 있는 Codex는 게임 작업은 가능하지만 비공개 아트 도구 설정은 별도로 접근 가능해야 한다. 사용자가 가진 설정/안내를 먼저 재사용하고 키를 채팅/공개 저장소에 요구하지 않는다.
