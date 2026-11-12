# Task 2 XCTest serial recovery run

## Command and target

- Result: `task2-migration-xctest-serial.xcresult` (sealed; `Info.plist` present).
- Destination: EarthOnlineGuide iPhone Recovery, `A84C57F4-4D07-4F30-AB79-2D9CFE56EF24`, iOS Simulator 26.5 / build 23F77.
- Scope: only `Task2MigrationXCTests.testMigrationFailureDoesNotReplaceOriginalStore` and `Task2MigrationXCTests.testV1DiskStoreMigratesProfilePlanSnapshotAndRevocationIdempotently`.
- Serial controls: `-parallel-testing-enabled NO`, one parallel worker, one concurrent simulator destination, and `-collect-test-diagnostics never`.

## Actual result

`xcresulttool get test-results summary` reported `totalTestCount=2`, `passedTests=1`, `failedTests=1`, `skippedTests=0`, `result=Failed`.

- PASS: `testMigrationFailureDoesNotReplaceOriginalStore()`.
- FAIL: `testV1DiskStoreMigratesProfilePlanSnapshotAndRevocationIdempotently()`.

The failure is a real V1 disk-store migration failure, not discovery or an in-memory substitute. Core Data reported `NSCocoaErrorDomain Code=134110`: `Cannot migrate store in-place: Validation error missing attribute values on mandatory destination attribute`; underlying entity/attribute: `Completion.lastMutationID`. The test then received `SwiftDataError...loadIssueModelContainer` at `EarthOnlineGuideTests.swift:146` while opening the V2 disk container.

`EarthOnlineSchemaV2.Completion` currently adds non-optional `updatedAtUTC` and `lastMutationID`, while the V1 `Completion` has neither. The migration plan's `didMigrate` assigns both only after the store has opened, so it cannot repair this pre-mapping validation failure.

## Related retained artifacts

- `task2-migration-xctest-bridge.xcresult` is retained as **ABORTED/HUNG**, unsealed (no `Info.plist`), 161 MiB. See `Task2-XCTestBridge-Hung.md`.
- `task2-migration-xctest-serial.xcresult` is retained as the authoritative executable result, 436 KiB.

No simulator erase/reset/delete, new device, service restart, cleanup, or Git write occurred.
