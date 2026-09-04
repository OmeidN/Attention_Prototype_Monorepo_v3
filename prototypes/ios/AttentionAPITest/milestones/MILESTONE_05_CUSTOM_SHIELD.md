# M05 — Custom Shield

**Goal:** add `ShieldConfigurationExtension`. Test title, subtitle, icon, and buttons, including copy that can read shared state. Record FULL / PARTIAL / FAIL customization.

**User-visible change:** the shield over a selected app shows Attention prototype copy instead of (or in addition to) the system default.

**Prerequisite:** M04 PASS (default shield works).

**Agent rule:** implement this milestone only. Do not handle button actions yet (M06). Configuration can show dummy buttons; taps are M06.

## Out of scope

- `ShieldActionExtension` behavior → **M06**
- DeviceActivity → **M07**
- Dynamic intensity beyond reading a simple UserDefaults flag

## Context

Apple limits what a shield can look like. Many apps get PARTIAL (title/subtitle yes, arbitrary layout no). Measure that. Shared state via App Group is required if copy depends on counts later (M11); a static title is enough if the group read fails — log the failure.

## Steps for the agent

1. Add Shield Configuration extension target, Family Controls capability, App Group.
2. Implement `ShieldConfigurationDataSource`. Primary/secondary labels: **Never Mind** and **Continue**. Title/subtitle may use a userLabel from App Group if you can look it up by token; if not, use generic copy plus `NO_LABEL` — do not invent bundle IDs.
3. Read a `shield_copy_variant` string from App Group UserDefaults (main app Experiments stepper: A/B). If the extension cannot read it, show `NO_SHARED_STATE` in the subtitle and log from the main app that it wrote the key. This is the same shared-state path M11 will need for friction levels.
4. Main app logs `shield_config_variant_written`, tag `ATTN-M05`. Extension logging is limited — do not rely on it.
5. Ugly is fine. Do not add custom fonts that Apple will ignore without noting it.

## Agent exit checks

- [ ] App + ShieldConfiguration extension build and are embedded
- [ ] Entitlements include Family Controls + App Group on both
- [ ] No ShieldAction extension yet

## Physical-device checklist (human)

- [ ] Shield on, open selected app: custom title/subtitle visible?
- [ ] Buttons visible with the prototype labels?
- [ ] Change variant in Attention, open shielded app again: copy changed without rebuilding?
- [ ] Record FULL (looks as coded) / PARTIAL (some fields ignored) / FAIL (still default shield)
- [ ] Icon: custom vs system — note
- [ ] PASS = experiment completed and outcome recorded, even if PARTIAL

## Definition of done

- [ ] Configuration extension ships
- [ ] Human recorded FULL/PARTIAL/FAIL

**Next:** [M06 — Shield Actions and Continue UX](./MILESTONE_06_SHIELD_ACTIONS_AND_CONTINUE_UX.md)
