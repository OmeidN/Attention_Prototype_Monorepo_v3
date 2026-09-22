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

- Arm code `wall_only_v1`; product wall `max(60, window)`.
- Near local midnight: clamp start to start-of-today; reject far `nextInterval`.
- Usage closer OFF (`usageCloserEnabled=false`); leftover usage callbacks ignored.

**Next:** P06 Today Home (already shipped) / continue P08+ dogfood
