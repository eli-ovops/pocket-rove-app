# Simulator data-migration diagnosis — 2026-08-25

Status: **BLOCKED — read-only diagnosis only**.

## Evidence ranking

1. **High confidence: Recovery device-local media-analysis migration / permission state.**
   - Recovery (`A84C57F4-4D07-4F30-AB79-2D9CFE56EF24`, iOS 26.5) reached `Waiting on Data Migration` then terminal `Data Migration Failed` after the authorized CoreSimulator service restart.
   - Its runtime log has `mediaanalysisd` errors creating `/var/mobile/Media/MediaAnalysis`: `NSCocoaErrorDomain Code=513` with underlying `NSPOSIXErrorDomain Code=13 Permission denied`.
   - The same log then reports `MA Database migration incomplete` for both `data/Media` and its Syndication photo library.

2. **Medium confidence: this device state, rather than a missing Runtime or globally unavailable CoreSimulator service, gates test launch.**
   - CoreSimulator restarted once and Recovery reproduced the bootstatus terminal condition.
   - Installed runtimes include iOS 17.0, 26.5 and 27.0; Recovery metadata references installed iOS 26.5 and remains non-deleted/non-ephemeral.

3. **Low confidence: host free space is a primary cause.**
   - Host storage had approximately 14 GiB free at diagnosis. This is a risk constraint, but the captured terminal error is permission/migration-specific rather than an out-of-space message.

4. **UNKNOWN: exact durable on-device file or platform defect that created the bad permission state.**
   - No device file, CoreSimulator file, Runtime component, or service configuration was changed or deleted, so the diagnosis does not establish a destructive repair target.

## Comparison boundary

- Original EarthOnlineGuide device (`E110C410-6304-4235-B45A-F1A1200C1A2A`) remains preserved and `Shutdown` on iOS 17.0.
- No corresponding boot attempt was made during this read-only diagnostic pass, so an exact original-vs-Recovery error-pattern comparison is **UNKNOWN**.

## Minimal recovery options requiring new explicit authorization

1. A user-approved, precisely scoped repair of the Recovery device's affected media-analysis data; this is destructive to part of its simulator data and was not attempted.
2. User-approved erase/reset of the existing Recovery device; prohibited without a separate concrete authorization and would destroy its simulator data.
3. User-approved Runtime repair/reinstall; this changes system state and was not attempted.

Creating another device, automatic cleanup, and retrying test execution are not proposed under the existing constraints.
