# Monster motion and combat balance v1

Final transparent pixel assets and authoring sources are in the binary split ZIP. Run `python3 restore.py` to validate SHA256 and ZIP CRC and extract to `restored/`.

Contains all normal18 final keyposes (HIT background fixed), four boss motion sets (only10R revised), Godot resources and preview scripts, balance data and deterministic simulation. Raw generated source sheets and video frame caches are excluded. Preview can be rebuilt with included scripts using @napi-rs/canvas and ffmpeg. All balance files are also directly readable here. Game integration/deployment and Godot runtime testing not performed.



## 2026-10-26 몬스터 모션·10R 강화·전투 수치 v1 완료
- 사용자 요청으로 기존 GitHub work/valley-runtime에 소스·최종 투명PNG·수치·검증 코드 백업. 배포/게임 적용 없음.
- 일반18종: HIT18프레임 잔여 사각 배경 제거, 나머지108포즈 기존 승인본 유지.
- 보스4종: 대기/공격/피격/죽음 각6프레임, 총96프레임. 10R만 몸통·팔·발톱 확대 및 320x320 프레임 교체; 3R/5R/7R PNG byte identical. 다른3종224x224. 모든 프레임 비어있지 않음, 테두리침범0, 반투명 잔여배경0. Godot런타임 미검증.
- 병사15종 1/2/3성 HP/ATK/DEF, 일반18·보스4 HP/ATK/DEF 설정. 10R=1000/70/40.
- 3인팀, 모든생존병사1.5초마다행동, 선두피격. 피해=max(1,round_half_up(ATK*100/(100+DEF))). 지원형3번째행동은공격대신ATK*0.8회복(초기제안).
- 출발체력100%, 일반15→일반16→10R 연속전투 기준. 라운드 내 체력유지. 라운드 간무료회복확정아님. 레벨/장비/속성/희귀도보정 제외.
- 방어/공격/지원 125조합: 전원1성0; 2성1마리0; 2성방어+2성공격+1성지원120(96%); 전원2성125. 이는 결정론적 조합 통과비율이며 확률승률 아님. 2성 두마리 아무조합이나 보장하는 방식 아님. 3성방어 대체성장경로 허용.
- 백업: docs/design/monster-balance-v1/ (manifest.json, restore.py, assets.zip.part000..023). python3 restore.py로 최종PNG 및 제작코드 복원, SHA256/ZIPCRC검증. 생성원본 시트·동영상캐시는 제외. 읽기쉬운 balance.json/CSV/HTML/시뮬레이션도 같은 경로에 별도 보존.
