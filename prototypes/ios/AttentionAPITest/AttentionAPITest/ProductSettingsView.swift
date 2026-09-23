import SwiftUI

/// P08 — Settings: default window, Continue budget, Pause Attention.
struct ProductSettingsView: View {
    @EnvironmentObject private var logger: TestLogger
    @EnvironmentObject private var trackedApps: TrackedAppsStore
    @EnvironmentObject private var shield: ShieldController
    @EnvironmentObject private var settings: AttentionSettingsStore
    @EnvironmentObject private var accessWindow: AccessWindowController

    @State private var showPauseConfirm = false
    @State private var statusMessage = ""

    var body: some View {
        NavigationStack {
            List {
                Section("P08 — Settings") {
                    Text("Attention")
                        .font(.largeTitle.weight(.bold))
                    Text("Daily Continue budget (global) and Pause Attention. Window length is on each app in the Apps tab. Budget does not lock Continue.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Daily Continue budget (global)") {
                    Text("Home shows remaining = budget − Continues today. Over budget → 0 remaining; Continue still works; L2 copy from friction.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Budget", selection: Binding(
                        get: { settings.continueBudget },
                        set: { settings.setContinueBudget($0) }
                    )) {
                        ForEach(AttentionSettingsStore.budgetChoices, id: \.self) { n in
                            Text("\(n) / day").tag(n)
                        }
                    }
                }

                Section("Optional (P10 stub)") {
                    Toggle("Usage checkpoint insights", isOn: Binding(
                        get: { settings.usageCheckpointEnabled },
                        set: { settings.setUsageCheckpointEnabled($0) }
                    ))
                    Text("Stub only — soft insight wiring is P10. Does not close windows.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Section("Pause Attention") {
                    if settings.attentionPaused {
                        Text("PAUSED — tracked apps are not shielded by Attention until you Resume.")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        Button("Resume / Shield all") {
                            resumeAttention()
                        }
                    } else {
                        Button("Pause Attention…", role: .destructive) {
                            showPauseConfirm = true
                        }
                        Text("Clears shields so tracked apps open normally. Louder than Clear on Apps — intentional escape hatch.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !statusMessage.isEmpty {
                    Section("Status") {
                        Text(statusMessage)
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                }

                Section("Decisions (v1)") {
                    Text("Continue budget: global (not per-app).")
                    Text("Default window: editable mid-day from Settings.")
                    Text("Pause Attention: yes, with confirm warning.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                settings.reload()
                accessWindow.durationSeconds = settings.defaultWindowSeconds
            }
            .confirmationDialog(
                "Pause Attention?",
                isPresented: $showPauseConfirm,
                titleVisibility: .visible
            ) {
                Button("Pause — clear all shields", role: .destructive) {
                    pauseAttention()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Tracked apps will open without the Attention pause until you tap Resume / Shield all. This is temporary — not uninstall.")
            }
        }
    }

    private func pauseAttention() {
        HardWindowMonitor.clearWallPending(reason: "pause_attention")
        _ = HardWindowMonitor.rearm(apps: [], reason: "pause_attention")
        let closed = AccessWindowBridge.closeAllOpenWindows(mechanism: "pause_attention")
        if !closed.isEmpty {
            logger.log("ATTN-P04", "window_end pause_attention labels=[\(closed.joined(separator: ","))]")
        }
        shield.clearShield(logTag: "ATTN-P08")
        settings.markPaused()
        statusMessage = "Attention paused — shields cleared."
        logger.log("ATTN-P08", "pause_attention shields_cleared tracked=\(trackedApps.apps.count)")
    }

    private func resumeAttention() {
        settings.markResumed()
        guard !trackedApps.apps.isEmpty else {
            statusMessage = "Resumed, but no tracked apps to shield."
            return
        }
        shield.shieldSelected(apps: trackedApps.apps, logTag: "ATTN-P08")
        ReshieldPolicy.setMode(.onThreshold)
        _ = HardWindowMonitor.rearm(apps: trackedApps.apps, reason: "resume_attention")
        statusMessage = "Resumed — shielded \(trackedApps.apps.count) app(s)."
        logger.log("ATTN-P08", "resume_attention shielded=\(trackedApps.apps.count)")
    }
}

#Preview {
    ProductSettingsView()
        .environmentObject(TestLogger.shared)
        .environmentObject(TrackedAppsStore.shared)
        .environmentObject(ShieldController.shared)
        .environmentObject(AttentionSettingsStore.shared)
        .environmentObject(AccessWindowController.shared)
}
