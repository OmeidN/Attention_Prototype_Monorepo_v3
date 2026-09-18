# Attention v1 Design Plan (iOS)

**Status:** Draft for product design after lab acceptance of the Access Window Model  
**North star:** pause → choose → reinforce → adapt  
**Platform:** iOS first (Family Controls / ManagedSettings / DeviceActivity)  
**Lab basis:** M00–M12 PASS; M13 architecture draft = Access Window Model  
**Canonical evidence:** `prototypes/ios/AttentionAPITest/docs/TEST_RESULTS.md`, `…/ARCHITECTURE_DECISION.md`

---

## One-sentence product shape

A Family Controls shield app whose loop is: pause at the door → Never Mind or timed Continue → re-shield → reward intentional choices and fewer/shorter windows, with goals and progression layered on those honest events.

---

## Why this design (lab verdict in plain language)

The lab proved intervention works; it did **not** prove open tracking.

| What works | What does not |
|---|---|
| Shield every launch of a tracked app (OS blocks until user acts) | Exact opens / launches |
| Never Mind vs Continue with custom chrome | Distinct sessions (Home vs Recents indistinguishable) |
| Timed **access window** after Continue | Host-readable Screen Time open/pickup dashboards |
| Re-shield at **window end** without mid-scroll yank | Guaranteed Continue-button delay API |
| L0→L2 friction copy from `continues_today` (App Group) | Notification deep-links into shielded apps |
| UUID + user-typed label as identity | Readable system display names from tokens |

**Implication:** Intervention *is* the sensing surface. Attention “knows” to intervene because the OS presents a shield — not because we counted launches.

Do not build v1 around DeviceActivityReport counters, pickup tallies, or claims like “we track every open.”

---

## Product principles for v1

1. **Intervention is the core** — the home screen and scoring exist to reinforce the shield loop, not the reverse.
2. **Primary behavior unit = access window** — started by Continue; ended by timer / deferred re-shield.
3. **Never Mind is a win** — intentional choice to back out; first-class rewarded event.
4. **Continue is a budgeted allowance** — timed, then re-shield; not unlock forever.
5. **Honest metrics only** — name signals by what the OS actually gives; never upgrade resolution in copy.
6. **Safe by default** — `on_window_end`, `unsafe_interrupt=off` (no mid-use yank as default).
7. **UX honesty** — shielded apps suppress notifications; say so; don’t design for notification bypass.
8. **Privacy-local first** — events and scores live on device (App Group + local store). No backend, auth, analytics SDKs, or AI in v1.

Aligned with `docs/PRODUCT_VISION.md`: intentionality over abstinence, improvement over perfection, positive reinforcement, honest metrics.

---

## Core loop (v1)

```text
User taps tracked app
  → Shield appears (L0 / L1 / L2 copy from continues_today)
  → Never Mind
       → stay blocked
       → log intentional_choice
       → reinforce (XP / streak eligibility)
  → Continue
       → clear that app’s shield
       → user must tap the app again (no auto-launch — lab fact)
       → start access_window(N minutes)
       → log continue + window_start
       → use app freely inside window (leave/return OK)
       → on_window_end: re-shield when safe
            (Attention active → apply; if Attention quit → deferred until host returns)
       → log window_end
  → Optional: usage_time checkpoint (~N min duration) — side signal only
```

**Not in the loop:** mid-scroll yank, open counters, live Screen Time dashboards.

---

## Behavior model & event taxonomy

All scoring, goals, streaks, and recaps consume **logged events** from App Group / local store — never Screen Time “opens.”

### Identity

| Field | Role |
|---|---|
| `id: UUID` | Primary key everywhere (events, goals, XP, streaks) |
| `userLabel: String` | User-typed name (e.g. “Gram”) — only reliable display name |
| `token: ApplicationToken` | Refreshable OS handle — not PK |
| `dateAdded: Date` | Onboarding / history |

**Token hygiene:** `refreshToken(for:)` via picker re-bind if a handle stops resolving. System picker checkboxes cannot be locked; uncheck of tracked apps is rejected; remove only in-app.

