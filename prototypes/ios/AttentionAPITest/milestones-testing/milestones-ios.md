# iOS Milestones

## Context for whoever (or whatever) picks this up

Two settled facts from feasibility research shape several milestones below —
Cursor, read this before touching M0.4, M0.5, or M1.1:

1. **`ApplicationToken` never exposes an app's name or bundle ID to your code.**
   `FamilyActivityPicker` returns opaque sealed tokens. The only way the user sees
   "TikTok" is via Apple's own `Label(token)` view — your code never gets the
   string. **Decision made: we accept this and are building our own "name your
   apps" screen right after the picker**, where the user types a label like
   "TikTok" themselves. This is intentional UX, not a workaround to hide — design
   for it, don't try to route around it.
2. **`ApplicationToken` is not reliably permanent.** Real developers have reported
   iOS silently reissuing new tokens for the same app after OS/app updates, with no
   error thrown — stored tokens can quietly stop matching. **Decision made: our own
   generated ID (not the raw token) is the primary key for a tracked app in
   storage.** The token is a live handle we refresh from a fresh picker session
   when needed, with a fallback path when a stored token stops resolving.

Why this matters enough to write down: skipping either of these leads to visible
bugs later — either "we can't show the app's real name anywhere" (should never come
up, because we're not trying to) or "the user's whole history vanished after an iOS
update" (a real, previously-reported failure mode we're deliberately avoiding by
never depending on token permanence).

