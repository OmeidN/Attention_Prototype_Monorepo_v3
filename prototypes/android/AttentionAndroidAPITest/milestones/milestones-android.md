# Android Milestones

## Context for whoever (or whatever) picks this up

One deliberate platform difference from iOS, worth understanding before M1.1:

**Android does not have iOS's app-identity restriction.** `PackageManager` gives
you the real app name (`applicationInfo.loadLabel(pm)`) and real icon
(`applicationInfo.loadIcon(pm)`) directly for any installed package — there is no
sealed-token privacy layer like iOS's `ApplicationToken`. That means the Android
app-selection screen can show the user's actual selected apps ("TikTok",
"Instagram") with their real icons immediately.

**Decision made: do not port iOS's "type the app's name yourself" screen to
Android.** That screen exists on iOS purely to work around an API limitation that
doesn't exist here — copying it to Android would be downgrading a strictly better
experience for the sake of a needless cross-platform match. If you want an
"optional nickname" feature later, fine, but it's a nice-to-have, not a
requirement, and should never block onboarding the way the iOS naming step
intentionally does.

Work top to bottom. Each milestone has a **Cursor prompt** (paste it in), **Manual
steps** (things only you can do, usually in Android Studio's GUI or on a physical
device), and **Done when**. `UsageStatsManager` behaves inconsistently on emulators —
test on a real device from M0.1 onward, and ideally on more than one OEM (Samsung,
Pixel, Xiaomi) before trusting the numbers.

---

## Phase 0 — Feasibility prototype

### M0.1 — Project skeleton + usage-access permission flow

**Cursor prompt:**
> This repo already has a Gradle skeleton (`settings.gradle.kts`, `app/`, `core/`,
> `usagestats/`). Fill in `app/src/main/java/.../MainActivity.kt` with a single Compose
> screen with a button that checks whether usage-access is granted (via
> `AppOpsManager.checkOpNoThrow` for `OPSTR_GET_USAGE_STATS`) and, if not, launches
> `Settings.ACTION_USAGE_ACCESS_SETTINGS` so the user can grant it manually — this
> permission cannot be requested via a normal runtime dialog.

**Manual steps:**
1. Open `android/` in Android Studio, let it sync Gradle.
2. Plug in a physical device (enable USB debugging), run the app.
3. Tap the button, get sent to Settings, manually toggle "Attention" on in the usage
   access list, come back to the app.

**Done when:** the app can detect that usage access is granted after you toggle it on.

---

### M0.2 — Query usage events for real open counts

**Cursor prompt:**
> In the `usagestats` module, implement `UsageStatsRepository.getAppOpenCounts(start:
> Long, end: Long): Map<String, Int>` using `UsageStatsManager.queryEvents(start,
> end)`, counting `UsageEvents.Event.MOVE_TO_FOREGROUND` events grouped by
> `event.packageName`. Add a debug screen in the app module that lets me pick a time
> range (e.g., "today," "last hour") and see the resulting counts per installed app
> I've used.

