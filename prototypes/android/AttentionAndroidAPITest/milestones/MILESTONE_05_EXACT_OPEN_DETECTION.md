# M05 — Exact Open Detection

**Goal:** run a controlled ~50-open trial. Use the word **open** only if the experiment supports launch/open semantics. Otherwise keep **session** (or lower).

**User-visible change:** an open-trial panel with ground-truth vs detections, running totals, and a visible "do not call this an open" banner unless the human later says otherwise.

**Prerequisite:** M04 PASS (harness works; session behavior recorded).

**Agent rule:** implement this milestone only. Default labels stay `detected_episode` / `session`. Do not rename product copy to "open" in code. Stop after the build succeeds.

## Out of scope

- Interventions → **M06**
- Changing `ARCHITECTURE_DECISION.md` (M14). You may append raw numbers to `TEST_RESULTS.md` as notes, not a verdict
- Accessibility / overlay

## Context

Exact App Opens is the highest-resolution metric in the fallback chain. Android UsageEvents often cannot distinguish "user launched from launcher" from "returned from recents" or "activity resumed." M04 measured sessions. M05 asks whether a stricter rule can recover launches. If it cannot, that is a successful measurement, not a failed milestone.

## Steps for the agent

1. Add an **Open trial** panel (separate from M04's session panel). Fields: target package, trial size default 50, Start/Stop, ground-truth `+1 launch from launcher icon only`.
2. Implement one **candidate open rule** and show it on screen. Default candidate: count `MOVE_TO_FOREGROUND` (M03) only when you are trying to approximate launches — if you cannot distinguish launcher vs recents vs resume, say `cannot distinguish launch vs resume` on screen and keep the M04 session count beside it.
3. Live counters: ground truth, detections, misses, false positives, last latency. Log each truth tap and detection, tag `ATTN-M05`. Log the rule name.
4. At Stop, show summary. Do **not** auto-write PASS or change terminology in the app.
5. Keep M04 session detector available so the human can see both numbers on the same trial.

## Agent exit checks

```text
.\gradlew.bat assembleDebug
```

- [ ] Debug APK builds
- [ ] UI does not claim "open" as a validated product metric
- [ ] Trial counters and TestLogger lines exist
- [ ] Grep `AccessibilityService`, `SYSTEM_ALERT_WINDOW` → zero hits

## Physical-device checklist (human)

- [ ] Cold start the prototype, grant Usage Access, pick one app
- [ ] **Launcher-only trial:** 50 times: Home → tap the app's launcher icon → Home. Count on the ground-truth button each launch. Do not use recents
- [ ] Record ground-truth, detections, misses, false positives, typical latency in the controlled-test template
- [ ] **Recents contrast (10 times):** open from recents only. If the "open" rule also counts these, it is not launch-accurate — write that down
- [ ] **Notification contrast** if available (a few times)
- [ ] Decide in notes: `opens validated` / `sessions only` / `weaker than sessions`
- [ ] Mark M05 PASS when the trial was completed and recorded, even if opens were not validated

## Definition of done

- [ ] ~50-open harness exists
- [ ] Rule and limitations visible on device
- [ ] Code still does not treat the signal as a product `open` unless the human's notes say it is validated
- [ ] Human recorded the trial

**Next:** [M06 — Intervention Baseline](./MILESTONE_06_INTERVENTION_BASELINE.md)
