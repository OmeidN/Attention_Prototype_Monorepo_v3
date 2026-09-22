# P07 — Goals, XP, Streaks

**Goal:** layer reinforcement on honest events: daily goals, XP, and a Never Mind–based streak. All scoring reads the local event store — never Screen Time opens.

**User-visible change:** Home shows XP, streak, and today’s goals with done/not-done. Completing a Never Mind or short window visibly moves numbers on next ingest.

**Prerequisite:** P06 PASS (event ingest + Today counts).

**Agent rule:** implement this milestone only. Keep weights simple and documented in-app or in `docs/`. No backend. No programs/Pro/AI.

## Out of scope

- Continue budget settings UI → **P08**
- Onboarding → **P09**
- Weekly recap narrative → **P13**

## Context

Design plan survival features: goals, XP, streaks on intentional choices / Continues / windows. Suggested starting weights (tune later, don’t block):

| Action | Effect |
|---|---|
| Never Mind | +XP; counts toward daily intentional-choice goal |
| Continue | spends budget later (P08); small or zero XP |
| Short window (≤ chosen length) | bonus XP |
| Under daily window-minute goal | goal complete |

Streak (v1): days with ≥1 intentional choice (or meeting a small daily Never Mind goal).

## Steps for the agent

1. Define `ScoringRules` (constants) + apply on ingest of new events.
2. Persist XP total, daily XP, streak count, last streak day, goal definitions for today.
3. Home: large-enough XP + streak; 2–4 daily goals with checkmarks.
4. Unit-test rules with fixture events if practical (no device needed for pure functions).
5. Tag `ATTN-P07`. Instrument awards with timestamps.

## Agent exit checks

- [x] Build succeeds
- [x] Scoring functions take events, not Report API data
- [x] Goal/XP/streak visible on Home

## Physical-device checklist (human)

- [ ] Never Mind → XP and intentional goal update
- [ ] Several Continues do not fake “open” goals
- [ ] Short window earns expected bonus (if implemented) — end elapsed ≤ preferred window → +5
- [ ] Next calendar day: streak logic behaves (or note mock date test)
- [ ] Record weights used in `PRODUCTION_RESULTS.md`

## Definition of done

- [ ] Reinforcement loop visible on device
- [ ] Human confirmed Never Mind feels like a win

**Next:** [P08 — Settings and Budget](./MILESTONE_08_SETTINGS_AND_BUDGET.md)
