# Attention iOS v1 scope freeze

Tag: `ATTN-P13`  
Status: **accepted 2026-09-26.** Human agreed this limitations list. Recap wear 2026-09-25 matches Home. Six criteria recorded in `docs/PRODUCTION_RESULTS.md`.

This is the product that dogfoods on `com.attention.apitest`. It is not an App Store release. Family Controls (Distribution) was granted to the account (2026-09-25). TestFlight smoke PASS 2026-09-26 (Attention Lab 0.1 (3)).

## Included

- Shield at the door for tracked apps (UUID + user-typed label; token is a handle).
- Never Mind (intentional choice) or timed Continue. Continue does not auto-launch the app.
- Wall-only closer `wall_multi_v7`: wall = `max(60, window)`. 15s debug and 1 min both close around 60s. Usage threshold is off as a closer. Unique end minutes. Burst-close rejected.
- Friction copy L0–L2 from per-app Continues today. No Continue-button delay.
- Today home, goals, XP, Never Mind streak. Honest unit is `access_window`, not an open or a session.
- Settings: global Continue budget (does not lock Continue), default window editable mid-day, per-app window on Apps, Pause Attention with confirm.
- First-run onboarding with notification honesty (checkbox required).
- Optional usage checkpoint (duration side signal, default off).
- Dogfood checklist and log copy.
- Recap: today plus last 7 days from the local event log. Rules-based sentence only. No AI.

## Explicit non-goals (v1)

- Open or session counters, and DeviceActivityReport as product truth
- Programs (7/14/21/30), StoreKit, accounts, backend, analytics SDKs, AI coach
- Android
- Bundle ID rename
- App Store submission
- All-day wear was not run in P11; human accepted moving on

## Known limitations (accepted)

- The wall can return while you are still in the app (a yank). Human 2026-09-25: that is intended. Design-plan “no mid-scroll yank” does **not** match this build.
- Never Mind is a button, not a felt win (criterion 2). Copy/UX later, not a closer change.
- Continue unblocks, then you tap the app again. No auto-launch.
- Shielded apps suppress notifications. After Continue a backlog can appear. Re-shield can clear Notification Center entries.
- Budget at 0 still allows Continue. It is not a lockout.
- Friction L1/L2 once stayed at L0. 2026-09-25: level now reads today’s Continue events (same store as Home). Confirmed on device 2026-09-30 (V11-00 PASS).
- A manual date jump can log a huge window time on the fake day (open wall billed until the new clock). Restoring the date brings the real day back. Left alone.
- Same-length Continue-all queues about 1 minute apart so each wall can fire.
- 2026-09-29, one time on TestFlight: an app's open window stayed while its wall disappeared from `pending`, so it never reshielded. Shield all recovers it. Cause unknown. Watching.
- Host catch-up runs when Attention is in the foreground. The monitor extension closes walls when Attention is dead.
- Distribution entitlement granted to the account (2026-09-25). TestFlight smoke PASS 2026-09-26 (Attention Lab 0.1 (3)). Not an App Store release.
- Recap needs a few lived days after cold installs (no prior-day history).

## Copy audit (product UI)

Product screens do not show an open count or a session count. “Open” in product copy means the tracked app can launch, or it denies that we count opens. Recap and Home say the unit is an access window.

## After freeze

New work uses `milestones-v1.1/`. Direction for later: `milestones-production/FUTURE_MONETIZATION.md`. Do not reopen the closer unless a named milestone says it is broken.
