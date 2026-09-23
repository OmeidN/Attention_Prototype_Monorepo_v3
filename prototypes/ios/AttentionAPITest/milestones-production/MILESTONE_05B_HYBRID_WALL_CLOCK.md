# P05B — Wall-Clock Close (usage off)

**Goal:** re-shield on wall-clock after Continue. **In-app usage threshold is disabled** (DeviceActivity usage was losing to wall / false-fire rearms). Wall duration = `max(60, window)` seconds (15s + 1 min → **60s**; 5 min → 5 min).

**User-visible change:** Apps tab shows wall-only mapping. Stay or leave — door closes on wall (~minute-aligned).

**Prerequisite:** P05A proven historically; current closer is wall-only.

**Agent rule:** honest copy — wall is approximate (minute snap), not a stopwatch.

## Steps

1. `wallSeconds`: **`max(60, window)`** — 15s/1min → 60s; longer → window length. Apple requires schedule span ≥ **15 minutes** — past-pad `intervalStart`.
2. On Continue: **do not** arm usage events; start one-shot wall schedule; store pending app id in App Group.
3. Monitor `intervalDidEnd` for wall activity → extension re-shields.
4. Tag `ATTN-P05B` / `wall_only_v1`.

## Physical-device checklist

- [x] 15s debug leave-early wall (historical hybrid PASS) — human 2026-09-21
- [x] Wall-only 15s debug / 1 min → shield returns ~1–2 min (`last_close=wall_clock` or host catch-up; `code=wall_multi_v7`) — human 2026-09-22
- [x] 3 min / 5 min windows → wall ≈ window + minute snap — human 2026-09-22 (IG 3, TikTok 5)
- [x] Force-quit Attention → walls still close — human 2026-09-22 trials 3–5
- [x] Record in PRODUCTION_RESULTS

## Device notes (2026-09-22) — current: `wall_multi_v7` on `main` @ 98291b0

- Arm code `wall_multi_v7`; product wall `max(60, window)`; **per-app** DeviceActivity names so Continue on A does not cancel B.
- `intervalDidEnd` more than 20s before that app's armed `endAt` is ignored (stale callback). It does not re-shield and does not clear the new wall. Legacy single-activity callbacks are ignored.
- Leftover `intervalDidEnd` from session N must not wipe session N+1 (coordinated pending-map CAS + live-marker fail-closed).
- **Unique end minutes:** two walls must not share the same hour:minute slot (`repeats: false` only fires once). Same-length Continues in the same minute queue ~1 min apart (`uniquedEndDate`). Honest copy: wall is minute-snapped, not a stopwatch.
- Host catch-up closes due walls if DeviceActivity drops a callback (Attention foreground only).
- Usage closer OFF (`usageCloserEnabled=false`); leftover usage callbacks ignored.
- **Rejected (2026-09-22):** `wall_burst_v1` — drop uniquing and close a 30s Continue-all burst from the first callback. Snap + TikTok closed; Instagram never reshielded (same-slot `intervalDidEnd` drop, burst did not cover it). Reverted to `main`.
- Expected: Shield both → Continue A → A unblocked with its wall; B stays shielded until Continue B (own wall). After A reshields, Continue A again → A must reshield on the new wall.

**Next:** P08 Settings/Budget device confirm, then P09+ dogfood
