# iOS Production Milestones (v1)

## Purpose

Build a **production-ready Attention v1** on iOS around the lab’s **Access Window Model**.

Canonical design: [`../ATTENTION_V1_DESIGN_PLAN.md`](../ATTENTION_V1_DESIGN_PLAN.md)  
Lab evidence (do not re-litigate): `../docs/TEST_RESULTS.md`, `../docs/ARCHITECTURE_DECISION.md`  
Lab milestones (complete): `../milestones-testing/`

## North star

```text
pause → choose → reinforce → adapt
```

Spine: shield at the door → Never Mind or timed Continue → re-shield → reward intentional choices and fewer/shorter windows.

## Rules (same discipline as the lab)

1. Implement **exactly one milestone at a time**.
2. Stop when it builds; give physical-device steps.
3. Do **not** mark PASS until the human confirms on a physical iPhone.
4. Prefer ugly, observable UI over polish.
5. Instrument important events with timestamps.
6. Never call a signal an `open` unless you have validated open semantics (you have not — use `access_window` / intentional choice / Continue).
7. No backend, accounts, StoreKit, analytics SDKs, or AI in v1.
8. Do **not** put DeviceActivityReport counts on the product spine.
9. Default re-shield: **`on_threshold` (hard / may yank)** via DeviceActivityMonitor — set-and-forget. Host `on_window_end` remains available as a gentler experiment, not the product default.
10. Android is out of scope unless explicitly asked.

## Settled facts (carry forward from lab)

1. UUID + user-typed `userLabel` is identity; token is a refreshable handle.
2. Shield + Never Mind / Continue works; Continue does not auto-launch the app.
3. Honest unit is **`access_window`**, not open/session. Threshold closer is **usage duration**, not wall-clock opens.
4. Friction L0→L2 from `continues_today` via App Group is trustworthy; no Continue-delay API.
5. Shielded apps suppress notifications — design with honesty, not bypass.
6. Monitor extension can re-shield while host is dead (`on_threshold`); may interrupt mid-use.
7. Wall closer (P05B, **`wall_multi_v7`**): **wall-only** (`max(60, window)`; 15s/1min→60s); DA ≥15m schedule + past-pad; minute-aligned; **unique end minutes** so same-slot `repeats: false` does not drop a sibling. Same-length Continue-all queues ~1 min. Usage threshold off. Burst-close (same-minute group yank) rejected — a dropped `intervalDidEnd` left an app unshielded.

## Milestone index

| ID | File | Goal |
|---|---|---|
| P00 | [MILESTONE_00_PRODUCT_SHELL.md](./MILESTONE_00_PRODUCT_SHELL.md) | Product app identity, entitlements, auth, empty host shell |
| P01 | [MILESTONE_01_TRACKED_APPS.md](./MILESTONE_01_TRACKED_APPS.md) | Picker, UUID + labels, persist, token refresh |
| P02 | [MILESTONE_02_SHIELD_APPLY_CLEAR.md](./MILESTONE_02_SHIELD_APPLY_CLEAR.md) | Apply/clear ManagedSettings shields for tracked apps |
| P03 | [MILESTONE_03_SHIELD_LOOP_AND_EVENTS.md](./MILESTONE_03_SHIELD_LOOP_AND_EVENTS.md) | Product shield chrome + Never Mind / Continue + event log |
| P04 | [MILESTONE_04_ACCESS_WINDOWS.md](./MILESTONE_04_ACCESS_WINDOWS.md) | Timed windows + host `on_window_end` (gentle path — proven) |
| P05 | [MILESTONE_05_FRICTION_LADDER.md](./MILESTONE_05_FRICTION_LADDER.md) | L0–L2 product copy from `continues_today` |
| P05A | [MILESTONE_05A_HARD_THRESHOLD_RESHIELD.md](./MILESTONE_05A_HARD_THRESHOLD_RESHIELD.md) | **Default closer:** per-app usage threshold + extension hard re-shield (yank OK) |
| P05B | [MILESTONE_05B_HYBRID_WALL_CLOCK.md](./MILESTONE_05B_HYBRID_WALL_CLOCK.md) | Wall-only closer (`max(60,window)`); usage OFF |
| P06 | [MILESTONE_06_TODAY_HOME.md](./MILESTONE_06_TODAY_HOME.md) | Host ingest + Today home (honest metrics) |
| P07 | [MILESTONE_07_GOALS_XP_STREAKS.md](./MILESTONE_07_GOALS_XP_STREAKS.md) | Goals, XP, streaks on logged events |
| P08 | [MILESTONE_08_SETTINGS_AND_BUDGET.md](./MILESTONE_08_SETTINGS_AND_BUDGET.md) | Continue budget, Pause Attention (windows live on Apps / P05A) |
| P09 | [MILESTONE_09_ONBOARDING.md](./MILESTONE_09_ONBOARDING.md) | Onboarding: loop + notification honesty + **yank honesty** |
| P10 | [MILESTONE_10_USAGE_CHECKPOINT_OPTIONAL.md](./MILESTONE_10_USAGE_CHECKPOINT_OPTIONAL.md) | Optional soft checkpoint (non-closing) if still needed |
| P11 | [MILESTONE_11_DOGFOOD_RELIABILITY.md](./MILESTONE_11_DOGFOOD_RELIABILITY.md) | Stress + all-day dogfood (closes lab M12 skip) |
| P12 | [MILESTONE_12_DISTRIBUTION_ENTITLEMENT.md](./MILESTONE_12_DISTRIBUTION_ENTITLEMENT.md) | Family Controls distribution + TestFlight path |
| P13 | [MILESTONE_13_RECAP_AND_V1_FREEZE.md](./MILESTONE_13_RECAP_AND_V1_FREEZE.md) | Thin recap + v1 scope freeze |

## Progress tracking

Record production pass/fail in [`../docs/PRODUCTION_RESULTS.md`](../docs/PRODUCTION_RESULTS.md) (create on P00 if missing).  
Do not overwrite lab `TEST_RESULTS.md`.

**v1 close-out (2026-09-25):** pending Recap wear + freeze accept. P12 archive done; TestFlight not run. Next-version folder [`../milestones-v1.1/`](../milestones-v1.1/) is empty until freeze. Later direction: [FUTURE_MONETIZATION.md](./FUTURE_MONETIZATION.md).

## Explicit non-goals until after P13

- Open/session counters or Report API dashboards  
- Leave-app-triggered re-shield (no API)  
- “We track every open” copy  
- Exact wall-clock stopwatch claims for thresholds  
- Programs / Pro / AI / Android parity  
- Marketing polish beyond readable prototype UI  

Post–v1 monetization direction (Family, Pro, Commitment Credits) — **context only, do not implement in P00–P13:** [`FUTURE_MONETIZATION.md`](./FUTURE_MONETIZATION.md).
