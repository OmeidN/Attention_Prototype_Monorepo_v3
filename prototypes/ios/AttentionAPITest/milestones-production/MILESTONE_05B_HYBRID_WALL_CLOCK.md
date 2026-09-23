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
- [ ] Wall-only: 15s or 1 min Settings → Continue → shield returns ~1–2 min (`last_close=wall_clock`, `code=wall_only_v1`, `until_end_s` small)
- [ ] 5 min window → wall ~5–6 min (minute snap)
- [x] Record in PRODUCTION_RESULTS

## Device notes (2026-09-22)

- Arm code `wall_multi_v7`; product wall `max(60, window)`; **per-app** DeviceActivity names so Continue on A does not cancel B.
- `intervalDidEnd` more than 20s before that app's armed `endAt` is ignored (stale callback). It does not re-shield and does not clear the new wall. Legacy single-activity callbacks are ignored.
- v7: leftover `intervalDidEnd` from session N must not wipe session N+1 (coordinated pending-map CAS + live-marker fail-closed). Two walls must not share the same hour:minute slot (`repeats: false` only fires once). Host catch-up closes due walls if DeviceActivity drops the second callback.
- Usage closer OFF (`usageCloserEnabled=false`); leftover usage callbacks ignored.
- Expected: Shield both → Continue A → A unblocked with its wall; B stays shielded until Continue B (own wall). After A reshields, Continue A again → A must reshield on the new wall.

**Next:** P06 Today Home (already shipped) / continue P08+ dogfood