Work top to bottom. Each milestone has a **Cursor prompt** (paste it in), **Manual
steps** (things only you can do, usually in Xcode's GUI or on a physical device), and
**Done when** (how you'll know it worked). Screen Time APIs largely don't behave
correctly in the Simulator — plan to test on your own iPhone from M0.1 onward.

---

## Phase 0 — Feasibility prototype

### M0.1 — Project skeleton via XcodeGen

**Cursor prompt:**
> Using the `ios/project.yml` XcodeGen spec in this repo, generate the Swift source
> stubs it references: an `AttentionApp.swift` App entry point, a `ContentView.swift`
> with a placeholder screen, and an `AttentionCore` Swift package with an empty
> `ScoringEngine.swift`. Keep it minimal — no networking, no persistence yet.

**Manual steps:**
1. Install XcodeGen if you don't have it: `brew install xcodegen`.
2. From `ios/`, run `xcodegen generate` to produce `Attention.xcodeproj`.
3. Open the generated project in Xcode, select your development team under
   Signing & Capabilities.
4. Plug in your iPhone, select it as the run destination, and confirm the
   placeholder screen runs on-device.

**Done when:** the app launches on your physical iPhone and shows the placeholder screen.

---

### M0.2 — Family Controls entitlement + authorization request

**Cursor prompt:**
> Add a button on `ContentView` that calls
> `AuthorizationCenter.shared.requestAuthorization(for: .individual)` and prints/logs
> the result. Wrap it in do/catch and surface any error as on-screen text so I can see
> it without checking the console.

**Manual steps:**
1. In Xcode, select the app target → Signing & Capabilities → "+ Capability" →
   add **Family Controls**.
2. Run on your device, tap the button, and approve the system permission prompt.
3. If you see an entitlement error, check that your Apple ID/team supports Family
   Controls for local development (this generally works for personal/dev use without
   waiting for App Review — only App Store/TestFlight distribution needs approval;
   verify current policy in Apple's developer docs since this can change).

**Done when:** the authorization call returns success and you see the confirmation
in the app, without needing Xcode's console open.

---

### M0.3 — App picker (`FamilyActivityPicker`)

**Cursor prompt:**
> Add a `FamilyActivityPicker` (SwiftUI, from the `FamilyControls` framework) behind a
> button, bound to a `@State private var selection = FamilyActivitySelection()`.
> After the user picks apps, print how many `ApplicationToken`s, `CategoryToken`s, and
> `WebDomainToken`s came back — just the counts, since Apple doesn't expose the
> underlying app names/bundle IDs to your app directly.

**Manual steps:**
1. Run on-device, tap through the picker, select TikTok/Instagram/YouTube (or
   whatever you have installed).
2. Confirm you get back non-zero token counts.

**Done when:** you've selected apps and can confirm (via the printed counts) that the
picker returned tokens — and you've personally confirmed you cannot read the app's
name back out of a token in your main app process (this is expected — note it in
`feasibility-notes.md`).

---

### M0.4 — DeviceActivityMonitor extension + threshold events

**Cursor prompt:**
> Set up a `DeviceActivityMonitor` app extension target. Implement a schedule using
> `DeviceActivitySchedule` for "all day, every day" and an event using
> `DeviceActivityEvent` with a threshold of, say, 3 occurrences of the selected apps
> opening (`applications: selection.applicationTokens`, `threshold: DateComponents()`
> — look up the exact threshold API for "N opens" vs. "N minutes", since `threshold`
> is duration-based, not count-based, in some SDK versions; flag this precisely in
> your response since it affects whether "3 opens" is even expressible here). Start
> monitoring with `DeviceActivityCenter().startMonitoring(...)` and implement
> `intervalDidStart`, `intervalDidEnd`, and `eventDidReachThreshold` in the extension,
> logging each callback (e.g., to a shared App Group `UserDefaults` so the main app
> can read it).
>
> **Important:** confirm for me explicitly whether `DeviceActivityEvent.threshold` can
> represent "opened N times" or only "used for N minutes" — this is the single most
> important feasibility fact for this whole project and I need a direct, unhedged
> answer based on the actual API, not a guess.

**Manual steps:**
1. In Xcode: File → New → Target → "Device Activity Monitor Extension." Give it an
   App Group shared with the main app (Signing & Capabilities → App Groups, on both
   targets).
2. Build and run; open one of your selected apps several times over the next hour
   with the phone actually locked/unlocked normally (not just left open in Xcode).
3. Check the shared App Group storage from the main app to see if/when callbacks fired.

**Done when:** you can say definitively, in `feasibility-notes.md`, whether "opens" or
only "duration" is the countable unit on iOS — this determines the entire scoring
model's iOS implementation.

---

### M0.5 — DeviceActivityReport: can you extract a number?

**Cursor prompt:**
> Add a `DeviceActivityReport` extension target and a minimal
> `DeviceActivityReportScene` that tries to surface a single number (e.g., total
> activity count for the selected apps today) to its `content` view. Then check
> whether that numeric value is readable from the **host app** (outside the
> extension's sandboxed view) at all, or whether it can only be *displayed*, never
> read programmatically by your own code. Report back plainly which of these is true
> — this is a known point of confusion in Apple's docs and I need the concrete answer
> from what you find while implementing it, not the general documentation description.

**Manual steps:**
1. Add the extension target in Xcode (File → New → Target → "Device Activity Report
   Extension"), same App Group as before.
2. Embed the report view in `ContentView` via `DeviceActivityReport(...)` and run
   on-device.
3. Visually confirm whether a number renders in the report UI at all.

**Done when:** `feasibility-notes.md` states clearly: "the host app can [/cannot] read
a numeric open-count out of DeviceActivityReport; the only path to a number is
[whatever you found]."

---

### M0.6 — Background reliability over a full day

**Manual steps only (no Cursor needed here):**
1. Leave the app + extensions installed and just use your phone normally for a full
   day, deliberately opening your selected apps at scattered times (morning, midday,
   night).
2. At the end of the day, check the logs/App Group data for gaps — did every open
   get caught, or did some get missed (e.g., after the phone was in Doze-like states,
   or after the app extension was memory-purged)?

**Done when:** you have a rough reliability percentage (even approximate) recorded in
`feasibility-notes.md`.

---

## Phase 1 — MVP (free tier) — start only after Phase 0 is fully logged

### M1.1 — Baseline period + onboarding (includes the naming screen)

**Why this milestone matters:** this is where the token-name and token-stability
facts from the Context section above stop being abstract and become a real screen a
real user has to get through. Get the data model wrong here and every later
milestone (scoring, weekly reports, Pro pattern detection) inherits the mistake,
since they all display copy keyed off whatever we call each app.

**Cursor prompt:**
> Build a three-step onboarding flow:
>
> 1. **App selection** — reuse the `FamilyActivityPicker` from M0.3.
> 2. **Naming screen**, shown immediately after the picker closes, one row per
>    selected app in the same order they were picked: a generic placeholder icon +
>    a text field with placeholder text like "e.g. TikTok". Require every field to
>    be non-empty before "Continue" is enabled — show an inline error if the user
>    tries to proceed with a blank field, don't just silently block the button.
>    Persist each app as `{ id: UUID, userLabel: String, token: ApplicationToken,
>    dateAdded: Date }`, where `id` — not `token` — is the primary key used
>    everywhere else in the app (scoring, streaks, weekly reports). Add a
>    `refreshToken(for id:)` path that re-derives the token from a fresh picker
>    selection, for use if a stored token stops resolving later (see the Context
>    note on token instability above — don't skip this just because it won't be
>    exercised immediately).
> 3. **Baseline period screen** — explain we'll passively observe for 7 days, then
>    persist a `baselineStartDate`. No interventions should fire during this window.

**Manual steps:** run on-device for a real week if you want genuine baseline data, or
mock the date for faster iteration. Also manually test the inline-error path by
trying to continue with a blank name field.

**Done when:** the app remembers your selection, your typed names, and the baseline
window across launches — and a blank name field visibly blocks continuing rather
than silently failing later.

### M1.2 — Scoring engine

**Cursor prompt:**
> Implement `ScoringEngine` in `AttentionCore` exactly per `docs/scoring-spec.md`.
> Write unit tests using hand-built fixture inputs (don't wait for real device data)
> covering: normal day, day with zero baseline (edge case — avoid divide by zero),
> and a day with a full streak-breaking miss.

**Done when:** `swift test` passes for `AttentionCore`.

### M1.3 — Friction ladder (shield UI)

**Cursor prompt:**
> Using `ManagedSettings` and a custom `ShieldConfiguration`/`ShieldActionExtension`,
> implement three friction levels keyed off the day's open count for a given app:
> level 0 (no shield), level 1 (shield with a plain reminder + "Continue" button),
> level 2 (shield with an "Are you sure?" intentionality prompt with a short delay
> before "Continue" becomes tappable). Wire the level selection to
> `ManagedSettingsStore().shield.applications`.

**Manual steps:** add the `Shield Configuration Extension` and `Shield Action
Extension` targets in Xcode; test by opening a selected app enough times to escalate
through levels on-device.

**Done when:** you can visibly see the shield escalate after repeated opens in one day.

### M1.4 — Intentional Choice logging

**Cursor prompt:**
> When the shield action extension reports the user chose "don't continue," write an
> Intentional Choice event (timestamp, app token) into shared storage, and have
> `AttentionCore` pick it up to award XP and update the day's streak-eligibility.

**Done when:** dismissing a shield visibly increments XP/score on next app launch.

### M1.5 — Home screen

**Cursor prompt:**
> Build the SwiftUI home screen: Attention Score (large number), current streak,
> today's goals with completion state, and a simple 7-day bar trend using `Charts`.
> Pull all data from `AttentionCore`, no hardcoded numbers.

### M1.6 — Local persistence

**Cursor prompt:**
> Replace any in-memory/UserDefaults-only storage with SwiftData models for daily
> stats, XP events, and goals, migrating existing shared-storage data on first launch.

---

## Phase 2 — Pro tier (outline — flesh out once Phase 1 ships)

- Long-term history storage + SwiftData migration plan.
- Pattern detection implementing the structured pattern objects from
  `scoring-spec.md`.
- Weekly Attention Plan generator (rules-based first, before any AI Coach).
- Programs (7/14/21/30-day) driven by shared JSON content in `shared/`.
- StoreKit 2 subscription integration for Pro pricing.

## Later — AI Coach

- Define the structured-insight payload sent to a coach model (see
  `scoring-spec.md`'s pattern JSON) — raw usage logs should never leave the device.
- Decide on-device vs. backend inference before writing any networking code.
