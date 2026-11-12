# Option A Clean simulator controlled retry — 2026-08-25

- Device: `EarthOnlineGuide iPhone Clean` (`7DDC2A41-46E2-4F2A-BC2C-A97C1F6819CA`)
- Authorization: exactly one controlled retry of this existing Clean device; no additional device, erase, reset, delete, rename, permission repair, or media-library repair.
- Preflight: no other `xcodebuild`, `xctest`, `testmanagerd`, or `simctl diagnose` activity; approximately 13 GiB free disk.

## Command and raw terminal result

```text
xcrun simctl shutdown 7DDC2A41-46E2-4F2A-BC2C-A97C1F6819CA
xcrun simctl boot 7DDC2A41-46E2-4F2A-BC2C-A97C1F6819CA
xcrun simctl bootstatus 7DDC2A41-46E2-4F2A-BC2C-A97C1F6819CA -b

[2026-08-25 07:14:55 +0000] Status=2, isTerminal=NO
Waiting on Data Migration

[2026-08-25 07:14:56 +0000] Status=3, isTerminal=YES
Data Migration Failed
```

Result: FAIL. This is the authorized one-and-only retry; no test execution, further boot attempt, new device, or cleanup followed.
