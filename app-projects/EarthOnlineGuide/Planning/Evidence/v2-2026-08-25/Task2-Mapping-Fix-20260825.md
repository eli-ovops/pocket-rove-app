# Task 2 V1 to V2 mapping compatibility — PASS

- Date: 2026-08-25.
- Result bundle: `task2-migration-mapping-fixed.xcresult`.
- Device: EarthOnlineGuide iPhone Recovery (`A84C57F4-4D07-4F30-AB79-2D9CFE56EF24`), iOS Simulator 26.5 / build 23F77.
- Serial controls: parallel testing disabled, one worker, one simulator destination, diagnostics collection disabled.

`xcresulttool` reports `totalTestCount=2`, `passedTests=2`, `failedTests=0`, `skippedTests=0`, `result=Passed`.

1. `Task2MigrationXCTests.testV1DiskStoreMigratesProfilePlanSnapshotAndRevocationIdempotently()` passed. It opens the V1 SQLite fixture with `EarthOnlineMigrationPlan`, asserts retained profile/plan/snapshot/completion/revocation, derives plan key and business-day sequence from the persisted V1 date and zone, verifies deterministic completion mutation metadata, then reopens the same disk store and verifies idempotence.
2. `Task2MigrationXCTests.testMigrationFailureDoesNotReplaceOriginalStore()` passed. It deliberately opens a malformed disk store, requires failure, and compares the original bytes afterward.

The V2 fields remain non-optional. Their declaration defaults make mapping possible; `didMigrate` replaces them with stable values derived from the persisted completion identity and timestamps. An invalid V1 business day takes a documented UTC / sequence-zero recovery path marked by algorithm version `v2-legacy-recovered-unparseable-business-day`; valid V1 dates derive a zone-aware sequence from 2001-01-01 and the frozen 05:00 refresh boundary.

No data clear/replace, device reset/erase/delete, service restart, Git write, or cleanup occurred. The prior 161 MiB aborted bundle remains retained.