### Events (v1)

| Event | When | Counts toward |
|---|---|---|
| `intentional_choice` | Never Mind on shield | XP, Never Mind streak, “choices today” |
| `continue` | Continue on shield | continues_today (friction), Continue budget, XP (smaller or cost) |
| `access_window_start` | Immediately after Continue | windows started today |
| `access_window_end` | Timer end + successful/deferred re-shield | window duration, “shorter windows” XP |
| `usage_checkpoint` *(optional)* | DeviceActivity duration threshold while in/around window | soft insight only — not primary score |
| `shield_applied` / `reshield` | Host/extension applies shield | reliability / debug; not user-facing score |

### What we measure and show

Prefer:

- Intentional choices (Never Mind) today / streak
- Continues today / daily Continue budget remaining
- Access windows taken today
- Average / total window minutes today
- Goals hit (e.g. ≥N Never Minds, ≤M Continues, ≤K window minutes)

Avoid / ban in v1 UI and marketing:

- “Opened Instagram 47 times”
- “Sessions today”
- “We track every open”
- Host-side live screentime charts from Report APIs

---

## Friction ladder (Continues)

Proven trustworthy in M11 via App Group shared state.

| Level | Trigger (`continues_today` before this choice) | Shield behavior |
|---|---|---|
| L0 | 0 | Soft pause copy |
| L1 | 1–2 | Reminder / “is this intentional?” |
| L2 | ≥3 | Higher stakes / “are you sure?” copy + stronger iconography |

**Rules:**

- Continues bump level; Never Mind does not.
- Escalate **tone and stakes in copy**, not mechanical delay — there is **no** ShieldConfiguration API to delay the Continue button.
- Levels must work with host force-quit (extension reads App Group).
- Fallback if App Group unread: one static shield; progression still happens later via goals/XP in the host when events sync.

---

## Access windows & re-shield policy

### Window

- Started only by Continue.
- Duration: user-selectable presets in settings (e.g. 5 / 10 / 15 min); default short.
- Inside window: leave/return allowed; app stays unshielded until end.
- After Continue, OS does not auto-open the app — user taps again. Treat that extra tap as expected UX, not a bug.

### Re-shield (production default)

| Setting | v1 value |
|---|---|
| Mode | `on_window_end` |
| Unsafe interrupt | **off** |
| Mid-use yank | **not default** (`on_threshold` reserved for optional hard mode later) |

When Attention is background/quit at window end: **deferred re-shield** when Attention becomes active again. Document this: windows may run long if Attention isn’t opened — still honest, still safer than yanking.

### Usage-time (side signal)

Optional DeviceActivity duration checkpoint (~1 min or settings-chosen) can power a soft “you’ve been in for ~1 min” insight or log. It is **not** the main loop and must not be labeled as opens or session end.

---

## Goals, XP, streaks (layered on honest events)

v1 progression sits on the event log. Exact numbers can be tuned; the **sources** must not change.

### Suggested v1 scoring inputs

| Action | Direction | Example |
|---|---|---|
| Never Mind | Reward | +XP; counts toward daily intentional-choice goal |
| Continue | Neutral / soft cost | Spends 1 Continue budget; small XP or none |
| Short window (ended ≤ chosen length) | Reward | Bonus XP vs long window |
| Window under daily minute budget | Reward | Goal complete |
| Hitting daily Continue budget | Friction only | L2 copy; optional soft nudge in host |

### Streaks (v1)

- **Never Mind streak:** days with ≥1 intentional choice (or meeting a small daily Never Mind goal).
- Optional later: “under Continue budget” streak — only if it doesn’t punish legitimate use unfairly.

### Daily Continue budget

- Soft cap (e.g. 3–5 Continues/day per app or global — pick one for v1 simplicity: **global**).
- Over budget → copy escalates (already L2); host can show “budget used.”
- Do **not** hard-block Continue in v1 (shield must remain usable); budget is reinforcement + friction, not a lockout.

### Features that survive (from master plan)

