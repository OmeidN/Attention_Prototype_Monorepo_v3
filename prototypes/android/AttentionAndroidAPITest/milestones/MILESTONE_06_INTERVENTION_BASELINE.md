# M06 — Intervention Baseline

**Goal:** find the **least-invasive** way to put usable friction in front of a selected app. Measure latency, consistency, escape, flicker, and whether Attention must stay running.

**User-visible change:** when a selected app comes to the foreground, an ugly full-screen intervention can appear. Toggle to arm/disarm the experiment.

**Prerequisite:** M04 PASS (session signal good enough to trigger). M05 notes available but opens need not be validated.

**Agent rule:** implement this milestone only. **Do not** add AccessibilityService or `SYSTEM_ALERT_WINDOW`. If those look necessary, record why and leave them for M08.

## Out of scope

- Continue / Never Mind UX polish and task-stack measurement → **M07** (you may include two unlabeled buttons as stubs; M07 owns the real flow)
- Accessibility / overlay / device-admin → **M08**
- Access windows, re-intervention timing → **M09**
- Production copy, animation, branding

## Context

Technical possibility is not enough (`PROTOTYPE_PLAN.md`). A foreground service that polls UsageEvents and starts an Activity is the default **real-time** candidate: no Accessibility, no overlay. It will likely be late, OEM-killed, or easy to dismiss. Measure that.

Historical counts can be delayed; real-time shields cannot. Add a short on-screen / code comment: **WorkManager ~15 min** (no persistent notification, Doze gaps) vs **FGS** (immediate, ugly notification, battery) vs **Accessibility** (M08, Play risk). Do not fully wire WorkManager here — M11 measures gaps.

## Steps for the agent

1. Add a **foreground service** (`InterventionWatchService` or similar) with a persistent, ugly notification `Attention prototype is watching usage`. Use `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_SPECIAL_USE` (or the least-sensitive FGS type that will compile for target 34). Request `POST_NOTIFICATIONS` on API 33+ with a Setup toggle.
2. While armed, poll or query UsageEvents on a short interval (show the interval on screen, e.g. 500–1000 ms). When a selected package is the foreground app **and** it is not this prototype, start `InterventionActivity` (new task / appropriate flags — document what you chose).
3. `InterventionActivity`: full-screen, readable, ugly. Text: **system label + package**, time detected, time shown, latency ms. Buttons may read `Dismiss (M06)` only.
4. Experiments: Arm / Disarm, last trigger log. Log `watch_started`, `watch_stopped`, `intervention_shown`, `latency_ms`, tag `ATTN-M06`.
5. Debounce so a single episode does not flicker. Show debounce ms.
6. Stub (comment or empty class) a WorkManager periodic worker — **not scheduled** — with the trade-off comment above.
7. If the prototype cannot see foreground changes without the service, say so on Setup. Do not silently fail.

## Agent exit checks

```text
.\gradlew.bat assembleDebug
```

- [ ] Debug APK builds
- [ ] Grep `src/` and manifests for `AccessibilityService`, `SYSTEM_ALERT_WINDOW`, `BIND_ACCESSIBILITY_SERVICE` → zero hits
- [ ] Foreground service + notification exist
- [ ] Intervention logs latency

## Physical-device checklist (human)

- [ ] Arm watch. Grant notification permission if asked. Confirm the persistent notification
- [ ] Open a selected app from launcher. Record: did intervention appear? latency (on-screen or felt)?
- [ ] Repeat 10 times. Count hits / misses / double-fires / flicker
- [ ] With intervention showing, press Back, Home, Recents. Record whether you can escape to the selected app without the prototype
- [ ] Disarm. Open the selected app — no intervention
- [ ] Swipe the prototype away from recents (or force-stop). Open the selected app. Record whether watching survived (expected: often no)
- [ ] Note whether Attention **must stay in the foreground task / have a live service** for this to work
- [ ] Record PASS/FAIL + escape/flicker notes in `docs/TEST_RESULTS.md`

## Definition of done

- [ ] Least-invasive watch + full-screen friction implemented (no Accessibility/overlay)
- [ ] Latency and trigger events logged
- [ ] Human recorded consistency, escape, flicker, process-lifetime need

**Next:** [M07 — Continue and Back-Out](./MILESTONE_07_CONTINUE_AND_BACK_OUT.md)
