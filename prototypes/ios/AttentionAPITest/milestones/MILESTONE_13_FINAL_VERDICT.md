# M13 — iOS Final Verdict

**Goal:** complete `docs/ARCHITECTURE_DECISION.md`. Choose BUILD Open / Session / Access Window / Usage-Time, or RECONSIDER/STOP. Do not build the production app.

**User-visible change:** none required.

**Prerequisite:** M12 recorded (or gaps listed). Physical-device evidence in TEST_RESULTS.

**Agent rule:** draft the decision from notes. Do not fill untested rows as PASS. Do not start production. Do not edit Android except `PROJECT_STATUS.md` iOS line.

## Out of scope

- Production app: scoring engine, 7-day baseline onboarding, home/Charts, SwiftData product models, Programs, StoreKit, AI Coach, networking
- Root `FINAL_PLATFORM_COMPARISON.md` until Android M14 is also accepted (later task)
- Re-running M08 to chase an Open Model

Those product pieces are **after** this lab. Carry forward into the decision file: UUID PK + user-typed labels, token refresh, threshold unit from M07, report host-readability from M08.

## Context

iOS strongest card is usually shielding + Continue, not exact opens. Red lines: cannot select apps, shield unreliable, or no useful signal. Distribution: Family Controls entitlement for App Store is a separate Apple process (local/dev usually works without that approval).

The architecture file must also state:

- Host can/cannot read DeviceActivityReport numbers
- Threshold is opens vs duration
- Identity is UUID + userLabel, token is a handle

Allowed primary choices: Open Model (only if M08 validated), Session Model, Access Window Model, Usage-Time Model, Stop-Rethink.

## Steps for the agent

1. Fill ARCHITECTURE_DECISION: Evidence, Reliable/Unreliable Signals, Recommended Terminology, Intervention Architecture, Distribution Constraints, Production Recommendation.
2. Cite milestone IDs. SKIPPED/untested called out.
3. Terminology matches the model. No unvalidated `opens`.
4. `PROJECT_STATUS.md` iOS → `M13 — verdict drafted, awaiting human confirmation`.
5. No new runtime features.

## Agent exit checks

- [ ] Decision file is not `NOT DECIDED` unless evidence is insufficient — then list missing tests
- [ ] No production code started

## Physical-device checklist (human)

- [ ] Read the decision against TEST_RESULTS
- [ ] Highest **honest** unit, not the most flattering
- [ ] Family Controls distribution risk mentioned
- [ ] Token/name/PK decisions and M07/M08 API facts are in the write-up
- [ ] Accept the write-up in TEST_RESULTS
- [ ] Leave production unbuilt (no scoring/home/Pro/AI in this repo yet)

## Definition of done

- [ ] Architecture decision complete
- [ ] One model or stop
- [ ] Human accepted
- [ ] Production not started

**Next:** stop iOS implementation. After Android M14, a separate task fills `docs/FINAL_PLATFORM_COMPARISON.md`.
