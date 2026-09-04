# M08 — Exact Open Detection and DeviceActivityReport

**Goal:** (1) Answer whether `DeviceActivityReport` can give the **host app** a number, or only *display* one inside the extension view. (2) Run a controlled ~50-open trial using whatever unit M07 actually supports. Use **Open Model** only if launch/open semantics are honest.

**User-visible change:** a report view embedded in Experiments (if the API allows), plus an open-trial panel. Banner: `Not validated as opens until the trial says so.`

**Prerequisite:** M07 recorded (threshold unit known, even if the answer is "duration only").

**Agent rule:** log names stay `episode` / `threshold_event` / `report_display_only` until the human says otherwise. Implement from the SDK, not from Apple's marketing copy.

## Out of scope

- Final ARCHITECTURE_DECISION → **M13**
- Re-shielding policy → **M10**
- Non-Screen-Time hooks

## Context

Two separate confusions:

- **Monitor threshold** (M07) may only be duration.
- **DeviceActivityReport** is a sandboxed UI. It is widely unclear whether the host process can *read* a count or can only *show* the extension's view. This milestone must settle that with an implementation, not a docs paraphrase.

Canonical fallback: Opens → Sessions → Access Windows → Usage-Time.

## Steps for the agent

1. Add a Device Activity Report extension. Embed `DeviceActivityReport(...)` in Experiments. Try to surface a single number (e.g. activity for selected apps today) in the report `content` view.
2. Then try to read that number in the **host app** (not inside the extension). If the only API is the SwiftUI view, the answer is display-only. Log `report_host_readable=true|false`. Write the sentence into TEST_RESULTS: `the host app can/cannot read a numeric count out of DeviceActivityReport; the only path to a number is …`
3. Open-trial panel: ground-truth +1, detections from M07 callbacks and/or report (if readable). Show the rule in one sentence. If M07 is duration-only, log `rule_cannot_see_launches` and still run the trial so the mismatch is visible.
4. Log every truth tap and callback, tag `ATTN-M08`. Stop summary: truth, detections, misses, false positives. No auto PASS.

## Agent exit checks

- [ ] Build succeeds with report extension embedded (unless the target cannot be added — then document the Xcode blocker in TEST_RESULTS and still run the 50-open trial on M07 signals)
- [ ] Unhedged host-readable vs display-only sentence in TEST_RESULTS
- [ ] UI does not claim validated opens

## Physical-device checklist (human)

- [ ] Report UI: does a number render at all?
- [ ] Host app: can you see that same number in Logs/Setup **without** looking at the report view? Record can / cannot
- [ ] **Launcher trial:** 50 times Home → tap selected app (write down shielded or not). Ground-truth each time
- [ ] Record ~50 / ~0 / other
- [ ] **Recents contrast:** 10 times. Unknown is allowed if the API cannot tell
- [ ] Decide: `opens validated` / `not opens` / `inconclusive`
- [ ] PASS = both the report question and the trial are recorded

## Definition of done

- [ ] Report host-readability answered in TEST_RESULTS
- [ ] ~50-open (or failed-signal) evidence recorded
- [ ] Code does not treat the signal as a product open unless notes say validated

**Next:** [M09 — Session / Access Fallback](./MILESTONE_09_SESSION_ACCESS_FALLBACK.md)
