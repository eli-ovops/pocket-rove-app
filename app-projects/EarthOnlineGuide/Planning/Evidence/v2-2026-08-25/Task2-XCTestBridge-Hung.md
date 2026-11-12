# Task 2 XCTest bridge — aborted hung run

- Observed: 2026-08-25 14:11 Asia/Shanghai.
- Result bundle: `task2-migration-xctest-bridge.xcresult`; it was unsealed (no `Info.plist`) and therefore cannot be read by `xcresulttool` or treated as a test result. Its size at observation was 161 MiB.
- Main process: PID 2650, started 14:04:22, parent PID 1151 (the active Codex app-server), exact command restricted to the two `Task2MigrationXCTests` methods and this result-bundle path.
- Direct child: PID 3136, started 14:05:01, `simctl diagnose --timeout=600`, with output under this bundle's `Staging/1_Test/Diagnostics/simctl_diagnostics` directory.
- Test clone: `CD69237D-39A2-4F2C-AA8D-03AE073E5DE6`, created at 14:04:40 under `~/Library/Developer/XCTestDevices`; its `testmanagerd` had the same start time. The configured Recovery base device remained present and Shutdown.
- Action authorized by PMO: the task-owned main `xcodebuild` process was sent SIGINT after this evidence capture. No device erase/reset/delete, CoreSimulator restart, or cleanup was performed.
- SIGINT did not make the main process exit within 30 seconds. SIGTERM was then sent to its own process group; the main process exited. Its `simctl diagnose` child had created a separate process group and was reparented to `launchd`, so it was sent its own SIGTERM using the already-recorded task-only command line and output path. No `testmanagerd`, Simulator service, or device process was signalled.

Status: **ABORTED/HUNG** — invalid for Task 2 acceptance; retained in place.