**Manual steps:**
1. Run on-device, open TikTok/Instagram/YouTube (or whatever's installed) a known
   number of times over the next 30 minutes — literally count your own opens as
   ground truth.
2. Compare the app's reported count to your manual count.

**Done when:** the reported count matches your manual count (or you've logged the
discrepancy and a guess at why — e.g., multitasking/split-screen can double-count
foreground events on some OEMs).

---

### M0.3 — `queryEvents` vs `queryUsageStats` sanity check

**Cursor prompt:**
> Add a second debug view showing `UsageStatsManager.queryUsageStats(INTERVAL_DAILY,
> start, end)` output (total time in foreground, last time used) side by side with
> the `queryEvents`-based open count for the same apps, so I can see both side by side
> and confirm `queryEvents` is the right primitive for "sessions" while
> `queryUsageStats` is better for "total time."

**Done when:** you can see both numbers on one screen for the same app/time range.

---

### M0.4 — Background collection: polling vs. service vs. WorkManager

**Cursor prompt:**
> Implement a `WorkManager` periodic job (minimum interval Android allows, ~15
> minutes) that calls `getAppOpenCounts` for the period since it last ran and appends
> results to Room storage in the `core` module. Log each run's timestamp so I can
> check for gaps later. Separately, stub out (but don't fully wire up yet) a
> foreground service alternative, and add a short code comment on the trade-off
> (immediacy vs. persistent notification vs. battery) so I can decide which to use for
> the real-time shield in Phase 1.

**Manual steps:**
1. Run the app, leave your phone alone for several hours doing normal things.
2. Check the Room-stored run log for gaps, especially after the screen has been off
   for a while or the device entered Doze mode.

**Done when:** `feasibility-notes.md` has a real answer for "how much delay/gap
should I expect from a 15-minute WorkManager job on my device."

---

### M0.5 — Real-time foreground-app detection for the shield

**Cursor prompt:**
> Prototype two approaches side by side in throwaway debug code (not production
> paths yet):
> 1. Fast polling (e.g., every 1–2 seconds while the app is running) of
>    `UsageStatsManager` to detect the moment a tracked app comes to foreground.
> 2. An `AccessibilityService` that observes window state changes for the tracked
>    package names.
> For each, report: detection latency (how long after the real app open did we
> notice), and battery/CPU cost if you can observe it (Android Studio's Profiler).
> Be direct about the Play Store review implications of shipping an
> `AccessibilityService` for this purpose versus polling — don't soften this, I need
> to make a real trade-off decision here.

**Manual steps:** use Android Studio's Profiler while manually opening/closing tracked
apps repeatedly to compare the two approaches' latency and cost.

**Done when:** `feasibility-notes.md` records which approach you're committing to and why.

---

### M0.6 — "First unlock of the day" detection

**Cursor prompt:**
> Investigate whether `ACTION_USER_PRESENT` (broadcast when the device is unlocked)
> combined with a simple "have we already logged today's first unlock" check in Room
> is sufficient to detect the morning-goal trigger from the product spec. Implement it
> as a `BroadcastReceiver` and log each firing.

**Done when:** you've confirmed on-device that unlocking your phone in the morning
reliably fires the receiver.

---

## Phase 1 — MVP (free tier) — start only after Phase 0 is fully logged

### M1.1 — Onboarding + baseline

**Why this milestone matters:** this is the direct counterpart to iOS's M1.1, and
the two should look deliberately different — see the Context note above. Getting
this right here means the Android selection screen is simpler than iOS's, not
because it was rushed, but because the platform genuinely allows it.

**Cursor prompt:**
> Build a two-step Compose onboarding flow (no naming step — see Context above for
> why):
>
> 1. **App selection** — list installed apps via `PackageManager`, showing each
>    app's real `loadLabel` and `loadIcon` directly, letting the user multi-select.
>    Persist each as `{ id: UUID, packageName: String, dateAdded: Date }` in Room via
>    the `core` module — `packageName` is stable and safe to use directly as the
>    identifying key here, unlike iOS's token.
> 2. **Baseline period screen** — explain 7 days of passive observation, then persist
>    a `baselineStartDate`. No shields/prompts should fire during this window.

**Manual steps:** run on-device for a real week if you want genuine baseline data, or
mock the date for faster iteration.

**Done when:** the app remembers your selection (with real app names/icons showing
correctly) and the baseline window across launches.

### M1.2 — Scoring engine

**Cursor prompt:**
> Implement the scoring engine in the `core` module (pure Kotlin, no Android
> dependencies) exactly per `docs/scoring-spec.md`. Write JUnit tests with the same
> fixture inputs used on iOS (ask me for them, or generate matching ones) so both
> platforms can be verified to produce identical scores from identical input.

**Done when:** `./gradlew :core:test` passes.

### M1.3 — Friction ladder (shield UI)

**Cursor prompt:**
> Using the real-time detection approach chosen in M0.5, show a full-screen Compose
> "shield" activity/overlay when a tracked app is about to open, with three levels
> keyed off today's open count: level 0 (no shield), level 1 (plain reminder +
> Continue), level 2 (intentionality prompt with a short delay before Continue is
> tappable).

**Done when:** repeated opens of a tracked app visibly escalate the shield on-device.

### M1.4 — Intentional Choice logging

**Cursor prompt:**
> When the user dismisses a shield instead of continuing, write an Intentional
> Choice event to Room, award XP per `scoring-spec.md`, and update streak-eligibility
> for the day.

### M1.5 — Home screen

**Cursor prompt:**
> Build the Compose home screen: Attention Score, streak, today's goals with
> completion state, and a 7-day trend chart (a simple Canvas-based bar chart is fine,
> no need for a charting library yet). Pull all data from `core`, no hardcoded values.

### M1.6 — Local persistence

**Cursor prompt:**
> Confirm all state (scores, XP, goals, events) is fully modeled in Room with proper
> migrations, not left in SharedPreferences/in-memory state from earlier milestones.

---

## Phase 2 — Pro tier (outline — flesh out once Phase 1 ships)

- Long-term history + Room migration plan.
- Pattern detection implementing the structured pattern objects from
  `scoring-spec.md`.
- Weekly Attention Plan generator (rules-based first).
- Programs (7/14/21/30-day) driven by shared JSON content in `shared/`.
- Google Play Billing integration for Pro pricing.

## Later — AI Coach

- Define the structured-insight payload sent to a coach model (see
  `scoring-spec.md`) — raw usage logs should never leave the device.
- Decide on-device vs. backend inference before writing any networking code.
