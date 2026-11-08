# Fight body size correction — 2026-11-08

User means actual hooked fish during fighting, not bite preview. Baseline publicv1.10 source12dfd5d1b96aa2ecfee558d491991d123950700a. Previous helper already reached fighting but visual growth was weak. Add explicit physical-length-based fight-body length override; preserve small<=20cm, add min(72,max(0,actual_cm-20)*0.8), cap156. Keep mouth/tension HUD/landing consistent. Bite shadow, decorative fish, measurement/result, gameplay balance and saves unchanged. Relevant tests and actual before/after screenshots required. No deployment/new paid art.

## 2026-11-08 resumed implementation
Explicit fight-body length connected to real/clone fish, mouth geometry, tension HUD and landing snapshot. Line now uses current-frame mouth. Full v1.10 source CRC/SHA verified before overlay. Related fight_body_size/fish_anchor_size/fish_presentation passed on Godot4.4.1 with isolated saves. Native after screenshots passed; baseline comparison in progress. No publication.

Actual landing implementation is addons/reservoir/angler_scene.gd; connected same explicit length and tail-drop origin. Native fight→landing assertions now pass. Comparison: [before/after](comparison.webp). Full QA details: [VERIFICATION.json](VERIFICATION.json). Latest public release remains v1.10.

## Final verification
Final source `466cb3c89301d4f952a03e96c6ccead1392b0aa5`: full CI [42432192399](https://github.com/znzkznzk96-rgb/nakshiworld-update/actions/runs/42432192399) success, including all regression suites, common/native screens, isolated save checks and actual PCK. Verification artifact13597648289. Comparison and logs are remotely saved. Next: user visual review; no new release version/publication authorized. The CI candidate uses existing1.10 settings for validation only; do not republish over v1.10. Future publication needs an explicitly prepared new version and matching final-source candidate.
