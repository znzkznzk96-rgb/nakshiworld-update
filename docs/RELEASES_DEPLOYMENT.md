# GitHub Releases automatic updates

The installed Android 0.60 bootstrap continues using https://nakshiworld-update-kr.znzkznzk96.workers.dev/. The deployed Worker streams published GitHub Release assets. No new APK or R2 credentials are required for game-content patches.

## Publish the next version

Maintain source under game/. Increment both code and name in automation/release.json (for example code 62, name 0.62). Push changes to main. GitHub Actions recovers original assets from the SHA-256-pinned 0.57 PCK, overlays source, imports Godot resources, runs equipment/save/lesson checks and exports a PCK. It calculates SHA-256 and size, uploads patch.pck, version.json and game-source.zip into a draft release, then publishes it last. The default GITHUB_TOKEN is used with contents:write; no personal token or signing key is needed.

Unchanged source can reuse an existing published version on merge. A changed source must increment the version. Do not replace published assets; create a new release.

The gateway exposes only GET/HEAD/OPTIONS, checks manifest format, rejects mismatched requested version, streams patch responses and disables caching at the fixed update URLs. Android independently verifies size, SHA-256 and pack magic before applying. Other R2 files such as test.txt remain accessible via the original binding. If updates fail, the app continues using its existing local content.

The source ZIP in each Release is a complete recovered Godot project without signing credentials. The repository game/ directory contains maintained script overrides rather than the original large asset tree.

Known scope: this pipeline publishes PCK content patches, not Android native binary or engine changes. Validate gameplay on Android after each release. Gateway end-to-end checks are recorded in the Verify deployed update gateway workflow.
