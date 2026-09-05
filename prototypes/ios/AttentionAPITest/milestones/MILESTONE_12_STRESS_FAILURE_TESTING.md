# M12 — Stress / Failure Testing

**Goal:** force quit, reboot, lock/unlock, rapid reopen, app switcher, notifications/deep links, offline, date rollover, permission/authorization changes.

**User-visible change:** a stress checklist in Experiments (human-ticked) plus logs that still export after failures.

**Prerequisite:** M04–M11 features you actually shipped.

**Agent rule:** no new product features. If authorization is revoked, show M02 status, do not crash. Do not try to defeat iOS kill.

## Out of scope

- Architecture verdict write-up → **M13**
- Android

## Context

Extensions die, shields persist, authorization can be removed in Settings. Date rollover must reset M11 counts. **Tracked-app history must still be there if tokens changed** — if a reboot/update breaks tokens, UUID rows remain and `refreshToken` is the recovery (log a miss if the shield no longer matches). Signing and install quirks stay in `docs/DEV_ENVIRONMENT.md`, not blamed on Screen Time.

## Steps for the agent

1. On launch: if `authorizationStatus` is not approved, clear "we think we are shielding" UI and log `auth_lost`.
2. Day key for counts; log `day_rollover`.
3. Stress checklist UI matching the human list. Export/copy logs still works.
4. Tag `ATTN-M12`. No new Screen Time APIs.

## Agent exit checks

- [ ] Build succeeds
- [ ] Denied/revoked auth is a UI state
- [ ] UUID store still used (no silent fallback to token-as-PK)

## Physical-device checklist (human)

- [ ] **Force quit** Attention. Shielded app still shielded?
- [ ] **Reboot.** Shield persists? Monitor still fires? Host shows correct **labels** (not just counts)?
- [ ] **Lock/unlock** during shield and during Continue window
- [ ] **Rapid reopen** selected app 20 times
- [ ] **App switcher** bypass?
- [ ] **Notification / deep link** into selected app if possible
- [ ] **Airplane mode** — shield still applies (should)
- [ ] **Date rollover** (change date, then restore)
- [ ] **Revoke Screen Time / Family Controls** — Attention does not crash
- [ ] **Full day:** leave the app+extensions installed, use selected apps morning/midday/night. Record a rough reliability percentage (callbacks vs remembered opens) in TEST_RESULTS — gaps after memory purge count
- [ ] Record each row in TEST_RESULTS

## Definition of done

- [ ] Failure states non-crashing
- [ ] Human recorded the stress matrix

**Next:** [M13 — iOS Final Verdict](./MILESTONE_13_FINAL_VERDICT.md)
