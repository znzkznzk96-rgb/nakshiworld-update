# v0.91 notification layout

Transaction completion is a single replacing line in the shop greeting area, above its purchase/sale list. Aquarium feedback uses its interior footer. Closing a shop exposes only the signed currency delta inside the top HUD for the remaining 1.5-second lifetime. No popup covers the village expedition strip. Insufficient funds remains in purchase confirmation, and shop-local generic errors use the inline band.

Fishing completion reuses the existing expedition progress strip below the owner gauge, rather than drawing a second overlay on top of it. Menu/settings/collection/guide/mail and transitions suppress the strip. Existing six-second lifetime and reward/claim logic are unchanged.

New behavioral checks cover exact purchase amounts, double-confirm safety, expiry, inline bounds, owner-gauge non-overlap, modal suppression, and unchanged expedition state. Rendered 270×480 and 270×660. Full suite and publication checks in progress.
