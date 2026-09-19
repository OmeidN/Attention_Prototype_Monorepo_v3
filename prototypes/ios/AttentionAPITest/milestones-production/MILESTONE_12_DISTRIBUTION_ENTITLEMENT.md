# P12 — Distribution Entitlement

**Goal:** get on the path to TestFlight / App Store by requesting **Family Controls distribution** for the host **and every** Screen Time extension bundle ID. Confirm provisioning includes the entitlement.

**User-visible change:** none required (process milestone). Optional in-app “Build: TestFlight candidate” debug label.

**Prerequisite:** Bundle IDs stable (ideally after P03 extensions exist). P11 dogfood underway or done.

**Agent rule:** this is mostly human/Apple Account Holder work. Agent prepares a checklist, verifies entitlements in the Xcode project, and documents request status — does not claim App Store approval.

## Out of scope

- Shipping marketing site / Pro / AI  
- Recap feature → **P13**  
- Changing product architecture  

## Context

Apple: development Family Controls ≠ distribution. Request distribution for **each** App ID that uses the capability (host, Shield Configuration, Shield Action, Device Activity Monitor, etc.). Approvals can lag, especially for extensions.

## Steps for the agent

1. Inventory all product bundle IDs + which need Family Controls / App Groups in `docs/PRODUCTION_RESULTS.md`.
2. Ensure each target’s entitlements file matches.
3. Write a human runbook: Account Holder → Capability Requests → Family Controls distribution per bundle ID; regenerate profiles; archive.
4. If archive fails, capture the exact provisioning error.
5. Tag docs `ATTN-P12`. No new app features.

## Agent exit checks

- [ ] Bundle ID inventory complete
- [ ] Entitlements files reviewed for each target
- [ ] Runbook exists in `docs/` or this milestone’s notes section in `PRODUCTION_RESULTS.md`

## Physical-device / human checklist

- [ ] Distribution requests submitted for **host + each extension**
- [ ] Request status recorded (Submitted / Assigned / Denied)
- [ ] After approval: archive succeeds with Family Controls in profile
- [ ] Optional: TestFlight upload smoke (install on device)
- [ ] Record in `PRODUCTION_RESULTS.md`

## Definition of done

- [ ] Requests submitted (minimum) or fully approved (ideal)
- [ ] Archive/TestFlight status recorded
- [ ] Human confirmed

**Next:** [P13 — Recap and v1 Freeze](./MILESTONE_13_RECAP_AND_V1_FREEZE.md)
