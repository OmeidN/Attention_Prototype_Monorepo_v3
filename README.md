# Attention Prototype Monorepo

This repository is the feasibility-testing workspace for the Attention product.

The goal is **not** to build the production app yet. The goal is to determine, with physical-device evidence, what iOS and Android can reliably support before product architecture, analytics language, and UX are locked.

## Structure

```text
Attention/
├── AGENTS.md
├── README.md
├── PROJECT_STATUS.md
├── PROTOTYPE_MASTER_PLAN.md
├── docs/
│   ├── PRODUCT_VISION.md
│   ├── SHARED_METRICS.md
│   ├── CROSS_PLATFORM_DECISION_MATRIX.md
│   ├── SWITCHING_BETWEEN_PLATFORMS.md
│   └── FINAL_PLATFORM_COMPARISON.md
└── prototypes/
    ├── ios/AttentionAPITest/
    │   ├── README.md
    │   ├── PROTOTYPE_PLAN.md
    │   ├── milestones/
    │   └── docs/
    └── android/AttentionAndroidAPITest/
        ├── README.md
        ├── PROTOTYPE_PLAN.md
        ├── milestones/
        └── docs/
```

## Start Here — Android

The current priority is Android because it can be developed immediately from Windows.

First Cursor prompt:

> Read the root `AGENTS.md`, root `PROTOTYPE_MASTER_PLAN.md`, `prototypes/android/AttentionAndroidAPITest/PROTOTYPE_PLAN.md`, and `prototypes/android/AttentionAndroidAPITest/milestones/MILESTONE_00_ENVIRONMENT_SETUP.md`. Implement Milestone 00 only. Do not begin later milestones. When the environment and blank app are verified, summarize changes, give me the physical-device test steps, and stop.

When Mac access is ready, switch to the iOS prototype and follow its milestones independently.
