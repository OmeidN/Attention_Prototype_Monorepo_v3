# P00 — Product Shell

**Goal:** establish the **production Attention app** identity (bundle IDs, App Group, Family Controls, host shell) separate from the lab experiment UI. Prove auth request works on device.

**User-visible change:** a minimal host app (not the Experiments dashboard) showing authorization status, milestone banner `P00`, and an ISO timestamp. No picker/shields yet.

**Prerequisite:** Lab M00–M12 PASS; human has accepted Access Window Model direction in `ATTENTION_V1_DESIGN_PLAN.md`.

**Agent rule:** implement this milestone only. Do not port Experiments tabs, DeviceActivityReport, or scoring. Decide and record product vs lab bundle boundary in `docs/PRODUCTION_RESULTS.md`.

## Out of scope

- App picker / naming → **P01**
- Shields / extensions product chrome → **P02–P03**
- XP, goals, onboarding polish → **P07+**

## Context

Lab app `com.attention.apitest` proved APIs. v1 needs a product shell users can dogfood without an experiment console. Open decision from the design plan: new bundle ID / App Group vs evolve the prototype project — **pick one in this milestone and stick to it**.

Recommended default (unless human overrides):

- Host: `com.attention.app` (or keep `com.attention.apitest` only if explicitly chosen)
- App Group: matching `group.com.attention…`
- Extensions: same family of bundle IDs, Family Controls on **each**
- Product UI: Home placeholder + Setup/Auth — no “Experiments / M08 Truth” UI

Reuse Shared code patterns from the lab where helpful; do not leave lab-only debug as the primary UX.

## Steps for the agent

1. Create or carve the **product** host target (and empty extension stubs only if signing requires them later — prefer adding real extensions in P03).
2. Enable Family Controls + App Groups on the host; record Team ID, bundle IDs, App Group in `docs/PRODUCTION_RESULTS.md`.
3. SwiftUI shell: app name **Attention**, `P00 — Product Shell`, auth status (`notDetermined` / `approved` / denied), **Request authorization** button for `.individual`, ISO timestamp on appear/active.
4. Instrument: `ATTN-P00` logs with timestamps for auth request success/failure.
5. Create `docs/PRODUCTION_RESULTS.md` with environment table + P00 row (awaiting human).
6. Create/update a short `Journal-Context/PRODUCTION_PROGRESS.md` pointing at P00 as current.

## Agent exit checks

- [ ] Product host builds for an iOS destination
- [ ] Grep product primary UI for `ExperimentsView` / `M08` / `Truth` → zero hits (lab UI not primary)
- [ ] Family Controls + App Group entitlements present on host
- [ ] `PRODUCTION_RESULTS.md` exists with bundle/App Group fields filled for agent-known values

## Physical-device checklist (human)

- [ ] App installs on physical iPhone via Xcode USB
- [ ] Cold launch shows `notDetermined` (or current status)
- [ ] Request authorization → `approved` (or record failure)
- [ ] Timestamp updates on leave/return
- [ ] Record device/OS/bundle/App Group in `PRODUCTION_RESULTS.md`
- [ ] Confirm chosen boundary: **new product bundle** vs **evolved lab project**

## Definition of done

- [ ] Product shell runs on device
- [ ] Auth path works
- [ ] Boundary decision recorded
- [ ] Human confirmed P00

**Next:** [P01 — Tracked Apps](./MILESTONE_01_TRACKED_APPS.md)
