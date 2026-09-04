# M11 — Background Reliability

**Goal:** measure FGS watch survival **and** WorkManager ~15 min collection gaps, plus whether `ACTION_USER_PRESENT` can detect **first unlock of the day**.

**User-visible change:** reliability panel: last FGS heartbeat, last WorkManager run, last unlock, last intervention, obvious "watch is dead" state.

**Prerequisite:** M06–M09 working well enough that a miss is meaningful. M08 comparison may be off.

**Agent rule:** implement this milestone only. No OEM autostart hacks. Ignore-battery-optimizations screen once, labeled, logged. Do not add Accessibility here.

## Out of scope

- Reboot / force-stop / date / OEM matrix → **M12**
- Play policy write-up → **M13**
- Bypassing force-stop
- Morning-goal product UX / scoring

## Context

FGS polling dies when swiped away. WorkManager is the honest delayed collector (min ~15 minutes) for counts, not for a real-time shield. First-unlock is a product trigger later; this milestone only logs whether the broadcast is reliable.

## Steps for the agent

1. FGS heartbeat every 60s; stale timestamp visible when the user returns. Persist `events_seen`, `interventions_shown`, `watch_restarts`, `last_kill_reason` (`onTaskRemoved` / destroy). Tag `ATTN-M11`.
2. Schedule a **WorkManager** periodic job at the minimum allowed interval. Each run: timestamp, `get` foreground-event counts since last run (in-memory/ExperimentStore append is enough — no Room product DB). Log gaps.
3. `BroadcastReceiver` for `ACTION_USER_PRESENT`. Persist `lastUnlockAt` and `firstUnlockOfLocalDate`. Log every fire; only the first per local date is `first_unlock`.
4. Setup buttons: battery optimization, `isBackgroundRestricted`, app settings.
5. Do not auto-request every permission. Keep M08 Accessibility off unless the human left it on.

## Agent exit checks

```text
.\gradlew.bat assembleDebug
```

- [ ] Debug APK builds
- [ ] Heartbeat + WorkManager run log + unlock receiver exist
- [ ] No new Accessibility unless already isolated in M08

## Physical-device checklist (human)

Record misses and whether the persistent notification stayed.

- [ ] Arm watch. Swipe Attention from recents. Wait 2 minutes. Open a selected app. Intervention? Heartbeat still advancing when you reopen Attention?
- [ ] Screen off 10 minutes, then open selected app
- [ ] Enable Battery saver (or Adaptive battery if that is what the phone has). Repeat a selected-app open
- [ ] If available: restrict background for this app in system settings, then try again
- [ ] Idle ~1–3 hours with watch armed, then use a selected app and reopen Attention. Screenshot logs. Note WorkManager run timestamps vs hours elapsed (expected ~15 min granularity)
- [ ] Unlock the phone in the morning (or after a long lock): `first_unlock` logged once; extra unlocks the same day do not duplicate it
- [ ] Note manufacturer and battery-optimization state in `TEST_RESULTS.md`
- [ ] Record expected WorkManager delay/gap on **this** device
- [ ] Mark PASS when the run was completed and losses were recorded — not only if nothing died

## Definition of done

- [ ] Heartbeats and kill/restart logs exist
- [ ] Human recorded swipe / idle / saver / restriction outcomes

**Next:** [M12 — Reboot and OEM Stress](./MILESTONE_12_REBOOT_AND_OEM_STRESS_TESTING.md)
