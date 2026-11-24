[영상](SSS-pixel-unified.mp4) · [Godot 소스](GachaCutscene-SSS-Pixel-Unified.zip)

# SSS 픽셀 통일판

Godot 4 독립 데모. F5로 SSS를 재생한다. 1~7은 D~SSS 선택, 스페이스는 다시 재생. 기존 7초 각성 시퀀스와 기존 붕어·해룡 스프라이트를 사용한다. PixelLab 신규 생성 0회.

## PixelLab 프롬프트와 파츠

승인한 기존 스프라이트를 참조로 넣고 상단 왼쪽 광원, 같은 ¾ 시점, 일정한 실루엣과 포즈 기준점을 고정한다. 같은 투명 PNG에 배경·외광·폭죽을 함께 그리지 않는다. 원본 크기와 2배 확대에서 픽셀 덩어리, 팔레트, 투명 테두리를 나란히 확인한다.
| 파츠 | 규격 | 프롬프트 핵심 |
|---|---|---|
| 붕어 | 투명 96×96, 점프와 회전 8~12포즈 | Exact approved round crucian carp, head leads the jump, tail follows, compact fins and black eye. Amber shadows, honey-gold mids, ivory highlights, upper-left light, two or three broad scale clusters, no glow or particles. |
| 해룡 | 투명 96×96, 등장 6~8포즈, 호버 4~6포즈 | Preserve approved eyes, horns, cyan palette and proportions. Chin lifts, wings settle, feet tuck. Indigo shadow, teal middle, pale mint highlights and tiny warm glints on horn tips. Fixed pivot, no aura. |
| 밤바다·각성 무대 | 135×240 목표, 하늘·해안·수면 반사 분리 | Match horizon and hard pixel scale. Navy and teal shadow; gold only on eclipse rim and pillars. Visual detail at edges, quiet center. |
| 스파크·링·왕관 | 투명 16×16 스파크, 64×64 링/왕관 | One effect per sprite, separated rays, hard stepped clusters, cream tip and two gold shades; no bloom. |
| 엠블럼 | 102×39 목표, 테두리·보석·광택 분리 | Symmetrical gold edges and contained purple shadow, no lettering or background. |

## Godot 구현

배경을 135×240으로 정리한 뒤 nearest 2배로 배치한다. 270×480 논리 화면에 viewport stretch, integer scaling, 2D transform snap을 적용한다. 붕어·해룡 기본 배율은 각각 3배와 2배다. 카메라의 비정수 줌이나 회전 중에는 nearest에서도 일부 픽셀 폭이 달라질 수 있다.
```gdscript
texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

fish.scale = Vector2.ONE * 3.0

_rim.set_shader_parameter("rim_strength", 0.28 + 0.10 * _aurora)
```

SpriteRim.gdshader는 상단·왼쪽 알파 이웃을 읽어서 실루엣 안쪽만 밝힌다. Shockwave.gdshader는 굴절 위치를 논리 픽셀 중심으로 다시 샘플링한다. Tween이 전조·줌·체공을, AnimationPlayer가 폭발·엠블럼 타격을 담당한다.

0–2.2초 전조, 2.2–3초 각성 무대와 80ms 정지, 3–5.1초 점프·슬로우·응축, 5.1–7초 왕관·고리·SSS 각인. 포즈를 새로 작화하는 항목은 위 프롬프트 표에 있다. 영상은 Godot 실행 상태를 바탕으로 별도 렌더링한 무음 시안이다.
