# EarthOnlineGuide implementation sync

## v2 同步（2026-08-25）

- 工程已经创建；既有 Build、15/15 测试和专用模拟器流程已记录，但本轮必须为领域、SwiftData、UI 三层分别重取证据。
- V2 将以 `planKey = installID + businessDaySequence`、05:00 日历边界、原子完整计划、30 日 canonical 冷却和可审计软撤销为真值。`businessDayKey` 不再承担唯一性。
- Settings 无“删除所有数据”；卸载删除本机数据。LocalProfile 丢失而历史存在、或数据库损坏，均进入恢复界面，绝不静默清库/重绑。
- 正常测试版目标是本地内置任务包；Debug `SeedPack` 只能给自动化 fixture。字体下载/二进制、嵌入、OFL、SHA 和视觉验收，以及音频播放、真机、发布仍为 BLOCKED/UNKNOWN。

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