Ship a thin slice in v1:

- Goals (daily)
- XP
- Streaks (Never Mind–based)
- Intentional choices + Continues + windows in a simple today view
- End-of-day or weekly **recap** (local, rules-based)

Defer:

- 7-day passive baseline before any shields (nice-to-have; not required to prove loop)
- Programs (7/14/21/30) as content packs
- Pro / StoreKit
- AI coaching
- Pattern detection backend
- Cross-platform parity

---

## Host app surfaces (v1)

Ugly-but-clear is fine; polish is not the goal of the first shippable build. Prefer one job per screen.

### Onboarding

1. Family Controls authorization (individual).
2. Pick distracting apps (`FamilyActivityPicker`).
3. Name each app (required non-empty labels).
4. Short explanation of the loop: shield → Never Mind or timed Continue → re-shield.
5. **Notification honesty:** shielded apps may delay or clear notifications; Attention is for reflexive checking, not critical-alert apps.
6. Choose default window length + optional daily Continue budget.
7. Apply shields.

Skip multi-week baseline gate for v1 unless product insists — intervention can start day one with conservative goals.

### Home (today)

- Today’s intentional choices, Continues, windows, window minutes.
- Continue budget remaining.
- Active streak + XP.
- Today’s goals with done/not done.
- List of tracked apps (userLabels) + quick “Shield all / pause Attention” (pause = clear shields with clear warning).

### Per-app detail

- Today counts for that UUID.
- Recent events (local).
- Re-bind token if broken.

### Settings

- Window duration presets.
- Continue budget.
- Friction copy tone (optional: default / firmer) — still L0–L2 ladder.
- Re-shield policy: fixed to safe default in v1 UI (advanced: show read-only explanation).
- Optional usage checkpoint on/off.
- Export / clear local data.
- Auth status + “Open Screen Time settings” help if revoked.

### Not in v1 host

- Live DeviceActivityReport “opens” dashboard as product truth.
- Mid-use yank as default toggle without heavy warning (if exposed at all, bury as experimental).

---

## Shield UX copy (product, not lab debug)

Title: `Attention — {userLabel}`  
Primary: **Never Mind**  
Secondary: **Continue**

| Level | Subtitle intent (examples) |
|---|---|
| L0 | Brief pause. What did you come here for? |
| L1 | You’ve continued already today. Still intentional? |
| L2 | Several Continues today. Sure this is worth a window? |

Avoid showing raw debug (`continues_today=3 (shared OK)`) in shipping builds; keep instrumentation in a hidden debug/log screen.

---

## Notifications (design constraint)

Lab (M12): while shielded, tracked-app notifications are suppressed; after Continue a backlog can appear; re-shield can clear Notification Center entries without tap.

**v1 policy:**

- Do not promise notification-driven intervention or bypass.
- Onboarding + Settings: clear copy that choosing an app for Attention means quieter notifications from that app while shielded.
- Recommend users not shield apps they need for time-critical alerts (banking OTPs, medical, work paging, etc.).
- Treat suppression as a **feature for reflexive checking**, with honesty about delayed/cleared alerts.

---

## Technical architecture (v1)

### Targets

- Host app (SwiftUI)
- ShieldConfigurationExtension
- ShieldActionExtension
- DeviceActivityMonitorExtension (optional checkpoints + future hard modes)
- App Group shared store

DeviceActivityReport: **omit from product spine**. Lab showed display-only / not host-readable for counts. Do not depend on it for scoring.

### State ownership

| Concern | Where |
|---|---|
| Tracked apps (UUID, label, token) | App Group |
| continues_today / never_mind_today | App Group (extension + host) |
| access_window end timestamp | App Group |
| Event log, XP, streaks, goals | Local store in host (SwiftData or equivalent); extensions write append-only events to App Group; host ingests on launch/active |
| Shield application set | ManagedSettingsStore |

### Reliability expectations (from M12)

Must handle: force-quit, reboot, lock, rapid reopen, app switcher, airplane mode, local date rollover, auth revoke.

