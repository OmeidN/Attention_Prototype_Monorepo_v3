# P05B — Hybrid Wall-Clock Close

**Goal:** re-shield even if the user leaves the app before usage threshold accumulates. Hybrid closer: **usage threshold OR wall-clock**, whichever comes first. Wall duration = usage window **+ 1 minute** (e.g. 1 min use → 2 min wall, 5 → 6).

**User-visible change:** Apps tab shows usage vs wall mapping. Leave-before-window-end still closes the door on wall clock without opening Attention.

**Prerequisite:** P05A (hard usage threshold) working on device.

**Agent rule:** this milestone only. Honest copy: wall is real-time backup; usage may yank sooner.

## Steps

1. `wallSeconds`: **15s debug → 60s wall**; otherwise `usageWindowSeconds + 60` (1→2, 5→6 min). Apple requires DeviceActivity schedule span ≥ **15 minutes** (`intervalTooShort` otherwise) — pad `intervalStart` into the past so `intervalDidEnd` still lands at now+wall.
2. On Continue: keep usage re-arm; also start a one-shot DeviceActivity schedule now→now+wall; store pending app id in App Group.
3. Monitor `intervalDidEnd` for wall activity → extension re-shields that app (Attention may be dead; user need not be in the app).
4. Whichever fires first wins; second is no-op if already shielded.
5. Tag `ATTN-P05B`.

## Physical-device checklist

- [x] 15s debug: Continue → leave immediately → shield returns ~2–2.5 min (minute-aligned wall; not exact 60s) without needing tracked app or Attention open — human 2026-09-21
- [x] Stay in app: usage threshold still yanks — human 2026-09-21
- [ ] 5 min window → wall ~6 min leave-early path (not required for PASS; optional later dogfood)
- [x] Record in PRODUCTION_RESULTS

## Device notes (2026-09-21)

- Apple `intervalTooShort` if schedule span &lt; 15 minutes → past-pad `intervalStart`.
- Arm code `pad15m_v2`; product wall still mapped 15s→60s / else window+60s.
- Immediate post-Continue reshield mitigated in P05A path (`includesPastActivity=false` + grace); Shield All clears pending wall.

**Next:** P06 Today Home
