import SwiftUI
import FamilyControls

/// P09 — first-run steps. Ugly and explicit. Does not claim app-open tracking.
struct ProductOnboardingView: View {
    /// Tips replay can close. First launch cannot.
    var isReplay: Bool = false

    @EnvironmentObject private var logger: TestLogger
    @EnvironmentObject private var trackedApps: TrackedAppsStore
    @EnvironmentObject private var shield: ShieldController
    @EnvironmentObject private var settings: AttentionSettingsStore
    @EnvironmentObject private var onboarding: OnboardingStore

    @State private var step = 0
    @State private var authStatusLabel = FamilyControlsAuth.statusLabel
    @State private var authErrorText: String?
    @State private var isRequestingAuth = false
    @State private var selection = FamilyActivitySelection()
    @State private var showPicker = false
    @State private var namingSession: NamingSession?
    @State private var pickStatus = ""
    @State private var notifyAcknowledged = false
    @State private var showSkipConfirm = false
    @State private var statusMessage = ""

    private let stepCount = 6

    var body: some View {
        NavigationStack {
            List {
                Section("P09 — Onboarding \(step + 1)/\(stepCount)") {
                    Text(stepTitle)
                        .font(.title2.weight(.bold))
                    Text(isReplay ? "Tips replay. Close leaves Home as-is." : "First launch. Finish or skip shields with the warning on the last step.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                stepBody

                if !statusMessage.isEmpty {
                    Section("Status") {
                        Text(statusMessage)
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                }

                Section("Recent ATTN-P09") {
                    let lines = Array(
                        logger.lines.filter { $0.tag == "ATTN-P09" }.suffix(6).reversed()
                    )
                    if lines.isEmpty {
                        Text("No ATTN-P09 lines yet.")
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
            .navigationTitle("Onboarding")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if step > 0 {
                        Button("Back") { step -= 1 }
                    } else if isReplay {
                        Button("Close") {
                            logger.log("ATTN-P09", "tips_replay_closed")
                            onboarding.showTipsReplay = false
                        }
                    }
                }
            }
            .familyActivityPicker(
                headerText: trackedApps.apps.isEmpty
                    ? "Pick exactly one app to track."
                    : "Keep already-tracked apps checked. Add exactly one new app.",
                isPresented: $showPicker,
                selection: $selection
            )
            .onChange(of: showPicker) { _, isPresented in
                if !isPresented { handlePickerDismissed() }
            }
            .sheet(item: $namingSession) { session in
                NamingAppsView(
                    token: session.token,
                    onCancel: {
                        namingSession = nil
                        selection = trackedApps.selectionFromTrackedApps()
                        pickStatus = "Naming cancelled."
                        logger.log("ATTN-P09", "naming_cancelled")
                    },
                    onSave: { label, token in
                        let added = trackedApps.addTrackedApp(label: label, token: token)
                        selection = trackedApps.lastSelection
                        namingSession = nil
                        pickStatus = "Named “\(label)”."
                        logger.log("ATTN-P09", "named id=\(added.id.uuidString) label=\(label) total=\(trackedApps.apps.count)")
                    }
                )
            }
            .confirmationDialog(
                "Skip shields?",
                isPresented: $showSkipConfirm,
                titleVisibility: .visible
            ) {
                Button("Skip — apps stay open", role: .destructive) {
                    finish(shieldsApplied: false)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Tracked apps will open with no Attention pause until you Shield all on the Apps tab. This is not uninstall.")
            }
            .onAppear {
                authStatusLabel = FamilyControlsAuth.statusLabel
                settings.reload()
                logger.log("ATTN-P09", "onboarding_shown mode=\(isReplay ? "tips" : "first_launch")")
            }
        }
    }

    @ViewBuilder
    private var stepBody: some View {
        switch step {
        case 0:
            Section("Loop") {
                Text("Pause at the door → Never Mind or a timed Continue → shield returns → that choice is recorded.")
                Text("The unit is an access window, not an app open. Attention does not count opens.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("When the wall ends, the shield can return even if you are still in the app. Attention does not need to stay open.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Continue") { advance("why") }
            }
        case 1:
            Section("Screen Time") {
                Text("Family Controls lets Attention shield the apps you name. Individual authorization.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Status: \(authStatusLabel)")
                    .font(.body.monospaced())
                Button(isRequestingAuth ? "Requesting…" : "Request Screen Time authorization") {
                    Task { await requestAuthorization() }
                }
                .disabled(isRequestingAuth || FamilyControlsAuth.status == .approved)
                if let authErrorText {
                    Text(authErrorText)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Button("Continue") { advance("auth status=\(authStatusLabel)") }
                    .disabled(FamilyControlsAuth.status != .approved)
            }
        case 2:
            Section("Pick and name") {
                Text("Apple does not give display names. Add one app, then type a label (blank is rejected).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if trackedApps.apps.isEmpty {
                    Text("No tracked apps yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(trackedApps.apps) { app in
                        Text(app.userLabel)
                    }
                }
                if !pickStatus.isEmpty {
                    Text(pickStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button("Add one app") {
                    selection = trackedApps.selectionFromTrackedApps()
                    showPicker = true
                    logger.log("ATTN-P09", "picker_open already=\(trackedApps.apps.count)")
                }
                .disabled(FamilyControlsAuth.status != .approved)
                Button("Continue") {
                    let labels = trackedApps.apps.map(\.userLabel).joined(separator: ",")
                    advance("pick count=\(trackedApps.apps.count) labels=[\(labels)]")
                }
                .disabled(trackedApps.apps.isEmpty)
            }
        case 3:
            Section("Notification honesty") {
                Text("While an app is shielded, its alerts get quieter. They can be delayed, missing, or cleared from Notification Center when the shield comes back. After Continue, a backlog can appear.")
                Text("Do not shield apps you need for time-critical alerts (banking codes, medical, work paging). Attention does not use notifications to catch you, and it cannot bypass this.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("I understand. I will not shield critical-alert apps.", isOn: $notifyAcknowledged)
                Button("Continue") {
                    logger.log("ATTN-P09", "notify_ack=true")
                    advance("notify_honesty ack=true")
                }
                .disabled(!notifyAcknowledged)
                Text("This step has no skip. The checkbox is required.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case 4:
            Section("Window and budget") {
                Text("Default window applies to every tracked app. You can change it later in Settings, including mid-day. Apps-tab rows can still override one app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Window", selection: Binding(
                    get: { settings.defaultWindowSeconds },
                    set: { settings.setDefaultWindowSeconds($0) }
                )) {
                    ForEach(AccessWindowBridge.durationChoices, id: \.seconds) { choice in
                        let wall = HardWindowMonitor.wallClockSeconds(forUsageWindowSeconds: choice.seconds)
                        Text("\(choice.label) (wall \(Self.formatDuration(wall)))").tag(choice.seconds)
                    }
                }
                Text("Wall closer is max(60s, window). 15s debug and 1 min both close around 60s. The shield can return mid-use when that wall ends.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Picker("Daily Continue budget (global)", selection: Binding(
                    get: { settings.continueBudget },
                    set: { settings.setContinueBudget($0) }
                )) {
                    ForEach(AttentionSettingsStore.budgetChoices, id: \.self) { n in
                        Text("\(n) / day").tag(n)
                    }
                }
                Text("Budget is reinforcement. At 0 remaining, Continue still works.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Button("Continue") {
                    advance("window_budget window_s=\(settings.defaultWindowSeconds) budget=\(settings.continueBudget)")
                }
            }
        default:
            Section("Apply shields") {
                Text("Apply shields so the next attempt on a tracked app hits the pause. Or skip with the warning — apps stay open until you Shield all.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Tracked: \(trackedApps.apps.map(\.userLabel).joined(separator: ", "))")
                    .font(.caption)
                Button("Apply shields and finish") {
                    applyShields()
                    finish(shieldsApplied: true)
                }
                .disabled(trackedApps.apps.isEmpty)
                Button("Skip shields…", role: .destructive) {
                    showSkipConfirm = true
                }
            }
        }
    }

    private var stepTitle: String {
        switch step {
        case 0: return "Why Attention"
        case 1: return "Screen Time permission"
        case 2: return "Pick apps and name them"
        case 3: return "Notifications while shielded"
        case 4: return "Window and Continue budget"
        default: return "Turn shields on"
        }
    }

    private func advance(_ name: String) {
        onboarding.markStep(name)
        step = min(step + 1, stepCount - 1)
    }

    private func applyShields() {
        settings.markResumed()
        HardWindowMonitor.clearWallPending(reason: "onboarding_apply")
        _ = HardWindowMonitor.rearm(apps: [], reason: "onboarding_apply")
        let closed = AccessWindowBridge.closeAllOpenWindows(mechanism: "onboarding_apply")
        if !closed.isEmpty {
            logger.log("ATTN-P04", "window_end onboarding_apply labels=[\(closed.joined(separator: ","))]")
        }
        shield.shieldSelected(apps: trackedApps.apps, logTag: "ATTN-P09")
        ReshieldPolicy.setMode(.onThreshold)
        logger.log("ATTN-P09", "shields_applied count=\(trackedApps.apps.count)")
        statusMessage = "Shields applied to \(trackedApps.apps.count) app(s)."
    }

    private func finish(shieldsApplied: Bool) {
        if !shieldsApplied {
            HardWindowMonitor.clearWallPending(reason: "onboarding_skip")
            _ = HardWindowMonitor.rearm(apps: [], reason: "onboarding_skip")
            let closed = AccessWindowBridge.closeAllOpenWindows(mechanism: "onboarding_skip")
            if !closed.isEmpty {
                logger.log("ATTN-P04", "window_end onboarding_skip labels=[\(closed.joined(separator: ","))]")
            }
            shield.clearShield(logTag: "ATTN-P09")
            logger.log("ATTN-P09", "shields_skipped_with_warning")
            statusMessage = "Skipped shields. Tracked apps stay open until Shield all."
        }
        onboarding.markComplete(shieldsApplied: shieldsApplied)
    }

    @MainActor
    private func requestAuthorization() async {
        authErrorText = nil
        isRequestingAuth = true
        logger.log("ATTN-P09", "auth_request_start")
        do {
            try await FamilyControlsAuth.requestIndividual()
            authStatusLabel = FamilyControlsAuth.statusLabel
            logger.log("ATTN-P09", "auth_request_success status=\(authStatusLabel)")
        } catch {
            authErrorText = error.localizedDescription
            authStatusLabel = FamilyControlsAuth.statusLabel
            logger.log("ATTN-P09", "auth_request_failure \(error.localizedDescription)")
        }
        isRequestingAuth = false
    }

    private func handlePickerDismissed() {
        let removed = trackedApps.removedTrackedTokens(in: selection)
        if !removed.isEmpty {
            selection = trackedApps.selectionFromTrackedApps()
            pickStatus = "Add cancelled: unchecking tracked apps is rejected. Use Apps tab Remove."
            logger.log("ATTN-P09", "add_rejected reason=unchecked_tracked")
            return
        }
        let newTokens = trackedApps.newTokens(in: selection)
        if newTokens.count != 1 {
            selection = trackedApps.selectionFromTrackedApps()
            pickStatus = newTokens.isEmpty
                ? "No new app. Add exactly one."
                : "Add exactly one new app (got \(newTokens.count))."
            logger.log("ATTN-P09", "add_rejected reason=count new=\(newTokens.count)")
            return
        }
        let token = newTokens[0]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            namingSession = NamingSession(token: token)
        }
    }

    private static func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m) min" : "\(m)m \(s)s"
    }
}
