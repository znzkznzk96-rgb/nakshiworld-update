# 참고 CanvasItem 셰이더 교체 적용
2026-11-08 KST. 사용자 참고 셰이더코드를 실제 빛 시안에 적용.

기존 light() draw_polygon광축 제거,4개TextureRect+독립ShaderMaterial로교체. tile_light.gdshader는blend_add,반복NoiseTexture128,UV.y시간흐름/sin가로왜곡/texture샘플/depthfade 참고구조. 부채꼴silhouette는왜곡전UV로분리,좁은tip/넓은하단폭과기존비동기랜덤폭·실제environment.hour()태양기울기유지. 전체source801x750수중좌표양자화/nearest,마스크가장자리연속감쇠. 알파중복곱제거.

첫노이즈가구름처럼뭉쳐세로결로늘이고대비를완화한최종본. FastNoiseLite seed와명시elapsed로재현가능,밤엔숨김. shader_node검사4독립재질/반복/시간uniform/야간숨김통과. nativeOpenGL호환렌더실제셰이더컴파일오류없음. 물고기등다른레이어없이빛만0/3/7초추가캡처하여실제움직임픽셀확인,전체8초GIF96프레임검사. VERIFICATION.json.

본편전체레이어통합/1.10검증후보교체/공개배포아님. 분석시안runtime에교체적용한상태. 기존아트원본·다른레이어·세이브·밸런스유지,추가유료생성0. 셰이더실행경로res://tests/tile_light.gdshader,수중컨트롤러res://tests/tile_water_layers.gd. 이디렉터리capture_video.gd/shader_verify.gd/isolated_capture.gd로재현.
