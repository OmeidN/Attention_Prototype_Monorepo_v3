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

## Start Here — iOS

The current priority is iOS. A local Apple silicon Mac, Xcode, a physical iPhone, and a paid Apple Developer Program membership are all available, so the Screen Time APIs can finally be tested on-device.

First Cursor prompt:

> Read the root `AGENTS.md`, root `PROTOTYPE_MASTER_PLAN.md`, `prototypes/ios/AttentionAPITest/PROTOTYPE_PLAN.md`, and `prototypes/ios/AttentionAPITest/milestones/MILESTONE_00_LOCAL_DEV_SETUP.md`. Implement Milestone 00 only. Do not begin later milestones. When the blank app builds and installs, summarize changes, give me the physical-device test steps, and stop.

Android is paused at M00 and keeps its own milestones. Its earlier rationale — that it was the only platform buildable from a Windows PC — no longer applies.
