# M13 — Policy and Distribution Review

**Goal:** review every sensitive permission/API used so far. Sideload success is not Play approval. Fill `docs/POLICY_NOTES.md`.

**User-visible change:** Setup shows a read-only list of sensitive permissions this build actually requests, with one-line why.

**Prerequisite:** M12 recorded (or explicitly paused). Code freeze on new APIs unless a note in POLICY_NOTES requires a tiny disclosure string.

**Agent rule:** this is mostly documentation. Do not *add* a new Accessibility path here if M08 already compared it. Do not submit to Play. Stop after the docs and disclosure screen build.

## Out of scope

- Final architecture verdict → **M14**
- Privacy policy website, account system, backend
- Changing M06 to Accessibility as default without M08 evidence

## Context

`PROTOTYPE_PLAN.md`: a technically successful approach with serious Play-policy risk is `TECHNICAL PASS / DISTRIBUTION RISK`, not a clean pass. Usage Access, FGS, notifications, WorkManager, overlays, and Accessibility each need a row. M08's Play sentence for Accessibility must appear even if polling "won."

## Steps for the agent

1. Inventory the merged manifest: every permission and service. Put the same list on Setup as plain text.
2. Complete `docs/POLICY_NOTES.md` with one section per capability actually used (including Accessibility if the M08 service exists in the APK, even when toggled off). For each:

   - API/capability
   - why the prototype uses it
   - user-facing permission/disclosure
   - whether it looks essential for the loop
   - less-sensitive alternative tried or skipped
   - technical reliability (cite TEST_RESULTS, do not invent PASS)
   - Google Play distribution concern (**do not soften Accessibility**)
   - recommended production use: `use` / `avoid` / `unknown`

3. Log `policy_review_screen_shown` once when Setup is opened this milestone, tag `ATTN-M13`.
4. Do not mark capabilities essential because they are convenient.

## Agent exit checks

```text
.\gradlew.bat assembleDebug
```

- [ ] Debug APK builds
- [ ] `POLICY_NOTES.md` is no longer a stub
- [ ] Setup lists permissions that match the manifest (spot-check)
- [ ] No new sensitive APIs added "for the review"

## Physical-device checklist (human)

- [ ] Compare Setup's permission list to Settings → App info → Permissions on the phone
- [ ] Re-read each POLICY_NOTES row. Edit anything that over-claims reliability
- [ ] Decide in notes: would you ship Usage Access? FGS? M08 API? (`yes` / `only with strong disclosure` / `no`)
- [ ] Mark M13 PASS when the review is honest, not when Play would approve (you cannot know that here)
- [ ] Record in `TEST_RESULTS.md`

## Definition of done

- [ ] POLICY_NOTES filled per used API
- [ ] On-device permission list
- [ ] Human signed off on honesty of the review

**Next:** [M14 — Android Final Verdict](./MILESTONE_14_FINAL_VERDICT.md)
