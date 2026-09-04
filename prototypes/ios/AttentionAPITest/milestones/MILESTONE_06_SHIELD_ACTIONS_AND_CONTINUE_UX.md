# M06 — Shield Actions and Continue UX

**Goal:** add `ShieldActionExtension`. **Never Mind** (stay blocked / go home) vs **Continue** (lift shield so the app can be used). Measure taps, clarity, latency, and whether the main app must come to the foreground.

**User-visible change:** shield buttons do something. Continue uses the selected app without an extra unexplained tap if the API allows it.

**Prerequisite:** M05 recorded (even PARTIAL). M04 shield apply still works.

**Agent rule:** implement this milestone only. Do not add DeviceActivity schedules (M07). Do not implement timed re-shield (M10) beyond whatever is required to avoid a permanently unsielded state — if you must re-apply immediately after Continue for safety, log that as a limitation and leave real policy to M10.

## Out of scope

- Usage thresholds → **M07**
- Open counting → **M08**
- Access windows / re-shield policy → **M09–M10**

## Context

The shared loop needs clean back-out and continue. On iOS the shield is a system UI; the extension gets `.primaryButtonPressed` / `.secondaryButtonPressed`. Closing the shield vs deferring vs opening the host app are different. Measure whether Continue can be one tap.

## Steps for the agent

1. Add Shield Action extension, same App Group / Family Controls.
2. Map primary = Never Mind, secondary = Continue (or the reverse — show the mapping on the shield labels from M05).
3. **Never Mind:** keep shield, `return .close` (or documented equivalent). Write an **Intentional Choice** record to App Group: `{ trackedAppId: UUID, timestamp }` — key by M03 id, not by raw token. Log `last_shield_action=never_mind`. Do **not** implement XP/scoring (after verdict).
4. **Continue:** clear or unblock the application tokens on `ManagedSettingsStore` so the app can run. Log `continue` with the same `trackedAppId`. Then `.defer` / `.close` as required so the user lands in the app.
5. Main app Experiments: last action, last latency if you can compute from timestamps, `host_app_needed: yes/no` note field.
6. Tag `ATTN-M06` in the main app when it reads the action. Extension should write UserDefaults; it may not print to your Logs tab until the host opens.

## Agent exit checks

- [ ] App + config + action extensions build
- [ ] Grep `DeviceActivityCenter` → zero hits
- [ ] Continue clears shield for the selected apps (code path exists)

## Physical-device checklist (human)

Repeat 5 times each.

- [ ] Never Mind: still blocked; you are not inside the selected app
- [ ] Continue: you get into the selected app. Count extra taps (including "Open Attention")
- [ ] After Continue, Home, tap the app again — still unshielded? (record; M10 will re-shield)
- [ ] Latency: tap to usable app (felt)
- [ ] If Continue only works after Attention comes foreground, record `main-app handoff required`
- [ ] Record PASS/FAIL and tap counts in TEST_RESULTS

## Definition of done

- [ ] Both actions implemented
- [ ] Human recorded taps, latency, handoff need

**Next:** [M07 — Device Activity Thresholds](./MILESTONE_07_DEVICE_ACTIVITY_THRESHOLDS.md)
