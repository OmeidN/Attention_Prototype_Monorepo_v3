# M03 — App Selection, Naming, and Persistence

**Goal:** pick apps with `FamilyActivityPicker`, then immediately **name them**, and persist a stable identity that does not depend on token strings or token permanence.

**User-visible change:** picker → naming screen (one text field per selected app) → counts plus the typed labels on Experiments. Blank names cannot continue.

**Prerequisite:** M02 approved on the physical iPhone.

**Agent rule:** implement this milestone only. Do not apply or remove shields.

## Settled decisions (do not reverse)

1. **You never get the real app name or bundle ID from `ApplicationToken`.** Do not try. Apple's `Label(token)` may be used *inside the picker UI only*. Everywhere else, show the **user-typed label**.
2. **Primary key is `id: UUID`, not the token.** Persist `{ id: UUID, userLabel: String, token: ApplicationToken, dateAdded: Date }`. The token is a live handle.
3. Implement `refreshToken(for id:)` now: re-run (or re-bind) a picker session and map the new token onto an existing `id` when a stored token stops resolving. Do not skip this because it will not be exercised today — silent token reissue after iOS/app updates is a reported failure mode. If history is keyed by raw token, it vanishes.

## Out of scope

- `ManagedSettingsStore.shield` → **M04**
- Shield UI extensions → **M05–M06**
- 7-day baseline / no-intervention onboarding window → after the iOS verdict, not this lab
- Scoring, home screen, SwiftData product DB, XP

## Context

Question 1 of the master plan: can the user select individual distracting apps? The picker returns opaque tokens plus optional category/web-domain tokens. Counts prove the picker works. Typed names prove we can talk about "TikTok" in our UI without lying that we read it from Apple.

## Steps for the agent

1. Experiments: present `FamilyActivityPicker` bound to `FamilyActivitySelection()`.
2. After the picker closes with a non-empty `applicationTokens` set, show a **naming screen** immediately, one row per selected app **in picker order**: generic placeholder icon (not a fake TikTok logo) + text field placeholder `e.g. TikTok`. Require every field non-empty before Continue. Inline error if they try to proceed blank — do not only disable the button with no explanation.
3. Persist each tracked app as `{ id, userLabel, token, dateAdded }` in App Group `UserDefaults` (create `group.com.attention.apitest` or similar now if M04+ will need it — document the suite id). Restore on launch. **Never key maps by token.**
4. Show on Experiments: `ApplicationToken` count, `CategoryToken` count, `WebDomainToken` count, plus the list of `userLabel`s. Attention cares about apps; log extra token types but do not require categories.
5. Add `refreshToken(for: UUID)` (UI can be an Experiments "Replace token for this label" that opens the picker). Log `token_refreshed` / `token_refresh_failed`.
6. Log `selection_changed` with counts + labels (not token dumps), tag `ATTN-M03`.
7. If authorization was revoked, show M02 status — do not crash.

## Agent exit checks

- [ ] Build succeeds
- [ ] Grep storage code: tracked-app PK is UUID, not `ApplicationToken` as the dictionary key
- [ ] Naming screen exists; blank field shows an inline error
- [ ] `refreshToken(for:)` exists
- [ ] Grep `ManagedSettingsStore`, `DeviceActivityCenter` → zero hits

## Physical-device checklist (human)

- [ ] Pick TikTok/Instagram/YouTube (or whatever is installed). Confirm non-zero application token counts
- [ ] Personally confirm you **cannot** read the app's name out of the token in the main app process (expected). Note that in TEST_RESULTS
- [ ] Type labels. Try Continue with one field blank — inline error, no silent fail
- [ ] Force-quit, reopen — labels + counts still there
- [ ] Reboot iPhone, reopen — still there
- [ ] Clear selection, relaunch — empty
- [ ] Record PASS/FAIL in TEST_RESULTS

## Definition of done

- [ ] Picker + naming + UUID-keyed persistence
- [ ] Token refresh path exists
- [ ] Human confirmed names are not readable from tokens
- [ ] No shielding yet

**Next:** [M04 — Basic Shielding](./MILESTONE_04_BASIC_SHIELDING.md)
