# M08 — Advanced Intervention API Experiment

**Goal:** measure **two** real-time detection approaches side by side (debug/isolated, not the default path): (1) fast UsageStats polling, (2) `AccessibilityService` on window-state changes. Record latency, cost, and **unhedged Play review implications**. Then the human commits to one approach.

**User-visible change:** Experiments → **M08 comparison** (default off). Polling path can reuse M06. Accessibility path is a separate toggle with a scary permission screen.

**Prerequisite:** M07 recorded. This milestone is **not skippable** as a paper-only skip unless Accessibility cannot be declared on this SDK — then record the blocker. You may skip *shipping* Accessibility as default; you may not skip *measuring* it without evidence.

**Agent rule:** do not make Accessibility the default watch. Do not soften Play-policy language. Do not change iOS.

## Out of scope

- Replacing the whole app with accessibility-first architecture
- Play Console submission
- Access windows (M09)
- Production onboarding copy beyond a one-line permission explanation

## Context

M06 already uses FGS polling. The product question is whether that is fast enough for a shield, or whether Accessibility's latency justifies its policy cost. Sideload success is not Play approval. A technical win with bad policy is `TECHNICAL PASS / DISTRIBUTION RISK`.

## Steps for the agent

1. Experiments → **M08 comparison**, default off. Two labeled buttons/toggles: `poll_1_2s` and `accessibility`. Only one armed at a time.
2. **Polling:** 1–2 second UsageStats/queryEvents loop (can be the M06 service at a documented interval). Log detection latency vs human open.
3. **Accessibility:** isolated `AccessibilityService` observing window-state / package for tracked `packageName`s. Same intervention Activity as M06/M07. Manifest permission only while this experiment compiles; keep it behind the toggle.
4. For each approach log: `api`, `latency_ms`, `shown`, failures, tag `ATTN-M08`.
5. Setup: plain-language permission names. In `docs/POLICY_NOTES.md` stub both APIs. **Be direct** about Play review for Accessibility used to detect other apps vs polling + Usage Access.
6. Optional: note Profiler CPU if the human runs it; do not fake numbers.

## Agent exit checks

```text
.\gradlew.bat assembleDebug
```

- [ ] Debug APK builds
- [ ] Default path remains M06 FGS unless the human later promotes M08
- [ ] Both approaches exist **or** accessibility is documented as blocked with a compile/SDK reason
- [ ] POLICY_NOTES stub includes an unhedged Play sentence for Accessibility

## Physical-device checklist (human)

- [ ] Polling: 10 opens of a tracked app — hits/misses/felt latency
- [ ] Accessibility: grant the permission, 10 opens — hits/misses/felt latency
- [ ] Disable M08: behavior returns to M06
- [ ] Note how scary the Accessibility settings screen is
- [ ] If possible, Profiler glance while tapping apps
- [ ] Commit in TEST_RESULTS: `use_polling` / `use_accessibility` / `neither` and why (latency vs Play). Do not pick Accessibility "because the demo looks better" without writing the store risk
- [ ] PASS = comparison recorded, not "Accessibility won"

## Definition of done

- [ ] Side-by-side measurement exists
- [ ] Human recorded the committed approach and Play implication
- [ ] Default path still least-invasive unless explicitly promoted

**Next:** [M09 — Access Window and Session End](./MILESTONE_09_ACCESS_WINDOW_AND_SESSION_END.md)
