# 부채꼴 폐기·자체생성 노이즈 세로빛결
2026-11-08 KST. 최신사용자스포트라이트거절/1자세로빛결요청이이전부채꼴요구대체.

관측원인:기존텍스처는회색노이즈였고삼각형형태는셰이더tip/bottom마스크에서발생. mask와origin4개/폭등급/4재질제거. 단일수중TextureRect/ShaderMaterial에서직접2Dvalue noise+3octave fbm2층 생성. 가로고주파/세로저주파로폭이불규칙한수직빛결,깊이별폭확대계산없음. 느린노이즈이동·미세warp·깊이감쇠. 해방향은일주기공통shear로만연동하며발산광원없음. 중립1x1흰quad외패턴텍스처/외부이미지없음.

원본아트·다른장식/수면/기포/수초/밸런스유지. nativeOpenGL셰이더오류0,단일field/입력패턴없음/시간uniform/해방향/밤숨김검사,3높이표시/장면전환/해제,빛단독0/3/7초화면변화/8초GIF검사통과. VERIFICATION.json. 시각최종채택은사용자미정.

본편전체레이어통합·기존v1.10후보교체·배포없음. 추가유료생성0. res://tests/tile_light.gdshader 및 tile_water_layers.gd 교체시안. capture_video.gd/isolated_capture.gd/shader_verify.gd로재현. 이전부채꼴은실패시안이력으로보존하며현재요구로재사용하지않음.
