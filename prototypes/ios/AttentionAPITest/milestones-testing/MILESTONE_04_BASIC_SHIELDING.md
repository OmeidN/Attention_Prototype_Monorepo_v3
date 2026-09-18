# M04 — Basic Shielding

**Goal:** apply and remove a `ManagedSettings` shield on the selected apps from a manual button. This is a red-line capability: if selected apps cannot be blocked reliably, later UX does not matter.

**User-visible change:** Experiments: **Shield selected** / **Clear shield**. Opening a shielded app shows Apple's default shield (custom UI is M05).

**Prerequisite:** M03 PASS; at least one **named** tracked app (UUID + token + userLabel).

**Agent rule:** implement this milestone only. Default system shield is enough. No ShieldConfiguration / ShieldAction / DeviceActivity extensions yet.

## Out of scope

- Custom shield copy/buttons → **M05–M06**
- Threshold monitors → **M07**
- Open detection → **M08**

## Context

`ManagedSettingsStore.shield.applications` takes `ApplicationToken`s. Read tokens from the M03 UUID store (current live handles), not from a parallel "raw selection only" store that can drift. Prefer apps-only. Clearing must restore the apps. If a token no longer resolves, log it and use `refreshToken` rather than deleting the user's history row.

## Steps for the agent

1. Use `ManagedSettingsStore()` (or the named store you will share with extensions later). Apply `shield.applications` from the **tracked-app records' current tokens**. Show userLabels on the Experiments buttons, never "token 1". Log tracked-app ids + count applied, tag `ATTN-M04`.
2. Clear: `shield.applications = nil` (or empty). Log clear.
3. Show on-screen `shielded: yes/no` from your last successful write (the API may not let you read back tokens — if so, say `last write` not `OS confirmed`).
4. App Group: if not created in M03, add it now so M05+ extensions can see selection. Document the suite name in Setup.
5. Do not start DeviceActivity schedules.

## Agent exit checks

- [ ] Build succeeds
- [ ] Apply/clear exist and are logged
- [ ] No new extension targets

## Physical-device checklist (human)

- [ ] Shield on. Open a selected app from Home. Confirm the system shield appears (not the app)
- [ ] Repeat for each selected app
- [ ] An unselected app still opens normally
- [ ] Clear shield. Selected apps open normally again
- [ ] Shield on, force-quit Attention. Selected app still shielded
- [ ] Shield on, reboot. Selected app still shielded? Record yes/no
- [ ] Record misses (app leaked through) — any leak is important
- [ ] PASS only with device evidence of apply AND clear

## Definition of done

- [ ] Manual shield apply/clear
- [ ] Human recorded reliability (red-line)

**Next:** [M05 — Custom Shield](./MILESTONE_05_CUSTOM_SHIELD.md)
