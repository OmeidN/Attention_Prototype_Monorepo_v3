import SwiftUI

/// P08 — Settings: default window, Continue budget, Pause Attention.
struct ProductSettingsView: View {
    @EnvironmentObject private var logger: TestLogger
    @EnvironmentObject private var trackedApps: TrackedAppsStore
    @EnvironmentObject private var shield: ShieldController
    @EnvironmentObject private var settings: AttentionSettingsStore
    @EnvironmentObject private var accessWindow: AccessWindowController
    @EnvironmentObject private var onboarding: OnboardingStore

    @State private var showPauseConfirm = false
    @State private var statusMessage = ""

    var body: some View {
        NavigationStack {
            List {
                Section("P08 — Settings") {
                    Text("Attention")
                        .font(.largeTitle.weight(.bold))
                    Text("Default window (all tracked apps), daily Continue budget (global), and Pause Attention. Budget does not lock Continue.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Default access window") {
                    Text("Applies to preferred duration + every tracked app. Next Continue uses this length. Mid-day edit is allowed. Apps-tab pickers can still override one app afterward.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Window", selection: Binding(
                        get: { settings.defaultWindowSeconds },
                        set: { applyDefaultWindow($0) }
                    )) {
                        ForEach(AccessWindowBridge.durationChoices, id: \.seconds) { choice in
                            let wall = HardWindowMonitor.wallClockSeconds(forUsageWindowSeconds: choice.seconds)
                            Text("\(choice.label) (wall \(Self.formatDuration(wall)))").tag(choice.seconds)
                        }
                    }
                    Text("Wall closer is max(60s, window). 15s debug and 1 min both close at ~60s.")
                        .font(.caption2)
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

                Section("Usage checkpoint (P10, optional)") {
                    Toggle("Usage checkpoint", isOn: Binding(
                        get: { settings.usageCheckpointEnabled },
                        set: { settings.setUsageCheckpointEnabled($0) }
                    ))
                    Text("Side signal only. About 1 minute of use of a tracked app can log a usage checkpoint. It does not close the window, does not block Continue, and is not an open or a session. Once per app until you toggle off and on. Default off. Wall closer is unchanged.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(UsageCheckpointMonitor.statusLine())
                        .font(.caption2.monospaced())
                        .textSelection(.enabled)
                    if UsageCheckpointMonitor.statusLine().contains("checkpoint_unavailable") {
                        Text("checkpoint_unavailable — insight did not start. The shield loop still works.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
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

                Section("Onboarding (P09)") {
                    Text(onboarding.isComplete ? "First-launch complete. Next cold start goes to Home." : "First-launch not complete. This screen is behind onboarding.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Last step: \(onboarding.lastStep)")
                        .font(.caption2)
                        .textSelection(.enabled)
                    Button("Show onboarding tips") {
                        onboarding.requestTipsReplay()
                    }
                    Button("Reset first-launch flag", role: .destructive) {
                        onboarding.resetFirstLaunch()
                        statusMessage = "First-launch reset. Onboarding should be on screen now."
                    }
                    Text("Reset is the in-app stand-in for delete + reinstall. Tips replay does not clear the flag.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Section("Decisions (v1)") {
                    Text("Continue budget: global (not per-app).")
                    Text("Default window: editable mid-day from Settings.")
                    Text("Pause Attention: yes, with confirm warning.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Recent ATTN-P08 logs") {
                    let lines = Array(
                        logger.lines
                            .filter { $0.tag == "ATTN-P08" }
                            .suffix(8)
                            .reversed()
                    )
                    if lines.isEmpty {
                        Text("No ATTN-P08 lines yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(lines) { entry in
                            Text(entry.formatted)
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                settings.reload()
                accessWindow.durationSeconds = settings.defaultWindowSeconds
                UsageCheckpointMonitor.flushHostNotes()
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

    private func applyDefaultWindow(_ seconds: Int) {
        settings.setDefaultWindowSeconds(seconds)
        let wall = HardWindowMonitor.wallClockSeconds(forUsageWindowSeconds: seconds)
        statusMessage = "Default window \(Self.formatDuration(seconds)) (wall \(Self.formatDuration(wall))) applied to \(trackedApps.apps.count) tracked app(s). Next Continue uses this length."
    }

    private static func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m) min" : "\(m)m \(s)s"
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
        .environmentObject(OnboardingStore.shared)
}
