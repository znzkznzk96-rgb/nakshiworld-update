# Fight body size correction — 2026-11-08

User means actual hooked fish during fighting, not bite preview. Baseline publicv1.10 source12dfd5d1b96aa2ecfee558d491991d123950700a. Previous helper already reached fighting but visual growth was weak. Add explicit physical-length-based fight-body length override; preserve small<=20cm, add min(72,max(0,actual_cm-20)*0.8), cap156. Keep mouth/tension HUD/landing consistent. Bite shadow, decorative fish, measurement/result, gameplay balance and saves unchanged. Relevant tests and actual before/after screenshots required. No deployment/new paid art.
