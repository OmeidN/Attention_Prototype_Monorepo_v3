# M03 — Usage Access and Raw Events

**Goal:** obtain Usage Access, dump recent `UsageEvents`, show **MOVE_TO_FOREGROUND counts per package** next to `queryUsageStats` totals for the same range, and let the human correlate with what they did.

**User-visible change:** permission status, settings button, raw event list, plus a two-column debug view: event-based foreground counts vs daily usage-stats (time in foreground, last used).

**Prerequisite:** M02 PASS; at least one real app selected.

**Agent rule:** implement this milestone only. Candidate counts are **not** product `opens` until M05. Do not infer sessions yet.

## Out of scope

- Session grouping harness → **M04**
- 50-open validation → **M05**
- Calling `MOVE_TO_FOREGROUND` an "open" in UI copy
- Accessibility / overlay
- Background WorkManager / FGS (manual Refresh is enough here)

## Context

`queryEvents` is the candidate primitive for episode/open counting. `queryUsageStats(INTERVAL_DAILY)` is the candidate for total time. This milestone puts both on one screen so we do not mix them later. Split-screen/multitask can double-count foreground events on some OEMs — the human will note that.

## Steps for the agent

1. Add `android.permission.PACKAGE_USAGE_STATS` (`tools:ignore="ProtectedPermissions"` as needed). Not a runtime permission.
2. Setup: `Usage Access: granted | denied` via `AppOpsManager.checkOpNoThrow(..., AppOpsManager.OPSTR_GET_USAGE_STATS, ...)`. Button: `Settings.ACTION_USAGE_ACCESS_SETTINGS`. Log grant/deny, tag `ATTN-M03`.
3. Denied: empty state, no crash.
4. `queryEvents(start, end)` over a configurable window (default last 15–30 minutes / "today" / "last hour"). Filter to M02 package names. List rows: package, type name (`MOVE_TO_FOREGROUND`, `MOVE_TO_BACKGROUND`, `ACTIVITY_RESUMED`, `ACTIVITY_PAUSED`, or `type_<n>`), timestamp.
5. Count `MOVE_TO_FOREGROUND` per `event.packageName` for the same window. Label the column `foreground_event_count (not opens)`.
6. Side by side: `queryUsageStats(INTERVAL_DAILY, start, end)` — total time in foreground, last time used — for the same packages.
7. Refresh, window length, snapshot to TestLogger. Disclaimer: `Raw events / time. Not validated opens.`

## Agent exit checks

```text
.\gradlew.bat assembleDebug
```

- [ ] Debug APK builds
- [ ] Both queryEvents counts and queryUsageStats time on one screen
- [ ] UI does not label counts as `open`
- [ ] Grep `AccessibilityService`, `SYSTEM_ALERT_WINDOW` → zero hits

## Physical-device checklist (human)

- [ ] Denied: button opens system Usage Access; event list explains the block
- [ ] Grant Usage Access for this app; status flips to granted after return
- [ ] Select one app you can open quickly. Refresh. Use that app for ~20 seconds, Home, return to the prototype, Refresh
- [ ] Confirm foreground/background (or resume/pause) rows exist for that package with plausible timestamps
- [ ] Over ~30 minutes, open a selected app a **known** number of times. Compare `foreground_event_count` to your ground truth. Log mismatch and a guess (split-screen/multitask double-count is a known OEM issue)
- [ ] Confirm usage-stats time and last-used look plausible next to the event count (they need not match — they measure different things)
- [ ] Note latency: seconds between leaving the app and seeing the event
- [ ] Note gaps
- [ ] Revoke Usage Access, reopen prototype — status denied, no crash
- [ ] Record PASS/FAIL, latency, gaps, and count discrepancy in `docs/TEST_RESULTS.md`

## Definition of done

- [ ] Usage Access guided and detectable
- [ ] Raw events + foreground_event_count + queryUsageStats on one screen
- [ ] Terminology is still "events"/"time", not "opens"
- [ ] Human recorded correlation, count discrepancy, latency/gaps

**Next:** [M04 — Foreground / Session Detection](./MILESTONE_04_FOREGROUND_SESSION_DETECTION.md)
