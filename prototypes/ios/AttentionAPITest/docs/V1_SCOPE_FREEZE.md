# Attention iOS v1 scope freeze (draft)

Tag: `ATTN-P13`  
Status: **draft — not accepted** until the human confirms the Recap tab and the six criteria in `docs/PRODUCTION_RESULTS.md`.

This is the product that dogfoods on `com.attention.apitest`. It is not an App Store release. Family Controls distribution is **Assigned**, not Approved.

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

## Explicit non-goals

- Open or session counters, and DeviceActivityReport as product truth
- Programs (7/14/21/30), StoreKit, accounts, backend, analytics SDKs, AI coach
- Android
- Bundle ID rename
- App Store submission (waits on distribution **Approved**, then archive)
- All-day wear was not run in P11; human accepted moving on

## Known limitations

- The wall can return while you are still in the app (a yank). Attention does not need to stay open for that close. Design-plan line “door closes without mid-scroll yank” does **not** match this build.
- Continue unblocks, then you tap the app again. No auto-launch.
- Shielded apps suppress notifications. After Continue a backlog can appear. Re-shield can clear Notification Center entries.
- Budget at 0 still allows Continue. Copy gets firmer. It is not a lockout.
- A manual date jump can log a huge window time on the fake day (open wall billed until the new clock). Restoring the date brings the real day back. Left alone.
- Same-length Continue-all queues about 1 minute apart so each wall can fire.
- Host catch-up runs when Attention is in the foreground. The monitor extension closes walls when Attention is dead.
- Distribution entitlement is Assigned for the five bundle IDs. Dev signing is what the phone uses until Apple approves.

## Copy audit (product UI)

Product screens do not show an open count or a session count. “Open” in product copy means the tracked app can launch, or it denies that we count opens. Recap and Home say the unit is an access window.

## After freeze

New work needs a v1.1 milestone list. Do not add programs, Pro, or AI inside this freeze.
