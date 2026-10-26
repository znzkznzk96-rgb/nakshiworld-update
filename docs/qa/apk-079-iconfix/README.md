# APK 0.79 ICONFIX

The prior 0.79 APK accidentally reused the Android shell from 0.73 before its icon correction. All 24 mipmap PNG resources are now restored byte-for-byte from the approved 0.73_ICONFIX teal puffer set. All 1,890 game asset entries and every non-icon, non-signature ZIP entry are unchanged; the existing Android certificate is identical. Android device installation remains unverified.

Deliverable: NAKSHIWORLD_0.79_ICONFIX.apk, Library libfile_62810253ff488191b43dd5cb9a8b3cf7. Supersedes the previous 0.79 APK for installation; game/source remain 0.79.

The approved resources are versioned at automation/approved-puffer-icons.zip. automation/repack_apk.py now always applies them and fails if the Android icon inventory or any approved SHA256 differs. The updated packer was executed against the old-icon 0.79 shell and reported 24/24 verified. No private signing material or access metadata is stored here.
