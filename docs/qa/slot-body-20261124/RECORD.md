# 슬롯 본체 재제작 (2026-11-24)
- 1차 image-to-pixelart-pro: 95x143로 줄어 도트가 굵어져 불합격(생성권 20회분).
- 2차 create-image-pixflux(init_image=기존 본체, 256x368, strength 750, seed 7): 합격. 생성권 1회분.
- 분홍 배경(#ff00ff) 제거 후 255x365로 잘라 art/pet_hut/slot/body_empty.png 교체. 첫 호출 결과 저장 누락으로 1회분 재호출 포함, 총 22회분.
