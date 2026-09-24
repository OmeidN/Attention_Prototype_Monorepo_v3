# iOS Production Progress

Last updated: 2026-09-23

| Item | Value |
|---|---|
| Current | **P13 — Recap and v1 freeze** |
| Status | **BUILT — awaiting device confirmation** (freeze draft, not accepted) |
| Prior | **P11 PASS** · **P10 PASS** · **P05B PASS** (`wall_multi_v7`) |
| Closer | Wall-only. Usage threshold OFF as a closer. Unique end minutes. No burst-close. |

## P05B (settled 2026-09-22)

- `code=wall_multi_v7` / `monitor_code=wall_multi_v7`
- Wall = `max(60, window)`; 15s debug is a **60s** wall
- Per-app DeviceActivity names; leftover session N cannot wipe session N+1
- Same hour:minute slots drop sibling `intervalDidEnd` → **uniquedEndDate** queues ~1 min
- Host catch-up only if Attention is foreground
- Force-quit trials (1/3/5 min, 2–3 apps) close on cadence
- `wall_burst_v1` rejected: Snap+TikTok closed, Instagram never reshielded
- Trials: `Journal-Context/trial_results.md`

## P08 (PASS 2026-09-23)

Settings tab: global default window (applies preferred + all tracked apps; next Continue uses it), global Continue budget, Pause Attention (confirm). Home shows Continues remaining. Budget does not lock Continue. Per-app pickers remain on Apps.

## P09 (PASS 2026-09-23)

First launch: why → Screen Time auth → pick/name → notification honesty (checkbox required) → window + global budget → apply shields or skip with warning. Second launch skips when the flag is set. Settings can replay tips or reset the first-launch flag.

## Decisions recorded

- Continue budget: **global**
- Window default: **editable mid-day** from Settings
- Pause Attention: **yes**, with confirmation
- Closer: **wall-only + unique end minutes** (not usage threshold, not burst-close)
- Usage checkpoint: **optional side signal** (P10). Not a closer. Not an open.

## P10 (PASS 2026-09-23)

Optional duration checkpoint. Two tracked apps each showed a new timestamp after ~1 min of use. Toggle off: another minute did not add a checkpoint; the last timestamp stayed. Not a closer. Not an open or a session.

## P11 (PASS 2026-09-23)

Stress matrix pass (force-quit, reboot, lock, rapid reopen, switcher, notifications, airplane, date rollover, revoke auth). All-day wear was not run; human accepted and moved on. Date jump: window time on the fake day showed ~1330 min, then ~3 min after the date was restored. Left alone.

## P12 (Assigned 2026-09-23)

Family Controls (Distribution) submitted for host, ShieldConfiguration, ShieldAction, DeviceActivityMonitor, and DeviceActivityReport. Wildcard skipped. Portal status **Assigned**. Not Approved. Archive and TestFlight not run. Phone installs still use the development entitlement.

## P13 (built 2026-09-23, awaiting device)

Recap tab: today totals plus last 7 days from the local event log. One rules-based sentence. No AI. No open counts. Scope freeze draft: `docs/V1_SCOPE_FREEZE.md`. Not accepted until the human confirms Recap and the six criteria.

## Next

Human checks Recap against a lived day and accepts or rejects the freeze. P12 stays Assigned until Apple approves; then archive. Do not start v1.1 until the freeze is accepted.
