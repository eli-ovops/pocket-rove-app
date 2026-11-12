# Task 4–5 integration evidence — 2026-08-25

## Content audit

- Source: `EarthOnlineGuide/Resources/TaskPacks/earth-online-guide-source-v1.json`
- Ledger: `Task4-Content-Audit-20260825.json`
- 218 canonical records were individually recorded. The four cross-category records are each one canonical record with both eligible types.
- Development Chinese capacity: core `124 approved / 39 reviewing / 3 blocked`; egg `39 approved / 11 reviewing / 6 blocked`.
- Gate: `124 >= 93` core and `39 >= 31` egg — PASS for development Chinese only.
- User-owned task prose is `verified-user-owned`; third-party asset, font, music, and template rights were not inferred.
- English remains pending; `releaseStatus` is `blocked-en-pending`.

## Runtime integration

- `ProductionTaskPackBootstrap` validates the complete source document then imports only approved members into a non-development SwiftData `TaskPack`.
- The normal app no longer seeds `debug-safe-v1`. `DailyTaskService` excludes development packs unless an explicit test-only initializer flag is supplied.
- Cross-category canonical records become exactly one core and one egg runtime card with separate stable revisions; the runtime validator rejects other rebinding patterns.

## Frozen visual boundary

- Only manifest PASS assets are referenced: Earth mark, core/egg card frames, generic 4x2 icon atlas, and core/egg badges.
- History uses current-design semantics: current date, all/core/egg filter, valid completions only, one generic icon and one type badge per row, and numeric date/time.
- Settings uses the Earth mark, one Guide ID, notification state, music and sound preference toggles, static `5:00 AM`, language, and About; it has no clear-data, standalone privacy, or agreement route.
- `FontToken` embeds no font binary and deliberately uses Dynamic-Type-safe system fallback. Music and sound toggles store future preference only; no audio asset or playback was added.

## Evidence boundaries

- `taskpack-audit-verifier` passed against the actual JSON: 218 records, 124 approved core memberships, 39 approved egg memberships, 4 shared.
- `task4-content-active-build.xcresult` and `task5-visual-static-build.xcresult` are build-for-testing evidence only, not test execution or simulator acceptance.
- Simulator execution remains BLOCKED by the preserved Recovery device Data Migration failure. No simulator command was executed during this task.
