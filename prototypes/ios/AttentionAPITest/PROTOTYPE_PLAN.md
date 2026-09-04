# iOS Prototype Plan

## Objective
Determine how well Apple's Screen Time APIs support the Attention intervention model on a user's own iPhone.

## Frameworks
Swift, SwiftUI, FamilyControls, ManagedSettings, ManagedSettingsUI, DeviceActivity, App Groups, UserDefaults for prototype shared state.

## Intended Targets
- AttentionAPITest App
- DeviceActivityMonitorExtension
- ShieldConfigurationExtension
- ShieldActionExtension

## Prototype UI
Authorization status, selected-app count, experiment dashboard, live logs, pass/fail/manual-result controls, counters, export/copy diagnostics.

## Critical Unknowns
Open/session signal, continue flow, re-shield timing, dynamic shield behavior, extension communication, physical-device reliability.

## Fallback
Open → Session → Access Window → Usage-Time.
