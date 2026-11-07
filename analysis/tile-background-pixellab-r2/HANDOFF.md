# Tile background retry — 2026-11-07

Isolated preview only; not integrated into game/ and not deployed. Public release remains v1.09.

Seven static PixelLab calls and one flight animation call completed sequentially; actual balance decrease 8 units. No pending paid jobs. Actual tile-sea originals (12 species) replace generic decorative fish, in three depths and both directions. Four previously passed PixelLab plants retained; small floor-ribbon plants fill the held ledge-grass role.

Final scene review overrides initial individual sprite passes: cloud-far, cloud-near and horizon-mist show rectangular noisy texture edges at game scale and are excluded. Ledge-grass is also held (wreath morphology). Bubble-cluster, water-specks and gull pass. No further paid retry performed. Clouds/mist remain unfinished.

Gull flight job fda4ebfe-767e-49d5-a1ab-af20ccbaa6b3 completed: requested 8 intervals, API returned 9 PNG frames, all used because endpoint pixels differ. Appearance stable and wings uncut. Refer to FLIGHT_QA.json, QA.json, LEDGER.json, MANIFEST.json and ACTUAL_TILE_FISH.json.

Preview uses native 540x1320 Godot capture, 150 frames / 10 seconds / 15fps. Renderer and capture scripts are analysis assets only. New background source is not a deployable release candidate. Next: review accepted plants/fish/birds/bubbles, resolve held clouds separately, then integrate approved composition into production and run relevant tests. No release approval.
