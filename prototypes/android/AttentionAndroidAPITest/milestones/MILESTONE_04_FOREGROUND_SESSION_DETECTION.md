# M04 — Foreground / Session Detection

**Goal:** turn raw UsageEvents into **session** candidates and measure them against ground truth. Decide if "session" is an honest label.

**User-visible change:** a recording panel: ground-truth counter vs detected sessions, plus miss/duplicate/latency fields.

**Prerequisite:** M03 PASS; Usage Access granted; at least one selected app.

**Agent rule:** implement this milestone only. Stop after `assembleDebug` succeeds. Do not mark PASS. Never label a detection an `open`.

## Out of scope

- Exact-open / 50-open trial → **M05**
- Showing an intervention → **M06**
- Deciding the product metric (that uses M05–M09 evidence)
- Accessibility / overlay

## Context

A session is a foreground episode, not a launch. Launcher, recents, notifications, deep links, lock, and rapid reopen will disagree with naive `MOVE_TO_FOREGROUND` counting. This milestone builds the comparison harness and runs those scenarios.

Canonical fallback (do not skip ahead): Exact App Opens → Distinct Sessions → Access Windows → Usage-Time.

## Steps for the agent

1. Define a `DetectedSession` (package, startMs, endMs or `ongoing`, sourceEventTypes). Document the grouping rule in a comment (e.g. foreground/resume starts; background/pause ends; merge gaps shorter than N ms — pick N and show it on screen).
2. Experiments: **Session test** panel:
   - selected package under test
   - Start/Stop recording
   - Ground-truth stepper (`+1 I opened it`, `+1 I left it`) — human-operated
   - Detected session count, last detection timestamp, last latency vs previous ground-truth tap if you can pair them loosely
   - Live list of detected sessions
3. Log every detection and every ground-truth tap, tag `ATTN-M04`. Include scenario name if the human typed one.
4. After Stop, show totals: ground-truth starts, detected starts, duplicates (two detections with no ground-truth in between — best-effort), unpaired detections.
5. Keep the M03 raw event list reachable so the human can see why a session was or was not formed.
6. On-screen copy: `Detected sessions (not opens).`

## Agent exit checks

```text
.\gradlew.bat assembleDebug
```

- [ ] Debug APK builds
- [ ] Grouping rule is visible in UI or a comment the human can read
- [ ] Grep `src/` for user-visible `"open"` labels on these detections → zero (log keys like `session_detected` are fine)
- [ ] No intervention Activity / Service beyond what M01–M03 already have
- [ ] Grep `AccessibilityService`, `SYSTEM_ALERT_WINDOW` → zero hits

## Physical-device checklist (human)

Run each as its own recording. Use one selected app. Fill the controlled-test template in `docs/TEST_RESULTS.md`.

- [ ] **Launcher:** Home → tap app icon → use ~5s → Home. Repeat 5 times
- [ ] **Recents:** switch to the app from recents 5 times
- [ ] **Notification:** if the app can open from a notification, do that 3 times
- [ ] **Lock:** open app, lock, unlock, confirm still there / or it restarted — record what the detector said
- [ ] **Rapid reopen:** leave and return within ~1s, 10 times
- [ ] **Split-screen / multi-window** if the phone supports it: note whether `MOVE_TO_FOREGROUND` double-counts
- [ ] For each scenario record: ground-truth count, detected count, misses, duplicates, rough latency
- [ ] Verdict in notes: session detection `honest` / `partial` / `unreliable`
- [ ] Mark PASS only if the harness worked and numbers were recorded — not because counts matched

## Definition of done

- [ ] Session grouping implemented and instrumented
- [ ] Ground-truth harness on device
- [ ] Terminology remains session, not open
- [ ] Human recorded per-scenario counts

**Next:** [M05 — Exact Open Detection](./MILESTONE_05_EXACT_OPEN_DETECTION.md)
