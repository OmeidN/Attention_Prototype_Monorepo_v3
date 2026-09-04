# M11 — Dynamic Interventions

**Goal:** three friction levels driven by today's Continue (or episode) count, using M03 userLabels and App Group state. If the extension cannot see state, one static shield — progression via goals/XP is after the verdict.

**User-visible change:** shield copy/delay escalates: **level 0** no extra delay, **level 1** plain reminder + Continue, **level 2** "Are you sure?" with a short delay before Continue is tappable. Counts persist.

**Prerequisite:** M05 configuration extension + M06 actions.

**Agent rule:** no backend, no ML, no `ScoringEngine`. If App Group reads fail in the extension, show `STATE_UNAVAILABLE` and keep one static shield.

## Out of scope

- Production streaks, XP awards, home score UI, SwiftData, 7-day baseline
- Stress/failure → **M12**

## Context

ShieldConfiguration runs in another process. Counts in the host are useless if the extension reads zeros. Product later wants a friction ladder keyed off the day's activity; this milestone only proves whether shared state can drive three visible levels.

## Steps for the agent

1. Persist `continueCountToday`, `neverMindCountToday` / intentional-choice count, local date in App Group, keyed by tracked-app **UUID**. Increment on M06 actions.
2. Map to levels (show the mapping on screen), e.g. 0 Continues → level 0/1 reminder; after repeated Continues → level 2 delay 0–2s before Continue enables. Subtitle may include `userLabel` if readable in the extension.
3. Increment on choice, not on shield appear. Log previous/next level, tag `ATTN-M11`.
4. Setup fallback: `If extension state fails, production should use one shield and move progression to goals/XP.`
5. Debug: +1 Continue, reset today.

## Agent exit checks

- [ ] Build succeeds
- [ ] Extension reads the same suite as the app writes
- [ ] Increment on choice

## Physical-device checklist (human)

- [ ] Continue 3 times (re-shield as needed). Level 1 then level 2 is visible on the shield
- [ ] Force-quit host, trigger shield: still correct level?
- [ ] Never Mind / Intentional Choice does not bump Continue count
- [ ] Reset today works
- [ ] If copy never changes: record `extension cannot see state`
- [ ] Notes: `trustworthy` / `fragile` / `unusable`

## Definition of done

- [ ] Shared counts + visible intensity attempt
- [ ] Human recorded whether the extension actually adapted

**Next:** [M12 — Stress / Failure Testing](./MILESTONE_12_STRESS_FAILURE_TESTING.md)
