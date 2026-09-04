# M01 — Android Prototype Foundation

**Goal:** turn the blank app into the experiment shell every later milestone will use: three tabs, timestamped on-device logs, local experiment state, device/build info, clear/export.

**User-visible change:** Setup / Experiments / Logs screens. Logs are readable on the phone without a cable.

**Prerequisite:** M00 PASS on a physical device, recorded in `docs/TEST_RESULTS.md`.

**Agent rule:** implement this milestone only. Stop after `assembleDebug` succeeds. Do not mark PASS.

## Out of scope

- App picker, persistence of selected packages → **M02**
- Usage Access, UsageEvents → **M03**
- Interventions, services, extra permissions → **M06+**
- Polished UI. Ugly and readable is correct.

## Context

`MainActivity.kt` is a single Column. Later experiments need a place to put controls, a log the tester can screenshot, and a device panel so OEM differences are visible without Logcat. Build this shell now so M02+ does not keep reinventing it.

Suggested layout under `app/src/main/java/com/attention/androidapitest/`:

- `logging/TestLogger.kt` — in-memory ring buffer + Logcat, ISO-8601 timestamps, tag `ATTN-M01`
- `state/ExperimentStore.kt` — SharedPreferences (or DataStore) for small key/value experiment flags
- `ui/SetupScreen.kt`, `ui/ExperimentsScreen.kt`, `ui/LogsScreen.kt`
- `ui/DeviceInfoPanel.kt`

## Steps for the agent

1. Replace the blank Column with a 3-tab scaffold (bottom bar or equivalent): **Setup**, **Experiments**, **Logs**. Keep Material3. Do not add navigation libraries unless needed.
2. **Setup:** DeviceInfoPanel showing manufacturer, model, Android version, SDK int, `applicationId`, versionName, and build type. A one-line "current milestone" field is fine.
3. **Experiments:** placeholder text `M01 — no experiments yet` plus a button that writes one test log line. Real experiment controls start in M02.
4. **Logs:** reverse-chronological list of logger events (time, tag, message). Buttons: Clear, Copy all / Export (share sheet or clipboard). Survives activity recreation for the current process; process death may reset — say so on screen.
5. `TestLogger.log(tag, message)` must also call `Log.i`. Every important event gets a timestamp. Cap the buffer (e.g. 500 lines) so the UI cannot grow without bound.
6. `ExperimentStore` with get/set string and boolean. Use it for a trivial flag (e.g. `foundation_ok=true` written once) so M02 can persist selections the same way.
7. Do not add `PACKAGE_USAGE_STATS`, queries, services, or new Activities.

## Agent exit checks

```text
.\gradlew.bat assembleDebug
```

- [ ] Debug APK builds
- [ ] Three tabs exist; Logs can clear and copy/export
- [ ] `TestLogger` timestamps every line
- [ ] Grep `src/` for `UsageStatsManager`, `AccessibilityService`, `SYSTEM_ALERT_WINDOW` → zero hits

## Physical-device checklist (human)

- [ ] Install on the physical phone
- [ ] Setup tab shows the correct manufacturer, model, and Android version
- [ ] Tap the Experiments test button; Logs tab shows that line with a timestamp
- [ ] Rotate or recreate the activity; logs for this process are still there (or the limitation is visible)
- [ ] Clear logs, confirm the list empties
- [ ] Copy/export, paste into a notes app, confirm the text arrived
- [ ] Leave the app and return; tabs still work
- [ ] Record PASS/FAIL + a screenshot note in `docs/TEST_RESULTS.md`

## Definition of done

- [ ] Setup / Experiments / Logs exist
- [ ] TestLogger + ExperimentStore in place
- [ ] Device/build panel visible
- [ ] Clear/export works
- [ ] No usage or intervention APIs
- [ ] Human recorded physical-device evidence

**Next:** [M02 — App Selection](./MILESTONE_02_APP_SELECTION.md)
