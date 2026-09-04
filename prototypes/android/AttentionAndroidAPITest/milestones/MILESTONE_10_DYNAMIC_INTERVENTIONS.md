# M10 — Dynamic Interventions

**Goal:** three friction levels from today's counts: **0** no extra delay, **1** reminder + Continue, **2** "Are you sure?" with a short delay before Continue is tappable. Measure whether counts are accurate, persistent, and race-free.

**User-visible change:** intervention copy/delay escalates. State survives relaunch. System app label shown (not a typed nickname).

**Prerequisite:** M09 recorded (window or session-end rule exists).

**Agent rule:** implement this milestone only. No backend, no ML, no scoring-spec engine.

## Out of scope

- Production scoring, streaks UX, home score, Room product DB, coaching
- Changing Google Play policy posture
- Background reliability marathon → **M11**

## Context

If state is untrustworthy, do not build a personality on it — keep one shield and put progression in goals/XP after the verdict.

## Steps for the agent

1. Persist `continueCountToday`, `neverMindCountToday`, `lastInterventionAt` per tracked-app UUID in ExperimentStore. Reset on local date; log `day_rollover`.
2. Map to levels 0 / 1 / 2 (show the mapping). Level 2: 0–2s before Continue enables. Show level + counts + **system label**.
3. Increment only on a confirmed human choice, not on `intervention_shown`. Intentional Choice (Never Mind) must not increment Continue. Log previous/next, tag `ATTN-M10`.
4. Debounce with episode id; log `race_ignored`.
5. Debug: +1 Continue, reset-today.
6. Fallback copy: `If counts desync, production should use one intervention and move progression to goals/XP.`

## Agent exit checks

```text
.\gradlew.bat assembleDebug
```

- [ ] Debug APK builds
- [ ] Counts persist in ExperimentStore
- [ ] Intensity visible on intervention
- [ ] Increment is on choice, not on show

## Physical-device checklist (human)

- [ ] Continue 3 times (with window expiry or leave/return as needed). Level 1 then 2 is visible
- [ ] Force-stop prototype, reopen: counts still there; **system names** still show (no typed-name screen)
- [ ] Never Mind does not increment Continue count
- [ ] Trigger intervention twice quickly; count does not jump by 2 for one choice
- [ ] Debug +1 and Reset work
- [ ] Optional: leave the app overnight or change the date — counts reset or `day_rollover` logged
- [ ] Notes: state `trustworthy` / `fragile` / `unusable`. Record in `TEST_RESULTS.md`

## Definition of done

- [ ] Local intensity from persisted counts
- [ ] Race/debounce logged
- [ ] Human recorded accuracy and persistence

**Next:** [M11 — Background Reliability](./MILESTONE_11_BACKGROUND_RELIABILITY.md)
