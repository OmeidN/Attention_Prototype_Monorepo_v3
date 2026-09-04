# M01 — iOS Project Setup

**Goal:** AttentionAPITest shell with Setup / Experiments / Logs, TestLogger, shared experiment state, timestamped logs. No authorization.

**User-visible change:** three tabs, on-device log list, device/build info, clear/copy logs.

**Prerequisite:** M00 recorded (Mac/Xcode exist). Simulator is enough to implement; later milestones need a phone.

**Agent rule:** implement this milestone only. Do not add Family Controls capability or authorization UI.

## Out of scope

- `AuthorizationCenter` → **M02**
- `FamilyActivityPicker` **and the naming screen** → **M03**
- Extensions → **M05–M07**

## Context

Same shell idea as Android M01 so experiments have a place to live. iOS logging must be visible on-device because a cloud Mac may not have USB Log.

Suggested files:

- `TestLogger.swift` — ring buffer + `Logger`, ISO-8601
- `ExperimentStore.swift` — `UserDefaults` for now; App Group comes when extensions need it (M04+)
- `SetupView`, `ExperimentsView`, `LogsView`

## Steps for the agent

1. TabView: Setup, Experiments, Logs.
2. Setup: model name if available (`UIDevice`), iOS version, bundle id, milestone label.
3. Experiments: `M01 — no experiments yet` + button writing one log line.
4. Logs: reverse-chronological, Clear, Copy all. Cap ~500 lines. Process death may clear memory — say so if not persisted; persisting logs to disk is allowed if small.
5. `ExperimentStore` get/set Bool and String. Write `foundation_ok=true` once.
6. Tag `ATTN-M01`. Ugly UI is correct.

## Agent exit checks

- [ ] Simulator (or device) build succeeds
- [ ] Three tabs; logs clear/copy
- [ ] Grep `AuthorizationCenter`, `FamilyActivityPicker`, `ManagedSettings` → zero hits

## Physical-device checklist (human)

- [ ] Prefer physical iPhone if install exists; else simulator and note that M02+ cannot be trusted on simulator
- [ ] Setup shows plausible device/OS
- [ ] Test log appears on Logs tab with timestamp
- [ ] Clear and copy work
- [ ] Record PASS/FAIL in `docs/TEST_RESULTS.md`

## Definition of done

- [ ] Shell + TestLogger + ExperimentStore
- [ ] No Screen Time authorization
- [ ] Human recorded evidence (device or explicit simulator limitation)

**Next:** [M02 — Family Controls Authorization](./MILESTONE_02_AUTHORIZATION.md)
