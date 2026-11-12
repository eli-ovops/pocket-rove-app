# Option A Clean simulator post-Mac-restart health probe — 2026-08-25

- Device: `EarthOnlineGuide iPhone Clean` (`7DDC2A41-46E2-4F2A-BC2C-A97C1F6819CA`)
- Runtime: `iOS 26.5 (26.5 - 23F77)` / `com.apple.CoreSimulator.SimRuntime.iOS-26-5`
- Authorization: post-restart single health probe only. No new device, erase, reset, delete, rename, permission repair, media-library repair, test, or cleanup is included.
- Preflight: no other `xcodebuild`, `xctest`, `testmanagerd`, or `simctl` test activity; 22 GiB free disk.

## Command and raw terminal result

```text
xcrun simctl boot 7DDC2A41-46E2-4F2A-BC2C-A97C1F6819CA
xcrun simctl bootstatus 7DDC2A41-46E2-4F2A-BC2C-A97C1F6819CA -b

Monitoring boot status for EarthOnlineGuide iPhone Clean (7DDC2A41-46E2-4F2A-BC2C-A97C1F6819CA).
[2026-08-25 07:27:04 +0000] Status=1, isTerminal=NO, Elapsed=00:02.
	Waiting on BackBoard

[2026-08-25 07:27:05 +0000] Status=3, isTerminal=YES, Elapsed=00:03.
	Data Migration Failed
```

## Final read-only state

- Checked at `2026-08-25T07:27:15Z`.
- `simctl list` reported the device as `Booted`, but the health gate above had already reached terminal `Data Migration Failed`.
- No `xcodebuild`, `xctest`, or `testmanagerd` activity was present.

Result: **FAIL**. The terminal migration failure is preserved as the blocking original error. Per the stop condition, no tests, screenshots, cleanup, device mutation, or further boot retry followed.