**Open risk:** full-day field reliability was **SKIPPED** in lab. v1 should include a short dogfood checklist (all-day wear) before calling reliability “proven.”

### Distribution risk

Family Controls **distribution** entitlement requires Apple approval for the app **and each** Screen Time extension bundle ID. Dev entitlement ≠ TestFlight/App Store. Schedule this as a critical path item, not an afterthought.

---

## Explicit non-goals (v1 spine)

Do not build these as the product foundation:

1. Open / session counters from DeviceActivityReport or pickups  
2. Host-side live screentime dashboards from Report APIs  
3. Mid-use yank as default re-shield  
4. Product claims of tracking every open  
5. Notification-bypass or notification-as-intervention design  
6. Backend, accounts, subscriptions, analytics SDKs, AI coach  
7. Android parity (paused; separate later)  
8. Polished marketing UI over observable behavior  

---

## Success criteria for v1

v1 is successful if a dogfooding user can say:

1. Every tracked app hits a clear pause before entry.  
2. Never Mind feels like a real win (visible in today stats / XP / streak).  
3. Continue grants a predictable timed window, then the door closes again without yanking mid-scroll.  
4. More Continues in a day makes the pause feel firmer (copy), without broken buttons or missing state.  
5. Nothing in the UI claims opens/sessions we cannot measure.  
6. They understand notification side effects before committing apps.

---

## Suggested build sequence (post-lab)

Order mirrors dependency, not polish:

1. **Product shell** — new app target/repo boundary as decided; Family Controls + App Group; auth.  
2. **Tracked apps** — picker, UUID + labels, token refresh, shield apply/clear.  
3. **Shield loop** — configuration + actions; Never Mind / Continue; event writes.  
4. **Access windows** — duration presets; `on_window_end` re-shield + deferred path.  
5. **Friction ladder** — L0–L2 from continues_today.  
6. **Host today + goals/XP/streak** — ingest events; reinforce.  
7. **Onboarding honesty** — notifications + loop explanation.  
8. **Dogfood / all-day** — close the M12 skip; fix reliability gaps.  
9. **Family Controls distribution** entitlement requests (parallel once bundle IDs stable).  
10. Only then: recaps polish, programs, budgets tuning, optional usage checkpoints as insights.

---

## Mapping to master-plan questions

| # | Question | v1 answer |
|---|---|---|
| 1 | Select individual apps? | Yes — picker + UUID/label |
| 2 | Know when to intervene? | Yes — shield at door (not open detection) |
| 3 | Usable friction? | Yes — custom shield + ladder copy |
| 4 | Back out cleanly? | Yes — Never Mind |
| 5 | Continue cleanly? | Yes — timed window; extra tap to enter |
| 6 | Meaningful usage end? | Partial — window end, not session end |
| 7 | Intensity adapt? | Yes — L0–L2 from Continues |
| 8 | Reliable behavioral data? | Yes — choices, Continues, windows (local) |
| 9 | Survive background/reboot? | Shield yes; re-shield deferred if host quit |
| 10 | Store-distributable? | Plausible; Family Controls distribution approval required |

Red lines from the master plan are **not** hit: targeting, intervention UX, and a meaningful unit (`access_window`) all exist.

---

## Open decisions (product, not architecture)

Resolve before or during early build — none reverse the Access Window Model:

1. Global vs per-app Continue budget  
2. Default window length and whether user can change mid-day  
3. Exact XP weights and streak definition  
4. Whether “Pause Attention” (clear all shields) exists and how loudly it’s warned  
5. Whether optional hard mode (`on_threshold` yank) ships behind a flag  
6. New bundle ID / App Group for product vs evolve the prototype project  

---

## Document control

- **Depends on:** human acceptance of `prototypes/ios/AttentionAPITest/docs/ARCHITECTURE_DECISION.md` (Access Window Model).  
- **Does not authorize:** implementing production scoring/home in the API lab until that acceptance and an explicit build kickoff.  
- **Android:** out of scope until Android lab reaches its architecture verdict.
