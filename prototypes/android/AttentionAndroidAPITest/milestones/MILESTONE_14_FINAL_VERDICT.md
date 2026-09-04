# M14 — Android Final Verdict

**Goal:** complete `docs/ARCHITECTURE_DECISION.md`. Choose one primary model. Do not start the production app.

**User-visible change:** optional Setup banner showing the recorded verdict string after the human fills it — or none. The deliverable is the markdown file.

**Prerequisite:** M13 complete. TEST_RESULTS has physical-device rows for the milestones you actually ran.

**Agent rule:** draft ARCHITECTURE_DECISION from existing notes. Do **not** fill PASS/FAIL for untested rows. Do not implement leftover features. Do not edit iOS docs except if the human later asks for the root comparison.

## Out of scope

- Production app: scoring engine, 7-day baseline, home/score UI, Room-as-product-DB, Programs, Play Billing, AI Coach, networking
- Root `docs/FINAL_PLATFORM_COMPARISON.md` until iOS also has a verdict (later task)
- Re-running M08 only to make Accessibility look better

Carry forward: no iOS naming screen; packageName identity; queryEvents vs queryUsageStats; FGS vs WorkManager vs Accessibility; first-unlock result; M08 committed approach.

## Context

Allowed choices (pick one primary):

- **Open Model** — only if M05 validated launch/open semantics
- **Session Model** — distinct foreground episodes are honest
- **Access Window Model** — Continue grants a bounded window; ends are timers or coarse
- **Usage-Time Model** — checkpoints / time used, not episode boundaries
- **TECHNICALLY VIABLE / DISTRIBUTION RISK** — loop works, Play posture is bad
- **RECONSIDER / STOP** — red lines: cannot target selected apps, intervention unusable, or no meaningful signal beyond generic screen time

Canonical fallback: Exact App Opens → Distinct Sessions → Access Windows → Usage-Time. Never label a lower-resolution signal as a higher one.

## Steps for the agent

1. Fill every section in `docs/ARCHITECTURE_DECISION.md`: Evidence, Reliable Signals, Unreliable Signals, Recommended Terminology, Intervention Architecture, Required Permissions, Background/OEM Limitations, Play Policy Risks, Production Recommendation.
2. Cite milestone IDs and TEST_RESULTS, not vibes. If a milestone was SKIPPED, say SKIPPED.
3. Recommended terminology must match the chosen model (`open` vs `session` vs `access window` vs `usage time`).
4. Production recommendation: what to build first on Android vs what to refuse (e.g. Accessibility as default).
5. Update `PROJECT_STATUS.md` Android section to `M14 — verdict drafted, awaiting human confirmation` — not `COMPLETE` until the human agrees.
6. No new runtime features.

## Agent exit checks

- [ ] `ARCHITECTURE_DECISION.md` status is a real choice, not `NOT DECIDED`, unless evidence is genuinely insufficient — in that case say what is missing
- [ ] Terminology does not call unvalidated signals `opens`
- [ ] `assembleDebug` still succeeds if you touched the app

## Physical-device checklist (human)

- [ ] Read ARCHITECTURE_DECISION against TEST_RESULTS. Correct over-claims
- [ ] Confirm the chosen model is the highest **honest** unit, not the most flattering
- [ ] Confirm Play risk is not buried (especially Accessibility if present)
- [ ] Identity is packageName + UUID, not an iOS-style required nickname
- [ ] Mark M14 PASS in TEST_RESULTS when you accept the write-up
- [ ] Leave production unbuilt (no scoring/home/Billing/AI in this repo yet)

## Definition of done

- [ ] Architecture decision file complete
- [ ] One primary model (or stop) chosen
- [ ] Human accepted the verdict
- [ ] Production app not started

**Next:** stop Android implementation. When iOS M13 exists, a separate task fills root `docs/FINAL_PLATFORM_COMPARISON.md`.
