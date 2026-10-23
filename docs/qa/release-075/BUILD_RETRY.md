# 0.75 release retry

Build39955310111 stopped before publication: all functional assertions passed, but village_entry_audio test exited while audio thread still held four resources. Work CI39954977132 had passed, revealing timing-dependent cleanup. Fixed test to free players synchronously, clear local references, then allow audio thread to retire playback. Six isolated verbose local runs passed with no ERROR/leak messages. No production gameplay code changed. Release remains0.74 until rebuilt and verified.
