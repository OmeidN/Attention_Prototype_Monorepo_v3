# iOS Architecture Decision

Status: **DRAFTED — awaiting human confirmation**

**Primary model: Access Window Model**

(Not Open Model. Not Session Model. Usage-Time is a secondary checkpoint only.)

---

## Evidence

Physical device lab: iPhone 17 / iOS 26.6.1, Xcode 26.6, Team `VPG6W79282`, bundle `com.attention.apitest`, App Group `group.com.attention.apitest`. Canonical results: `docs/TEST_RESULTS.md`.

| Area | Milestone | Outcome |
|---|---|---|
| Select apps | M02–M03 | Family Controls individual auth works. Tokens opaque; **UUID + user-typed label** is PK. System picker checkboxes cannot be locked. |
| Shield / friction | M04–M06 | ManagedSettings shield reliable (force-quit + reboot). Custom chrome + Never Mind / Continue. Continue = unblock + `.close` (extra Home tap; no auto-launch). `host_app_needed=no`. |
| Opens / launches | M07–M08 | **`not opens`**. Thresholds are **duration** only. Report is display-only; host cannot read counts. Pickups ≠ opens. |
| Honest unit | M09 | **`access_window`** after Continue; leave/return inside window OK; re-shield deferred if Attention background. |
| Re-shield | M10 | Production candidate **`on_window_end`** (unsafe off). `on_threshold` can yank mid-use. |
| Intensity | M11 | L0/L1/L2 from continues_today via App Group — **trustworthy**. No API to delay Continue button. |
| Stress | M12 | Force-quit, reboot, lock, rapid reopen, switcher, airplane, date rollover, revoke auth behaved as expected. **Full-day reliability: SKIPPED.** Notifications: shielded apps suppress notifs; backlog appears after Continue; re-shield can clear NC entries. |

Red lines not hit: apps selectable, shield usable, Continue/Never Mind usable, useful behavioral unit exists (`access_window`).

---

## Reliable Signals

- Tracked-app identity: **UUID + userLabel**; token is a refreshable handle (M03).
- Shield applied / cleared for selected application tokens (M04).
- Shield action: Never Mind vs Continue (M06).
- Access window start (Continue) and end (timer / deferred host re-shield) (M09–M10).
- Continue / Never Mind counts today for friction copy (M11).
- Coarse **usage_time** checkpoint: `eventDidReachThreshold` after ~N minutes duration, once per event per interval until Restart (M07) — optional, not primary.
- Shield persistence across Attention quit and device reboot (M04, M12).

---

## Unreliable / Unavailable Signals

- Exact **opens / launches** (M08).
- Distinct **session** start/end (cannot tell Home vs Recents; timer end ≠ session end) (M08–M09).
- Host-readable DeviceActivityReport numbers; host `DeviceActivityData.activityData` sandboxed on this device (M08).
- Readable system display names from tokens (`token_name_readable=NO`) (M03).
- Per-open threshold or occurrence-count DeviceActivity events (M07 SDK + device).
- Guaranteed Continue button delay on shield (no ShieldConfiguration API) (M11).
- Notification-driven entry while shielded (suppressed; not a reliable deep-link intervention path) (M12 note).
- Full-day field reliability percentage (**not measured** — M12 skipped).

---

## Recommended Terminology

| Use | Do not use |
|---|---|
| access window | open, launch, session (as validated signals) |
| intentional choice / Never Mind | — |
| Continue | unlock forever |
| usage checkpoint / duration threshold | open count |
| continues_today (friction level) | “engagement score” from Screen Time APIs |
| userLabel + UUID | bundle ID as PK |

Product copy may say “pause” or “check-in”; telemetry and architecture must stay honest to **access_window**.

---

## Intervention Architecture

```text
User opens tracked app
→ Shield (L0/L1/L2 copy from continues_today)
→ Never Mind → stay blocked (intentional choice)
→ Continue → start access_window (N minutes)
     → use app inside window
     → on_window_end: re-shield when safe (Attention active / deferred; no mid-scroll yank by default)
→ Optional: usage_time checkpoint logs (not primary gate)
```

- **Primary loop metric:** access windows (and intentional choices / Continues).
- **Re-shield policy:** `on_window_end`, `unsafe_interrupt=off`.
- **Identity:** UUID rows survive token refresh / reboot; refreshToken or picker re-bind if handle breaks.
- **Progression:** App Group friction levels work; richer XP/goals/scoring are **post-lab** product work, not required for this verdict.

---

## Distribution Constraints

- Requires **Family Controls** / Screen Time entitlement path. Local/dev with paid Apple Developer membership worked on device.
- **App Store** distribution of Family Controls apps is a **separate Apple approval process** — treat as a schedule/risk item, not proven by this lab.
- Shield extensions + App Groups are required; host need not be foreground for shield chrome / Continue (M06).
- Re-shield timing that depends on host timer is weaker if Attention is force-quit until next open (deferred path still works when user returns).

---

## Production Recommendation

**BUILD — Access Window Model** on iOS.

Do **not** build an Open Model or claim session detection on this stack. Use Usage-Time only as secondary checkpoints. Do **not** start production scoring/home/Pro/AI in this prototype repo until the human accepts this write-up and product scope is separate.

Carry forward into production design:

1. UUID + user-typed labels  
2. Token refresh / re-bind  
3. Shield + Continue / Never Mind  
4. Timed access windows + `on_window_end` re-shield  
5. Optional duration thresholds  
6. App Group–driven friction copy  
7. Honest metric naming  

**Stop-Rethink:** not warranted — core loop is viable.

**Next:** human accepts this file in TEST_RESULTS. iOS implementation lab stops at M13. Cross-platform `docs/FINAL_PLATFORM_COMPARISON.md` waits for Android M14.
