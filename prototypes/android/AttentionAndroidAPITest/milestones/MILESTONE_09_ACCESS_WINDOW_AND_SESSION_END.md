# M09 — Access Window and Session End

**Goal:** after Continue, test whether we can detect a real session end vs only grant a timed **access window**. Choose the highest honest unit: session end, access window, or usage-time fallback.

**User-visible change:** a configurable post-Continue window (e.g. 1 / 5 / 15 minutes) and logs for window start, window end, suspected session end, and re-intervention.

**Prerequisite:** M07 PASS (Continue works at least sometimes).

**Agent rule:** implement this milestone only. Do not add dynamic intensity (M10). Label signals conservatively.

## Out of scope

- Progressive friction → **M10**
- Background/OEM marathon → **M11–M12**
- Calling a timer expiry an "open" or a "session end" if you only have a clock

## Context

If Android cannot see a clean end of use, Attention can still offer a bounded Continue (access window) or fall back to usage-time checkpoints. Interrupting someone mid-scroll because a poll fired is a product failure even if the API is "working."

## Steps for the agent

1. Experiments: access-window length (`1m`, `5m`, plus a `15s` debug value). Show current mode: `in_window | watching | idle`.
2. On Continue: start the window, log `access_window_start`, allow that package without intervention until **either** the timer fires **or** a session-end rule fires — whichever you implement first, both must be loggable.
3. **Session-end candidates** (implement and show which fired): package `MOVE_TO_BACKGROUND` / pause for longer than X seconds; screen off; Home. Do not treat recents peek as end unless you measured it.
4. **Window end:** log `access_window_end`. Next time the package is foreground, show intervention again.
5. Rapid reopen inside the window must **not** re-prompt. Rapid reopen after end should prompt (record misses).
6. Optional usage-time checkpoint: if events are too sparse, log `usage_checkpoint` at window end anyway so M14 can choose Usage-Time Model.
7. Tag `ATTN-M09`. On-screen: `Window ≠ session end. Labels are experimental.`

## Agent exit checks

```text
.\gradlew.bat assembleDebug
```

- [ ] Debug APK builds
- [ ] Window start/end logged
- [ ] Continue path uses the window, not an immediate re-prompt
- [ ] UI does not label timer expiry as an `open`

## Physical-device checklist (human)

Use the 15s debug window first, then 1 minute.

- [ ] Continue → stay in the app for the whole window → intervention after the next leave+return or at expiry, per on-screen rule
- [ ] Continue → Home immediately → return inside the window → no intervention
- [ ] Continue → Home, wait until after window → return → intervention
- [ ] Foreground → background (other app) → back, inside window
- [ ] Screen lock / unlock inside window
- [ ] Rapid reopen inside vs after window (5 each)
- [ ] Notes: can you tell **session end** from **timer end**? If not, the honest unit is access window or usage-time
- [ ] Record choice in `TEST_RESULTS.md`: `session_end` / `access_window` / `usage_time`

## Definition of done

- [ ] Configurable post-Continue window
- [ ] Session-end candidates logged separately from timer end
- [ ] Human recorded which unit is honest

**Next:** [M10 — Dynamic Interventions](./MILESTONE_10_DYNAMIC_INTERVENTIONS.md)
