# EarthOnlineGuide implementation sync

Authority copies in this project mirror the approved PRD, technical architecture, risk register, task-source document and P0 manifest from the designated source paths.

## Current authorization delta

- Old promise: MVP had no audio. New promise: independent music and sound-effect preferences are implemented as local preferences; publication remains **BLOCKED** because no audio asset, licence or playback evidence exists.
- Refresh business semantics remain device-local 05:00; user-visible copy is `5:00 AM`.
- The local guide ID is single-install only. Editing it never changes the SwiftData-only install ID.
- History and Settings visual authorities are `history-page-visual-v8.png` and `settings-page-visual-v7.png`; their source mockups are not shipped production screens.
- No production 166-core/56-egg pack is claimed. The app uses a small safe development-only seed pack until source validation, safety review, stable identity, licence and English release status are complete.

## Explicit gaps

- Pixel font: no licensed bilingual production font selected or embedded; Dynamic Type system-font fallback is active.
- Audio: blocked as above.
- Real-device notification, DST/time-zone behavior and user outcome evidence: UNKNOWN.
