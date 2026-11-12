# Task 6 test inventory — static preparation

## Execution status

All newly prepared XCTest/UI XCTest methods are **not run**: the only Recovery simulator is blocked by preserved Data Migration failure. `build-for-testing` compiles targets but executes zero tests. Historical Task 2 evidence remains 2/2; the host JSON verifier is separately executable.

## Expected targets and entry points

| Target | Expected methods | Static status | Runtime status |
|---|---:|---|---|
| EarthOnlineGuideTests / Swift Testing | 15 current entries: deterministic seed, egg decision, 05:00, pool shortage, test-host storage, UI run-ID path isolation, pack rules, SwiftData plan, task identity, Task 2 migration/failed-store, legacy day recovery | compiled | blocked / 0 this phase |
| EarthOnlineGuideTests / XCTest | 18 current entries: 2 Task 2 authority tests; 5 TaskPack contract tests; DST; monotonic rollback; pool shortage; cooldown day 31; completion/revoke idempotency; timezone; plus fixture helpers | compiled | blocked / 0 this phase |
| EarthOnlineGuideUITests | 1 workflow: reset run-ID Store → first ID → Today → completion → History → preferences → terminate/launch persistence → undo → second terminate/launch | compiled | blocked / 0 this phase |
| EarthOnlineGuideUITestsLaunchTests | 1 launch test | compiled | blocked / 0 this phase |

## Required execution once a healthy simulator is available

1. Run the two named Task 2 authority XCTest methods and retain an xcresult with 2 passed / 0 failed / 0 skipped.
2. Run the full unit target. Confirm 05:00, DST, timezone change, rollback, long absence, deterministic selection, 25% egg distribution, insufficient pool, 30/31-day cooldown, incomplete return, idempotency, same-day undo, cross-day rejection, temporary-disk migration, reopen, failed-store preservation, plan atomicity, restart, pack upgrade, and effective-completion history.
3. Run the UI workflow using an isolated temporary store and fixed clock/install ID/pack with animations disabled; retain Chinese/English onboarding, Today, History, empty history, Settings, and large-type screenshots.
4. Verify notification scheduling independently: opt-in request, denied no-block, stable 09:00/20:00 replacement, and tap navigates only to Today.

## Static readiness

- `UI_TESTING` with an allowed run ID is the only route to a run-ID-specific temporary disk Store. Reset is only eligible when `UI_TEST_RESET=1`; it deletes that exact test directory after a test-root containment check.
- UI mode injects fixed Gregorian/UTC time, fixed install ID, formal parsed TaskPack, and disables animations. Normal startup does not use these values.
- NotificationService is dependency-injected; XCTest Fake coverage exercises request gating, denied behavior, replacement, cancellation, and Today-only routing.
- All entries remain unexecuted until a healthy Simulator exists; static READY does not imply runtime PASS.
