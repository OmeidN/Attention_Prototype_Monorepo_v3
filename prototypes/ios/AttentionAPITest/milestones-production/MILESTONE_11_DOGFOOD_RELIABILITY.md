# P11 — Dogfood Reliability

**Goal:** stress + **all-day dogfood** for the product app. Close the lab M12 gap (full-day was SKIPPED). No new product features.

**User-visible change:** a dogfood / stress checklist screen (human-ticked) + log export. Failure states must not crash.

**Prerequisite:** P00–P09 (P10 optional). Features you actually shipped.

**Agent rule:** no new Screen Time product APIs. Auth revoke → safe UI. Do not try to defeat iOS process kill. Fix only reliability bugs found.

## Out of scope

- Distribution entitlement request writing → **P12**
- Recap feature → **P13**
- Android

## Context

Lab confirmed force-quit, reboot, lock, rapid reopen, switcher, airplane, date rollover, revoke auth, notification suppression. Product must re-verify on the **product** bundle and complete an all-day wear test.

## Steps for the agent

1. Stress checklist UI matching the human list below.
2. On launch: if auth not approved, clear “shielding active” optimism; log `auth_lost`.
3. Ensure day rollover resets Continue/Never Mind counts and budget display.
4. Export/copy logs still works after failures.
5. Tag `ATTN-P11`.

## Agent exit checks

- [x] Build succeeds
- [x] Denied/revoked auth is a non-crash UI state
- [x] UUID still PK (no silent token-as-PK)

## Physical-device checklist (human)

- [x] **Force quit** Attention — tracked apps still shielded
- [x] **Reboot** — shields + labels correct
- [x] **Lock/unlock** during shield and during window
- [x] **Rapid reopen** tracked app ~20×
- [x] **App switcher** — no unexpected bypass
- [x] **Notifications** — suppressed while shielded; behavior after Continue matches honesty copy
- [x] **Airplane mode** — shield still applies
- [x] **Date rollover** — counts/budget reset
- [x] **Revoke Family Controls** — no crash; clear CTA
- [x] **All-day dogfood** — not worn; human 2026-09-23 accepted and moved on
- [x] Record each row in `PRODUCTION_RESULTS.md`

## Definition of done

- [x] Stress matrix recorded for product app
- [x] All-day dogfood completed (not skipped without human decision) — human decision: accept without the wear
- [x] Critical reliability bugs fixed or accepted with documented limitation (date-jump ~1330 min window time on the fake day; restored with the real date; left alone)

**Next:** [P12 — Distribution Entitlement](./MILESTONE_12_DISTRIBUTION_ENTITLEMENT.md)
