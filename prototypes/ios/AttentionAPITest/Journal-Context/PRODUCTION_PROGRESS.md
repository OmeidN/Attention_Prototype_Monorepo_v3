# iOS Production Progress

Last updated: 2026-09-25 (Recap wear)

| Item | Value |
|---|---|
| Current | **v1 close-out pending** |
| Status | Waiting on Recap wear + freeze accept. P12: distribution granted; archive done; TestFlight not run. |
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

## P12 (close-out pending)

Apple email 2026-09-25: Family Controls (Distribution) assigned to the account. Human archived. **TestFlight not run.** Phone dogfood can stay on the current install. Not marked PASS until TestFlight is recorded or the human accepts skip.

## P13 (close-out pending — criteria in)

Recap vs Home matches. Criteria 2026-09-25: 1 yes; 2 no (Never Mind is a button, not a win); 3 yank accepted as wanted; 4 L0-only after 2 Continues (fix built, not re-checked); 5 yes; 6 yes. Freeze not accepted.

## Next (do these before v1.1)

1. Reinstall this build. After 1–2 Continues on one app, next shield should be L1 (“already today”), after 3+ L2 (“Continue anyway”).
2. Accept or reject `docs/V1_SCOPE_FREEZE.md` (yank is intended; Never Mind win is a later copy/UX job).
3. Record P12 TestFlight skip or smoke.
4. Only then: `milestones-v1.1/`. Do not implement Pro / StoreKit / Family / credits yet.
