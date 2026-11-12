# Task 4 local TaskPack content gate — 2026-08-25

Status: **BLOCKED — approved capacity 0 core / 0 egg**.

## Completed mechanical conversion

- Source: `Planning/EarthOnlineGuide-App-TaskCatalog-Source-v0.md`.
- Formal local JSON: `EarthOnlineGuide/Resources/TaskPacks/earth-online-guide-source-v1.json`.
- It preserves all 166 core source memberships and 56 egg source memberships as 218 canonical records.
- Four cross-category source duplicates use one canonical record each: `shared-001` through `shared-004`, each with `eligibleTypes = ["core", "egg"]` and both source-member lists.
- Normal App startup no longer invokes the five-card `SeedPack`; that fixture remains in tests only.

## Safety and release posture

All converted source records remain exactly non-active:

| Field | Value |
|---|---|
| `contentStatus` | `reviewing` |
| `safetyStatus` | `pending` |
| `localizationStatus` | `zh-ready` |
| `licenseStatus` | `pending` |
| English text | intentionally empty; release blocked |

No source item was self-approved, translated, relicensed, or introduced into an active SwiftData pack.

## Validator and parse evidence

- `LocalTaskPackCatalog.swift` provides Codable parsing and checks for pack identity, required fields, canonical/revision rebindings, `eligibleTypes`/source-membership consistency, resource keys, release localization, deterministic input fingerprint, and approved capacity.
- A host-only verifier parsed the shipped JSON and observed:

```text
TASKPACK_PARSE_PASS records=218 coreMemberships=166 eggMemberships=56 shared=4 approvedCore=0 approvedEgg=0
```

- The validator correctly reports `insufficientApprovedCapacity(core: 0, egg: 0)` against the required 93 approved core / 31 approved egg threshold.

## Stop condition

The 93/31 active-content hard gate is not met. TaskPack import into normal runtime, task selection on this source, Task 5 task-driven visual implementation, simulator test execution, and release claims remain blocked. A content review with explicit safety, license, and localization decisions is required before further implementation.
