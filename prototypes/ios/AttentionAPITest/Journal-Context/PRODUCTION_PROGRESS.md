# iOS Production Progress

Last updated: 2026-09-21

| Item | Value |
|---|---|
| Current | **P06 — Today Home** (not started) |
| Status | **P05A + P05B PASS** — waiting for human OK to start P06 |
| Prior | Hybrid closer confirmed on device |

## Closer (shipped)

- **Usage:** DeviceActivity threshold ≈ per-app window; may yank; Attention may be quit.
- **Wall backup:** product map `15s→60s`, else `window+60s`. DeviceActivity needs ≥15m schedule span → past-pad start (`pad15m_v2`); fire time is **minute-aligned + ~1m buffer** (leave-early often ~2–2.5 min on 15s debug — not a precise 60s stopwatch).
- **Continue stickiness:** mitigated with `includesPastActivity=false` + premature-threshold grace; Shield All clears pending wall.

## Next

**P06 — Today Home** (ingest App Group events → honest Today metrics). Wait for human OK before implementing.
