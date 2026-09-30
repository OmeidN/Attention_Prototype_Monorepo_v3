# iOS Production Progress

Last updated: 2026-09-26 (v1 freeze accepted)

| Item | Value |
|---|---|
| Current | **v1 frozen** |
| Status | P00–P13 PASS. Next: `milestones-v1.1/`. |
| Prior | **P13 PASS** · **P12 PASS** · **P11 PASS** |
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

## P12 (PASS 2026-09-26)

Apple granted Family Controls (Distribution) 2026-09-25. App Store Connect listing **Attention Lab** (home screen still Attention). Build **0.1 (3)** uploaded after adding a real App Icon catalog (earlier archives failed ITMS-90022). Human: TestFlight install/open consistent with the Xcode dogfood; shields work. Not App Store approval.

## P13 (PASS 2026-09-26)

Recap vs Home matches. Criteria 2026-09-25: 1 yes; 2 no (Never Mind is a button, not a win); 3 yank accepted as wanted; 4 L0-only on wear (fix in 0.1 (3), re-check is V11-00); 5 yes; 6 yes. **Freeze accepted.**

## Post-freeze watch (TestFlight 0.1 (3))

2026-09-29: TikTok did not reshield long after its window. Apps tab showed `open_windows=[Snap,Tiktok]` but P05B `pending=[Snap]`. TikTok's wall was missing while its open window stayed, so nothing was going to close it. Instagram and Snap closed normally. **Shield all** recovered it; later TikTok Continues reshielded fine. The cause (wall never armed vs. dropped later) is not known. Watching on TestFlight. The closer is not reopened unless it happens again. If it does, capture P05B `Monitor / wall`, P04 `open_windows`, and Dogfood → Copy logs *before* tapping Shield all.

## Next

V11-00 **PASS** 2026-09-30 (L0→L1→L2 on device, no code change).
V11-01 **PASS** 2026-09-30 on TestFlight 0.1 (4): green Never Mind button + win line on the shield, Home win banner, and a Recap line that leads with Never Minds. XP and the closer are unchanged. The human says the UI is still bland, so the win doesn't land visually yet; that goes to V11-02.
Next: V11-02 UI pass. StoreKit and programs are not laid out.
