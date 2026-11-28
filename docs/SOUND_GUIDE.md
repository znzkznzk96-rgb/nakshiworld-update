# 사운드 작업 가이드 (v1.60·v1.61에서 실제로 쓴 방법)

새 세션은 소리 작업 전에 이 문서만 읽으면 된다. 출처 기록은 `game/sfx/CREDITS_v160.txt`.

## 1. 어디서 구하나 (모두 무료, 결제 금지)
- **BigSoundBank** (CC0, 실제 녹음 3,500개+): 셸에서 바로 받아진다.
  - 검색: `python3 automation/sound/bsb_search.py "fishing reel" chain splash` → 번호·이름·길이 목록
  - 받기: `curl -sL -o 1435.mp3 https://bigsoundbank.com/UPLOAD/mp3/1435.mp3` (번호 4자리). python urllib는 막히고 curl은 된다.
- **OpenGameArt** (CC0만 필터): 셸에서 받아진다.
  - 검색: `python3 automation/sound/oga_search.py music "calm loop" peaceful` / `... sfx splash bubbles`
  - 받기: 페이지(`https://opengameart.org/content/<이름>`)에서 `sites/default/files/...` 주소를 찾아 curl. 페이지의 라이선스가 CC0인지 꼭 확인.
  - 쓴 것: Juhani Junkala "JRPG Music Pack #4 Calm"(마을 Calm5), "Fields of Cabbage"(타이틀), "40 CC0 water/splash/slime SFX"(물소리).
- **Kenney** (CC0): kenney.nl은 셸에서 403. 사용자가 zip을 올려 준다(이미 받은 것: impact-sounds, interface-sounds, ui-audio, music-jingles).
- **PulseLite** (CC-BY-4.0): 출처 표기 의무. 게임 안 표기 위치는 아직 미정 → 쓰려면 먼저 사용자에게 확인.
- 사용자가 올린 zip은 `/mnt/user-data/uploads`에 있다. 압축은 각각 새 빈 폴더에 푼다.
- **Free-Game-Dev-Assets** (사용자가 준 무료 에셋 모음 사이트): https://tmhsdigital.github.io/Free-Game-Dev-Assets/
  - 사용자가 지정한 항목: https://tmhsdigital.github.io/Free-Game-Dev-Assets/entry/tallbeard-abstraction-music-loop-bundle/ (tallbeard Abstraction Music Loop Bundle). 이 안의 배경음악 **마지막 곡**을 쓰라고 함. 아직 받지 않음(잔잔한 곡은 OpenGameArt로 대신했음). 받기 전 항목의 라이선스·다운로드 위치(itch.io 등)를 확인하고, 결제가 필요하면 멈추고 사용자에게 묻는다.
  - 사용자가 처음 보여준 인스타그램 추천 목록(사이트 주소가 순서대로 적힌 캡처)은 이 문서에 옮겨 적지 못했다. 다시 받으면 여기에 추가한다.
- itch.io 유료/후원 번들은 사용자 결정 전 받지 않는다.

## 2. 게임에서 어떤 파일이 어디서 울리나 (같은 이름·경로로 덮어쓰면 코드 수정 없이 교체됨)
- `game/sfx/refresh65/*.ogg` → `addons/reservoir/audio_feedback.gd`가 읽음:
  water(퐁당·작은 물), splash(큰 물보라·착지), bubbles, swim, rain(반복), thunder, tension, click(UI), hook, catch, record, snap, hammer, reel, music(타이틀 음악, 반복)
  - 물고기 동작별 연결은 audio_feedback.gd의 `SOUNDS` 표. swim·bubbles 등은 -13dB로 작게 남.
  - main.gd의 `play("ui"/"plop"/"splash_s"…)`는 `replacement` 표로 위 이름에 연결되고 -8dB 더 작게 남.
- `game/sfx/refine68/cast.ogg` 던지기 / `game/sfx/village/village.ogg` 마을 음악(반복), gull1·gull2·horn(마을 효과음)
- `game/sfx/forge138/{light,medium,heavy,success,failure}.wav` 강화
- `game/sfx/unlock/{unlock_chain_pull,unlock_latch,unlock_chain_release}.wav` 낚시터 잠금 해제
- `game/art/pet_hut/slot/sfx/{lever,spin,reel_stop,reveal,win_0~6,jackpot}.wav` 펫 뽑기
- 아직 안 바꾼 것: main.gd가 직접 읽는 `game/sfx/drag.wav`, `drag_recording.ogg`(끌기), thunder.ogg, 마을 gull·horn

## 3. 가공 (ffmpeg)
- 짧은 효과음: 앞 무음 자르고 모노 44.1kHz wav
  `ffmpeg -y -ss 시작 -t 길이 -i 원본 -ac 1 -ar 44100 -af "silenceremove=start_periods=1:start_threshold=-45dB,afade=t=out:st=끝-0.05:d=0.05" 대상.wav`
- 반복 소리·음악: ogg `-c:a libvorbis -q:a 4`. 음악은 스테레오 그대로 둬도 됨(약 1MB/분).
- **주의(실수 기록)**: `afade=t=out:st=0:d=0`처럼 길이 0 페이드를 넣으면 무음 파일이 된다. 변환 후 크기·길이 확인.
- 크기 맞추기: `ffmpeg -i 파일 -af volumedetect -f null -` 로 max/mean을 보고 기존 소리와 비슷하게(최대 -1~-3dB). 너무 작으면 `volume=+NdB,alimiter=limit=0.8`.
- 여러 소리 겹치기: `-filter_complex "[0][1]amix=inputs=2:normalize=0"`, 음 높낮이: `asetrate=44100*0.6,aresample=44100`.

## 4. 검사에 걸리는 기준 (바꾸면 같이 확인)
- `tests/spot_unlock_audio_verify.gd`: 잠금 해제 소리 3개는 각 0.3~0.7초.
- `automation/verify_packed_art.gd`: 마을 음악 길이 > 60초(v1.60에서 27초 고정 검사를 바꿈. 짧은 곡으로 바꾸면 이 줄도 고친다).
- 바꾼 소리 경로를 테스트가 쓰는지: `grep -rn "파일이름" game/tests automation`.

## 5. 사용자 확인 방법
- 공개 전에 "이전/새" 짝으로 zip을 만들어 보낸다(번호_이름_이전.ogg / _새.ogg). 음악 후보는 45초 미리듣기 mp3 여러 개 + 번호로 고르게 한다.
- 고르면 출처를 `game/sfx/CREDITS_v160.txt`에 한 줄 추가하고, 버전을 올려 공개(공개는 사용자 "공개해" 뒤).
- 사용자 취향 메모: 마을·타이틀은 느긋하고 잔잔한 곡(신나는 곡은 어색하다고 함). 효과음은 체감이 확실히 달라야 함(자주 나는 물소리부터).
