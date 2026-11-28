# 컷신 5컷 (마지막, 초안)
흐름: 거대한 달 앞 부두 끝에 낚싯대를 멘 연구원과 흰 고양이가 실루엣으로 섬(바람에 머리카락·꼬리 흔들림) → 자막 "여기선… 어떻게 탈출해야 하지…?" 타자 → 4.5초부터 부두와 인물이 아래로 빠지며 달이 화면을 채우고 밝아짐 → "낚시월드" 로고(게임 game/art/ui/updater/logo.png 재사용)와 종소리 → 암전. 약 7초.
- 그림(PixelLab 64회분, 레이어 분리): source/ c5_bg(달·호수 배경) c5_fg(부두 언덕, 투명) c5_res_0~3 중 3번 → c5_resA_0~8(바람 애니메이션) c5_cat_0(달 조각 제거) → c5_catA_0~8(꼬리 애니메이션, 1/2 최근접 축소).
- 연출: proj/main.gd + sil.gdshader(실루엣·위쪽 1도트 달빛 테두리) + moon.gdshader(달만 밝힘·계단식 번짐·수면 반짝임). 소리는 gen_sfx.py 합성(wind, chime) + 2컷 blip·water.
- Godot Glow는 도트를 흐리게 하므로 쓰지 않음. 타이틀 씬 연결은 게임에 넣을 때 한다.
- 녹화: `godot --path proj --write-movie out.avi --fixed-fps 30 --resolution 1080x2400 --quit-after 225` (먼저 `--headless --import`).
