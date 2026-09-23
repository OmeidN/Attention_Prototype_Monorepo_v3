# P06 — Today Home

**Goal:** host ingests App Group events into a local store and shows an honest **Today** home: intentional choices, Continues, access windows, window minutes. No open/session claims.

**User-visible change:** Home tab with today’s counts, tracked-app list (labels), shielding status, and recent events. Ugly/clear is fine.

**Prerequisite:** P03–P05 (events + windows + counts flowing).

**Agent rule:** implement this milestone only. XP/streaks/goals UI is **P07** (you may show raw counts only here). Do not embed DeviceActivityReport as product truth.

## Out of scope

- XP, streaks, goal completion chrome → **P07**
- Full onboarding → **P09**
- Weekly recap → **P13**

## Context

Design plan: scoring and home reinforce the shield loop using **logged events**, not Screen Time opens. Ingest on launch / scene active.

## Steps for the agent

1. Local store (SwiftData or equivalent) for events: `intentional_choice`, `continue`, `access_window_start`, `access_window_end` (+ optional reshield debug).
2. On appear/active: read App Group append-only queue → ingest → mark consumed / compact safely.
3. Today home widgets: Never Minds, Continues, Windows, Window minutes (from start/end pairs). Per-app breakdown by UUID/label.
4. Copy audit: no “opens”, “launches”, or “sessions” as validated metrics.
5. Empty states: no tracked apps → CTA to Setup; auth lost → CTA to re-authorize.
6. Tag `ATTN-P06`. Keep a simple Logs/export for dogfood.

## Agent exit checks

- [x] Build succeeds
- [x] Grep Home UI strings for `\bopens?\b` / `session` as user-facing metrics → zero inappropriate hits (copy denies opens/sessions)
- [x] No DeviceActivityReport dependency for counts
- [x] Ingest path runs on scene active

## Physical-device checklist (human)

- [x] Never Mind → Home increments intentional choices after reopen/ingest
- [x] Continue + window end → windows / minutes update (yank + leave-early wall)
- [x] Force-quit during day → counts still correct after relaunch
- [x] Labels show, not raw UUIDs only
- [x] Day filter: calendar jump forward → zeros; restore real date → prior totals return
- [x] Record in `PRODUCTION_RESULTS.md`

## Amendment — per-app window bookkeeping (2026-09-22)

Multi-app Continue exposed a metrics bug. Window state lived in single App Group slots
(`window_started_at`, `window_tracked_id`, `window_label`, `window_duration_seconds`), so a second
Continue overwrote the first app's start time, and the ingest dedupe keyed on
`(type, timestamp±2s)` only. Because walls are minute-aligned, two apps usually close in the same
minute — app B's `access_window_end` was swallowed as a duplicate of app A's, losing its minutes.

Now:

- `AccessWindowBridge.openWindowsMapKey` holds a per-app map (`appUUID → OpenWindow`) with each
  window's own start/end/planned duration. `beginWindow` writes it; `markReshielded(trackedAppId:)`
  consumes just that app's entry.
- Close attribution uses `last_reshield_app_id` / `last_reshield_label` / `last_reshield_elapsed_s`
  instead of the latest-Continue slot.
- Ingest dedupe keys on `(type, trackedAppId, timestamp±2s)`.
- `clearWindow` no longer drops open windows (it held the start times wall closes need).
- Manual Shield All / Clear shields / Pause log a real `access_window_end` per open window
  (`closeAllOpenWindows`) instead of leaving stale entries.
- Removed a duplicate `access_window_end` append on the host `on_window_end` path.

## Definition of done

- [x] Today home reflects real shield actions
- [x] Honest naming verified by human
- [x] Human confirmed
- [ ] Per-app window amendment confirmed on device (two apps, same-minute close)

**Next:** [P07 — Goals, XP, Streaks](./MILESTONE_07_GOALS_XP_STREAKS.md)
