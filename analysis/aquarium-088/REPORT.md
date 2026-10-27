# Aquarium redesign v0.88

Approved 2026-10-27: large tank and stacked management/expansion buttons. Plants, light shafts and air bubbles are separate animated drawing layers. The static tank contains only water, rocks, sand and frame. Owned fish remain actual saved specimens; prices, income, transfer rollback and persistence retain their original behavior.

PixelLab management and expansion icons use one generate-ui-v2 request each, with sequential generation and reviewed transparent output. Requests and job IDs are in pixellab/. No secrets are included.

Village exterior renders only owned swimming fish over the original building art. Opaque replacement window polygons, bubble overlays and extension rectangles are removed.

Regression: original fixture-only fish missing weight corrected in regional test; fresh isolated test data used for shop checks. UI guide checks pass with the old overlay renderer removed. Runtime screenshot checks cover 480 and 660 logical-pixel heights.

GitHub publication status is tracked in WORK_STATE.json and release verification records.
