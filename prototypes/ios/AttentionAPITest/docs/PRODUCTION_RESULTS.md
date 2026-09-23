# iOS Production Results (v1)

Track production milestones **P00–P13** here. Do **not** overwrite lab `TEST_RESULTS.md`.

## Environment

- Mac: Apple silicon (M4), local (from lab `DEV_ENVIRONMENT.md` — confirm if changed)
- macOS: 26.6.2 (confirm)
- Xcode: 26.6 (confirm)
- iPhone model: *(human — confirmed P00 on device 2026-09-18)*
- iOS: *(human)*
- Team ID: `VPG6W79282`
- Product bundle id: `com.attention.apitest`
- App Group: `group.com.attention.apitest`
- Boundary decision: **evolved lab project** (keep working signing + App Group for dogfood; optional rename to `com.attention.app` at P12 distribution)
- Display name: `Attention` (`INFOPLIST_KEY_CFBundleDisplayName`)
- Family Controls distribution status: not requested

## Boundary note (P00)

Chose **evolved lab project** over a brand-new `com.attention.app` target so P00 can install on the existing paid-team device profile without re-registering App Groups mid-milestone. Product primary UI is `ProductShellView` (no Experiments tabs). Lab source files remain in the target for now but are not the launch UI.

## Milestone table

| Milestone | Test | Result | Evidence / Notes |
| --------- | ---- | ------ | ---------------- |
| P00 | Product shell + auth | **PASS** | Human confirmed on device 2026-09-18. Product shell, auth, timestamp, identity OK. |
| P01 | Tracked apps UUID + labels | **PASS** | Human confirmed on device 2026-09-18. UUID + labels, add/remove/clear, uncheck reject, re-bind OK. |
| P02 | Shield apply/clear | **PASS** | Human 2026-09-18. Apply/clear OK. Note: app switcher can show stale lab shield snapshot (“variant B”); full open refreshes live config (L0/L1 lab copy until P03). |
| P03 | Shield loop + events | **PASS** | Human 2026-09-19. Product pause copy; Never Mind / Continue OK; force-quit OK. |
| P04 | Access windows + on_window_end | **PASS** | Human 2026-09-19. Window + on_window_end + deferred re-shield OK. |
| P05 | Friction ladder L0–L2 | **PASS** | Human 2026-09-19. L0→L1→L2 trustworthy across rapid cycles + force-quit. |
| P05A | Hard threshold re-shield | **PASS** | Human 2026-09-19–21. Usage yank works with Attention force-quit; Continue re-arms. Immediate false threshold after rearm mitigated (`includesPastActivity=false` + grace). |
| P05B | Wall-only closer (`wall_multi_v7`) | **PASS** | Human 2026-09-21 hybrid PASS, then wall-only. **2026-09-22 device:** `main` @ 98291b0, `code=wall_multi_v7`. Usage OFF. Wall=`max(60,window)` (15s/1min→~60s, minute snap). Per-app names + unique end minutes so each `intervalDidEnd` fires. Force-quit trials 3–5: 1/3/5 min cadences hold; Continue after close still gets a new wall. Same-length Continue-all queues ~1 min (accepted). Burst-close experiment (`test/wall-burst-close`) dropped — third app never reshielded. Detail: `Journal-Context/trial_results.md`. |
| P06 | Today home ingest | **PASS** | Human 2026-09-21. Never Mind / Continue / window time update on yank + leave-early wall; force-quit OK; day filter: jump to 23rd → zeros, back to 21st → prior totals restored (filter not wipe). |
| P07 | Goals / XP / streaks | **PASS** | Human 2026-09-21. Never Mind → XP/goals; Continues don't fake opens; window end updates; day filter OK. Weights: `docs/SCORING_WEIGHTS.md`. |
| P08 | Settings + Continue budget + Pause | **PASS** | Human confirmed on device 2026-09-23. Settings default window applies to preferred + all tracked apps; next Continue uses new duration (15s/1min still ~60s wall). Home remaining = budget − continues_today (floor 0); Continue still works at 0; L2 copy OK. Pause confirm clears shields; Resume / Shield all restores. **Decisions:** Continue budget **global**; window **editable mid-day** from Settings; Pause Attention **yes, with confirm**. P10 usage-checkpoint left stubbed. |
| P09 | Onboarding + notification honesty | **PASS** | Human confirmed on device 2026-09-23. Full path: why → auth → pick/name → notification honesty (checkbox required) → window/budget → shields. Second launch goes to Home. Honesty copy matched shield/notification behavior. Tips replay and first-launch reset available in Settings. |
| P10 | Usage checkpoint optional | **PASS** | Human 2026-09-23. Toggle on: two different tracked apps each got a new timestamp after ~1 min of use. Toggle off: another minute in a tracked app added nothing; last timestamp stayed. Side signal only (`threshold_unit=duration`); not an open or a session; wall closer unchanged. `checkpoint_unavailable` not reported. |
| P11 | Dogfood / stress / all-day | AWAITING HUMAN | Agent 2026-09-23: Dogfood tab checklist (force-quit, reboot, lock, rapid reopen, switcher, notifications, airplane, date rollover, revoke auth, all-day) + copy logs. Launch/foreground: auth not approved clears shield-UI optimism and logs `ATTN-P11 auth_lost`. Day change logs `ATTN-P11 day_rollover` and clears Continue/Never Mind counts; Home budget follows today's events. No new Screen Time APIs. Build OK. |
| P12 | Distribution entitlement | AWAITING | |
| P13 | Recap + v1 freeze | AWAITING | |

## Bundle ID inventory (fill in P12)

| Target | Bundle ID | Family Controls | App Group | Distribution request |
| ------ | --------- | --------------- | --------- | -------------------- |
| Host | com.attention.apitest | yes | group.com.attention.apitest | not requested |
| ShieldConfiguration | com.attention.apitest.ShieldConfiguration | yes | group.com.attention.apitest | not requested |
| ShieldAction | com.attention.apitest.ShieldAction | yes | group.com.attention.apitest | not requested |
| DeviceActivityMonitor | com.attention.apitest.DeviceActivityMonitor | yes | group.com.attention.apitest | not requested |

## v1 success criteria (fill in P13)

| # | Criterion | Human |
|---|---|---|
| 1 | Pause at door for every tracked app | |
| 2 | Never Mind feels like a win | |
| 3 | Timed Continue + safe re-shield | |
| 4 | Firmer copy after more Continues | |
| 5 | No dishonest open/session claims | |
| 6 | Notification honesty understood | |
