# M12 — Reboot and OEM Stress Testing

**Goal:** stress permission loss, reboot, force-stop, date rollover, low-power, rapid access, and OEM differences. Document force-stop instead of trying to defeat it.

**User-visible change:** a stress checklist screen (checkboxes the human can tick) and logs for boot, permission revoke, and store restore. Optional `BOOT_COMPLETED` receiver only if used to **record** boot, not to stealth-restart watching without a notification.

**Prerequisite:** M11 recorded.

**Agent rule:** implement this milestone only. Pixel if the human has one; Samsung when available. Do not add iOS. Do not claim a second OEM was tested without the device.

## Out of scope

- Play policy essay → **M13**
- Autostart on every Chinese OEM via undocumented intents
- Defeating force-stop

## Context

Force-stop is a platform rule: the app will not run until the user launches it. Reboot may drop FGS, revoke nothing, or delay Usage Access. Date rollover must not corrupt M10 counts. Rapid repeated access tests debounce from M06–M10 under load.

## Steps for the agent

1. If you add `RECEIVE_BOOT_COMPLETED`, log `boot_completed` and show a notification `Attention prototype: phone rebooted — watch is off until you open the app` (or arm only if the human enabled "resume watch after boot" — default off).
2. Setup: persist and display last-known Usage Access granted, notification permission, battery-opt status. On launch, if Usage Access flipped to denied, log `usage_access_revoked` and show it on Setup.
3. Experiments → **Stress**: visible checklist items matching the human list below (local booleans are fine). Export logs still works after these events.
4. Confirm M10 day key uses local date; after rollover, counts reset and `day_rollover` logs.
5. Tag `ATTN-M12`. Do not add new intervention APIs.

## Agent exit checks

```text
.\gradlew.bat assembleDebug
```

- [ ] Debug APK builds
- [ ] Revoked Usage Access is visible and non-crashing
- [ ] Boot receiver, if present, does not silently start watching without a user-visible notification or explicit toggle

## Physical-device checklist (human)

Same phone as M11 first.

- [ ] **Reboot:** watch armed, reboot, do not open Attention, open a selected app. Then open Attention. Record: watch alive? boot log? selection persisted?
- [ ] **Usage Access revoke:** revoke in settings, open selected app, open Attention — no crash, status denied
- [ ] **Force-stop:** Settings → Force stop Attention. Open selected app. Then launch Attention. Record that watch was dead until launch (expected)
- [ ] **Date rollover:** change date forward one day (or wait). Counts reset or rollover logged. Restore the correct date
- [ ] **Low power / Extreme battery:** one selected-app open
- [ ] **Rapid access:** 20 times in a row open/close selected app. Note flicker, duplicate interventions, missed Continues
- [ ] **Pixel** if available: repeat reboot + swipe-away
- [ ] **Samsung** when available: repeat reboot + swipe-away + any "Sleeping apps" / Deep sleeping setting
- [ ] **Xiaomi** (or other OEM) when available: same — `UsageStats` delay and FGS death often differ here. Missing OEM = `not tested`
- [ ] Record OEM rows in `TEST_RESULTS.md`. Missing OEMs = `not tested`, not PASS

## Definition of done

- [ ] Boot/revoke/force-stop behavior is observable
- [ ] Human recorded reboot, revoke, force-stop, rollover, low-power, rapid access, and any OEM

**Next:** [M13 — Policy and Distribution Review](./MILESTONE_13_POLICY_AND_DISTRIBUTION_REVIEW.md)
