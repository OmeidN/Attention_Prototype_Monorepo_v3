# M07 — Continue and Back-Out UX

**Goal:** selected app → intervention → **Never Mind** or **Continue**, with measurements of task stack, taps, latency, relaunches, and repeatability.

**User-visible change:** two explicit actions on the intervention screen. Never Mind returns the user to a safe place. Continue lets them into the selected app (for this milestone, until they leave — not a timed window).

**Prerequisite:** M06 PASS enough that an intervention can appear at least sometimes.

**Agent rule:** implement this milestone only. Do not add access-window timers (M09). Do not add Accessibility/overlay (M08).

## Out of scope

- Timed access windows, session-end re-intervention → **M09**
- Progressive friction → **M10**
- Accessibility / overlay → **M08**

## Context

The shared loop needs a clean back-out and a clean continue (`PROTOTYPE_MASTER_PLAN.md` questions 4–5). Android task affinity will fight you: Continue may open a second copy, Never Mind may land in recents on the blocked app, Back may undo the intervention. Measure the real stack instead of assuming `finish()` is enough.

## Steps for the agent

1. Replace M06's dismiss stub with two buttons: **Never Mind** and **Continue**. Keep the ugly layout. Show **system app label**, package, latency, timestamp.
2. **Never Mind:** log `choice=never_mind` and an **Intentional Choice** record `{ trackedAppId: UUID, packageName, timestamp }`. Go Home (`ACTION_MAIN` + `CATEGORY_HOME`). Finish the intervention. Do not start the selected package. Do **not** award XP (after verdict).
3. **Continue:** log `choice=continue` with the same id. Finish intervention and bring the selected app forward (`getLaunchIntentForPackage` or documented alternative). Log success/failure of that start.
4. After Continue, **do not immediately re-show** the intervention for the same episode. Use a simple "continue grace" flag cleared when that package leaves the foreground (or a short hardcoded ignore — show the rule on screen). Timed windows are M09; this is only to avoid an infinite loop.
5. Log taps, `intervention_shown_at`, `choice_at`, delta ms, and activity/task notes you can get (`taskId` if useful), tag `ATTN-M07`.
6. Experiments: counters for Never Mind vs Continue this process, last outcome, last stack/escape note field the human can screenshot.

## Agent exit checks

```text
.\gradlew.bat assembleDebug
```

- [ ] Debug APK builds
- [ ] Both actions exist and are logged
- [ ] No access-window duration picker yet
- [ ] Grep `AccessibilityService`, `SYSTEM_ALERT_WINDOW` → zero hits

## Physical-device checklist (human)

Repeat each 5 times. Note taps and where you landed.

- [ ] **Never Mind:** intervention → Never Mind → you are not in the selected app. Recents: is the selected app still the next card? Can one Recents tap bypass Attention?
- [ ] **Continue:** intervention → Continue → you are in the selected app without an extra blank Attention screen stuck on top
- [ ] **Back from intervention:** system Back vs Never Mind — do they differ?
- [ ] **Immediate re-open after Never Mind:** open the selected app again. Intervention should appear again (loop avoided only after Continue)
- [ ] **Continue then leave then return:** after Continue, Home, open selected app again. Record whether intervention appears (M09 will own the policy; here just record)
- [ ] Count extra taps vs the ideal (one tap on the choice)
- [ ] Record PASS/FAIL, bypass via Recents, and duplicate-activity issues in `docs/TEST_RESULTS.md`

## Definition of done

- [ ] Never Mind and Continue implemented and instrumented
- [ ] Continue does not flicker-loop the same episode
- [ ] Human recorded stack, taps, latency, relaunch behavior

**Next:** [M08 — Advanced Intervention API Experiment](./MILESTONE_08_ADVANCED_INTERVENTION_API_EXPERIMENT.md)
