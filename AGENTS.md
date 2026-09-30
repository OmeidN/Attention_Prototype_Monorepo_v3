# AGENTS.md

These instructions apply to Cursor/AI coding agents throughout this repository.

## Mission
This repository is a technical feasibility lab for Attention. Do not prematurely build the production app.

## Rules
1. Read `PROTOTYPE_MASTER_PLAN.md` before platform work.
2. Read the relevant platform `PROTOTYPE_PLAN.md`.
3. Implement exactly one milestone at a time.
4. Stop after the milestone builds and provide physical-device test steps.
5. Never claim a test passed until the user confirms results from a physical device.
6. Prefer ugly, observable prototype UI over polished UI.
7. Instrument important events with timestamps.
8. Keep iOS and Android code separate.
9. Never call a signal an `open` unless the experiment validates launch/open semantics.
10. If an API is unreliable, branch to the documented fallback instead of hiding it.
11. Do not add backend, auth, subscriptions, analytics SDKs, AI, or production design yet.
12. Do not modify the other platform while completing a milestone unless explicitly asked.

## Definition of Done
A milestone is done only when it builds, has instrumentation, has clear physical-device steps, lists limitations, and did not accidentally implement later work.

## Current Priority
iOS first. Production v1 (P00–P13) is **frozen** — see `prototypes/ios/AttentionAPITest/docs/V1_SCOPE_FREEZE.md`. New work is one milestone from `prototypes/ios/AttentionAPITest/milestones-v1.1/`. Do not reopen `wall_multi_v7` unless that milestone says the closer is broken. Android is paused at M00.
