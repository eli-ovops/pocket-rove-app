# Task 6 — Canvas scoped PASS and Settings Toggle diagnosis — 2026-08-25

## Status separation

| Scope | Result | Evidence | Boundary |
| --- | --- | --- | --- |
| Canvas / TaskRow | **scoped PASS** | `taskrow-layout-green-b.xcresult` | In the formal workflow, the standard-size card-frame checks, non-overlap checks, real `element.tap()`, completed state, and History entry all completed before Settings. Canvas remains frozen. |
| Complete UI workflow | **FAIL** | `taskrow-layout-green-b.xcresult` | The later immediate assertion for `settings-music` observed `0`, not `1`. This does not invalidate the Canvas scope. |
| Settings real-control diagnostic | **PASS (1/1)** | `settings-toggle-diagnostic-v1.xcresult` | A direct tap on the inner, actual Switch changed music `0 -> 1`, and the value remained `1` after terminate/relaunch. |

## Confirmed Settings facts

- `SettingsView` uses a direct SwiftUI `Toggle` binding that writes the `LocalProfile` field and immediately calls `modelContext.save()`; it has no `disabled`, `allowsHitTesting(false)`, background, or overlay modifier.
- The identifier `settings-music` resolves to an accessible row proxy: `744 x 52.3pt`, enabled and hittable. Its child is the actual, unnamed `63 x 28pt` Switch at `x=751, y=261`; its center is `(782.5, 275)`.
- The previous full workflow tapped the identifier-bearing proxy. The diagnostic directly tapped the inner Switch. Its value was `0` before, `1` immediately after, and `1` after relaunch. The sound toggle remained `0` as expected.
- A read-only copy of the run-ID-specific store contains exactly one Profile; music is `1`, sound is `0`, and both identity fields are non-empty. SHA-256 hashes of `earth.sqlite`, `-shm`, and `-wal` match before and after copying.

## Single root cause and stop condition

The UI test's selector targets SwiftUI's identifier-bearing Toggle row proxy rather than its nested physical Switch. This causes `XCUIElement.tap()` to hit the row center instead of the knob. Binding, save, and relaunch restoration are confirmed healthy. No coordinate-tap experiment was needed, and no product implementation was changed in this diagnosis.

Do not modify `TaskRow`/Canvas. Await PMO approval for a minimal Settings accessibility/test-semantic repair; do not run full regression, screenshots, or cleanup before that decision.
