# Task 6 test inventory — static preparation

## Execution status

All newly prepared XCTest/UI XCTest methods are **not run**: the only Recovery simulator is blocked by preserved Data Migration failure. `build-for-testing` compiles targets but executes zero tests. Historical Task 2 evidence remains 2/2; the host JSON verifier is separately executable.

## Expected targets and entry points

| Target | Expected methods | Static status | Runtime status |
|---|---:|---|---|
| EarthOnlineGuideTests / Swift Testing | 14 current entries: deterministic seed, egg decision, 05:00, pool shortage, test-host storage, pack rules, SwiftData plan, task identity, Task 2 migration/failed-store, legacy day recovery | compiled | blocked / 0 this phase |
| EarthOnlineGuideTests / XCTest | 18 current entries: 2 Task 2 authority tests; 5 TaskPack contract tests; DST; monotonic rollback; pool shortage; cooldown day 31; completion/revoke idempotency; timezone; plus fixture helpers | compiled | blocked / 0 this phase |
| EarthOnlineGuideUITests | 1 workflow: first ID → Today → completion → History → undo → preferences | compiled | blocked / 0 this phase |
| EarthOnlineGuideUITestsLaunchTests | 1 launch test | compiled | blocked / 0 this phase |

## Required execution once a healthy simulator is available

1. Run the two named Task 2 authority XCTest methods and retain an xcresult with 2 passed / 0 failed / 0 skipped.
2. Run the full unit target. Confirm 05:00, DST, timezone change, rollback, long absence, deterministic selection, 25% egg distribution, insufficient pool, 30/31-day cooldown, incomplete return, idempotency, same-day undo, cross-day rejection, temporary-disk migration, reopen, failed-store preservation, plan atomicity, restart, pack upgrade, and effective-completion history.
3. Run the UI workflow using an isolated temporary store and fixed clock/install ID/pack with animations disabled; retain Chinese/English onboarding, Today, History, empty history, Settings, and large-type screenshots.
4. Verify notification scheduling independently: opt-in request, denied no-block, stable 09:00/20:00 replacement, and tap navigates only to Today.

## Known static gaps, retained as non-PASS

- UI test source has the workflow and stable identifiers, but app-side deterministic clock/install-ID/TaskPack injection and isolated persistent-store launch configuration still need implementation before it can prove restart recovery.
- NotificationService currently couples directly to `UNUserNotificationCenter`; its required opt-in/denied/idempotent behavior has not yet been dependency-injected for deterministic unit execution.
- These are source-readiness gaps, not simulator failures and not pass claims.
