# M07 — Device Activity Thresholds

**Goal:** add `DeviceActivityMonitorExtension`, run an all-day schedule, and answer **without hedging** whether `DeviceActivityEvent.threshold` can mean "opened N times" or only "used for N minutes." That answer is the most important iOS feasibility fact in this lab.

**User-visible change:** Experiments: start/stop monitoring for the named tracked apps. Main app shows last `intervalDidStart` / `intervalDidEnd` / `eventDidReachThreshold` times from App Group.

**Prerequisite:** M03 named selection. M04 shield understanding. M06 Continue is useful but not required.

**Agent rule:** implement this milestone only. Do not call a duration callback an `open`. Write the threshold-unit answer into `docs/TEST_RESULTS.md` from the **actual SDK types**, not from memory of old blog posts.

## Out of scope

- DeviceActivityReport host-app number extraction → **M08**
- 50-open trial → **M08**
- Re-shield policy → **M10**
- Scoring engine

## Context

DeviceActivity is how iOS reports usage in the background. Callbacks can be late, coalesced, or missing. Some SDK versions expose `threshold` as `DateComponents` (duration). If "3 opens" is not expressible, the iOS product metric cannot be Exact App Opens via this API — M08/M13 must follow that fact.

## Steps for the agent

1. Add Device Activity Monitor extension. App Group shared with the main app. `DeviceActivitySchedule` for **all day, every day**. `DeviceActivityEvent` for the tracked apps' current tokens.
2. **Quote the SDK:** what type is `DeviceActivityEvent.threshold`? Can it represent occurrence count ("N opens") or only duration ("N minutes")? Put the unhedged sentence on Setup and in TEST_RESULTS. If only duration, use a short threshold (e.g. 1 minute) as the probe — show the value on screen.
3. Implement `intervalDidStart`, `intervalDidEnd`, and `eventDidReachThreshold`. Each writes timestamp + event name + tracked-app ids you can map into App Group `UserDefaults`. Extension cannot reliably UI-log.
4. Main app: Start monitor / Stop monitor (`stopMonitoring` on stop — no orphan schedules), last fire times, `waiting since`. Tag `ATTN-M07`.
5. Use M03 UUIDs in logs, not token dumps.

## Agent exit checks

- [ ] App + monitor extension build
- [ ] All three callbacks write to App Group
- [ ] TEST_RESULTS draft sentence exists for the agent to fill: `threshold_unit: opens | duration | unknown` — agent fills from API, human confirms on device

## Physical-device checklist (human)

Phone locked/unlocked normally, not only sitting in Xcode.

- [ ] Read the on-screen threshold-unit claim. Does it match what you observe?
- [ ] If duration: use a selected app for **over** the threshold. Did `eventDidReachThreshold` update? Note delay
- [ ] If you tried to express "N opens" and could not, that is a PASS of the *question*, not a failed build
- [ ] Repeat 5 times. Count fires vs attempts
- [ ] Unselected app should not fire
- [ ] Idle 2 minutes without opening selected apps — should not fire
- [ ] Record the unhedged unit in TEST_RESULTS. PASS = the unit is known and callbacks were measured

## Definition of done

- [ ] Monitor + all-day schedule + three callbacks
- [ ] Unhedged opens-vs-duration answer recorded
- [ ] Human recorded repeat reliability

**Next:** [M08 — Exact Open Detection](./MILESTONE_08_OPEN_DETECTION.md)
