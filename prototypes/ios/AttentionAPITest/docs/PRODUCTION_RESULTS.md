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
| P05A | Hard threshold re-shield | AWAITING HUMAN | Agent: per-app window; Continue re-arms DeviceActivity; extension hard re-shield; yank disclosed. Build OK. |
| P06 | Today home ingest | AWAITING | |
| P07 | Goals / XP / streaks | AWAITING | |
| P08 | Settings + Continue budget + Pause | AWAITING | |
| P09 | Onboarding + notification honesty | AWAITING | |
| P10 | Usage checkpoint optional | AWAITING | |
| P11 | Dogfood / stress / all-day | AWAITING | |
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
