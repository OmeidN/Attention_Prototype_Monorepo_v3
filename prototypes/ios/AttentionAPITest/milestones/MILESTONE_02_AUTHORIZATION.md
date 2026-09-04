# M02 — Family Controls Authorization

**Goal:** add the Family Controls capability, request **individual** authorization, show status, log errors. Pass only after a physical iPhone confirms.

**User-visible change:** Setup shows `notDetermined / approved / denied` (or the actual `AuthorizationStatus`) and a Request button.

**Prerequisite:** M01 PASS. Paid Apple Developer account. Physical iPhone — **simulator is not acceptable for PASS**.

**Agent rule:** implement this milestone only. Do not present `FamilyActivityPicker` yet (M03). Do not apply shields (M04).

## Out of scope

- App selection, naming screen, UUID store → **M03**
- ManagedSettings shield → **M04**
- Waiting for App Store Family Controls *distribution* approval. Local/dev signing generally works without App Review; **TestFlight/App Store** is the process that needs Apple's entitlement approval. Verify current Apple policy if the request fails. Do not block the prototype on distribution approval.

## Context

Individual authorization (`AuthorizationCenter.shared.requestAuthorization(for: .individual)`) is the on-device Screen Time path. Without it, every later API is theatre. Failures (entitlement missing, wrong signing team, child account) must be visible on the phone, not only in Xcode's console.

## Steps for the agent

1. Enable Family Controls on the app target. Record the `.entitlements` file name in TEST_RESULTS.
2. Setup: read `AuthorizationCenter.shared.authorizationStatus`, refresh on appear. Button: request `.individual`. Wrap in do/catch.
3. Log start, success, failure (`localizedDescription`), tag `ATTN-M02`. **Surface the error as on-screen text** so the human does not need the console.
4. Denied / error: on-screen text, not a crash. Do not retry in a loop.
5. No picker, no `ManagedSettingsStore` writes.

## Agent exit checks

- [ ] Device-capable build (or generic iOS device build) succeeds
- [ ] Entitlement present
- [ ] Grep `FamilyActivityPicker`, `shield.applications` → zero hits

## Physical-device checklist (human)

- [ ] Install on a physical iPhone signed with the Family Controls capability
- [ ] Cold launch: status before tapping Request
- [ ] Request: complete the system sheet. Record approved vs denied
- [ ] Kill app, reopen: status persists
- [ ] If request fails: screenshot/error text into TEST_RESULTS (signing vs user deny)
- [ ] Confirm this did **not** work as a substitute on Simulator (optional 1-minute check)
- [ ] PASS only with device evidence

## Definition of done

- [ ] Individual authorization requested and displayed
- [ ] Errors logged
- [ ] Human confirmed on iPhone

**Next:** [M03 — App Selection and Persistence](./MILESTONE_03_APP_SELECTION_AND_PERSISTENCE.md)
