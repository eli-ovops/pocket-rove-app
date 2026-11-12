# Validation status — 2026-08-24

## Fresh evidence

- App simulator build: `BUILD SUCCEEDED` at 20:27 Asia/Shanghai.
- Test bundle compilation: `TEST BUILD SUCCEEDED` at 20:32 Asia/Shanghai.
- Test execution: **UNKNOWN**. The completed first result bundle is `/Users/USER/Library/Developer/Xcode/DerivedData/EarthOnlineGuide-gamngckyrgdikefhldmlwnjtiivd/Logs/Test/Test-EarthOnlineGuide-2026.08.24_20-19-39-+0800.xcresult`; `xcresulttool` reports `result: unknown`, `totalTestCount: 0`.

## Isolated simulator blocker

- UDID `DB4BBBEF-D80B-4A37-9204-55793CA8DB5B` reports Booted but `simctl bootstatus -b` did not return after 30 seconds.
- Simulator screenshot remained black.
- A separate DisciplinedPet task owns a live `simctl diagnose` process against the same UDID. This project did not stop, reset, erase, or otherwise mutate that shared simulator.

## Independent-device retry

- 20:43 Asia/Shanghai: iPhone Air, iOS 26.5, `510307E0-648E-4A0B-B476-64A572758716` completed `bootstatus -b` in 8 seconds with terminal `Data Migration Failed`.
- 20:44 Asia/Shanghai: iPhone 17e, iOS 27.0, `6C81CF3F-64A7-498A-ABE2-B054799CAAC9` remained `Booting` after a 60-second bounded wait. The task stopped only its own boot-status process.
- No simulator was erased, reset, shut down, or otherwise modified. Two independent available devices produced the same category of simulator-startup failure, so **local Simulator infrastructure is BLOCKED** for this validation pass.

## Consequence

No unit-test result, UI test result, or manual simulator core-flow acceptance is claimed. The next attempt must begin only after local Simulator infrastructure becomes healthy; it must re-run tests before any PASS statement.

## Recovery evidence — 2026-08-25

- Created the dedicated simulator `EarthOnlineGuide iPhone` (`E110C410-6304-4235-B45A-F1A1200C1A2A`), iPhone 15 Pro / iOS 17.0. It booted in 17 seconds on first creation. No existing simulator was erased, reset, deleted, cloned, or modified.
- CoreSimulator was **not restarted**: a separate active `DisciplinedPet` `xcodebuild test` process was bound to the shared iPhone 17 Pro, so the authorization precondition for a service restart was not met.
- Real `xcodebuild test` execution on the dedicated device passed **15/15** tests after fixing the 05:00 business-day key and SwiftData cross-context relationship handling. The runner emits the non-fatal local warning `DebuggerLLDB.DebuggerVersionStore.StoreError error 0` before launching, but produced actual per-test PASS output and exit code 0.
- Manual simulator flow passed: first ID setup -> Today -> complete one task -> History displays it -> revoke in Today -> History displays `暂无完成记录` -> Settings switches English, Music and Sound Effects to enabled. A terminate/relaunch retained the guide ID, English, and both preferences; the existing daily plan stayed frozen while its task text changed language.
- Logic evidence: 05:00 UTC edge case and language-independent seed pass in the real test suite; the new SwiftData test verifies a plan/profile relationship and completion created across contexts. DST/time-zone-change, system-clock rollback, and long-offline E2E remain **UNKNOWN**. Notification identifiers `earth-guide-0900` / `earth-guide-2000` are covered by a real logic test; OS permission delivery and true-device notification behavior remain **UNKNOWN**.
- Disk hygiene observation only: project 8.6 MB; its DerivedData 242 MB. No DerivedData, simulator data, cache, or user file was deleted.
