# iOS Production Progress

Last updated: 2026-09-22

| Item | Value |
|---|---|
| Current | **P08 — Settings and Budget** |
| Status | **BUILT — awaiting device confirmation** |
| Prior | **P05B PASS** (`wall_multi_v7` on `main` @ 98291b0) · **P07 PASS** |
| Closer | Wall-only. Usage threshold OFF. Unique end minutes. No burst-close. |

## P05B (settled 2026-09-22)

- `code=wall_multi_v7` / `monitor_code=wall_multi_v7`
- Wall = `max(60, window)`; 15s debug is a **60s** wall
- Per-app DeviceActivity names; leftover session N cannot wipe session N+1
- Same hour:minute slots drop sibling `intervalDidEnd` → **uniquedEndDate** queues ~1 min
- Host catch-up only if Attention is foreground
- Force-quit trials (1/3/5 min, 2–3 apps) close on cadence
- `wall_burst_v1` rejected: Snap+TikTok closed, Instagram never reshielded
- Trials: `Journal-Context/trial_results.md`

## P08

Settings tab: default window (applies to all tracked apps), global Continue budget, Pause Attention (confirm). Home shows Continues remaining. Budget does not lock Continue.

## Decisions recorded

- Continue budget: **global**
- Window default: **editable mid-day** from Settings
- Pause Attention: **yes**, with confirmation
- Closer: **wall-only + unique end minutes** (not usage threshold, not burst-close)

## Next

Human device checklist for P08, then P09 (onboarding + yank/notification honesty).
