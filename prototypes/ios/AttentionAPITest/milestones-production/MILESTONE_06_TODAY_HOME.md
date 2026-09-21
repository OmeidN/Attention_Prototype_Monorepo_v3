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

- [ ] Never Mind → Home increments intentional choices after reopen/ingest
- [ ] Continue + window end → windows / minutes update
- [ ] Force-quit during day → counts still correct after relaunch
- [ ] Labels show, not raw UUIDs only
- [ ] Record in `PRODUCTION_RESULTS.md`

## Definition of done

- [ ] Today home reflects real shield actions
- [ ] Honest naming verified by human
- [ ] Human confirmed

**Next:** [P07 — Goals, XP, Streaks](./MILESTONE_07_GOALS_XP_STREAKS.md)
