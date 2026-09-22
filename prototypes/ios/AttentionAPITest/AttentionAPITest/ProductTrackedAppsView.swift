import SwiftUI
import FamilyControls
import ManagedSettings

/// P01–P02 product Setup: pick → name → list + Shield all / Clear (Apple default chrome).
struct ProductTrackedAppsView: View {
    @EnvironmentObject private var trackedApps: TrackedAppsStore
    @EnvironmentObject private var shield: ShieldController
    @EnvironmentObject private var accessWindow: AccessWindowController
    @EnvironmentObject private var logger: TestLogger

    @State private var selection = FamilyActivitySelection()
    @State private var showPicker = false
    @State private var namingSession: NamingSession?
    @State private var refreshTargetID: UUID?
    @State private var statusMessage = "Add apps one at a time. Name each yourself — Apple does not give us display names."
    @State private var isSelectingToRemove = false
    @State private var removeIDs: Set<UUID> = []
    @State private var lastActionLine = ShieldActionBridge.lastActionSummary()
    @Environment(\.scenePhase) private var scenePhase

    private var authApproved: Bool {
        FamilyControlsAuth.status == .approved
    }

    var body: some View {
        NavigationStack {
            List {
                Section("P01 — Tracked apps") {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    row("Count", "\(trackedApps.apps.count)")
                    row("Storage", ExperimentStore.shared.backingDescription)
                    row("Auth", FamilyControlsAuth.statusLabel)
                }

                Section("P05B — Wall-clock closer") {
                    Text(HardWindowMonitor.mappingDescription())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Expect: Continue app A → only A opens + own wall. App B stays shielded until its Continue. Each has independent wall (`wall_multi_v1`). last_close=wall_clock per app.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    row("Closer", "wall-only · per-app timers · may yank when that app's wall ends")
                    row("Monitor / wall", HardWindowMonitor.statusLine())
                    Text(DeviceActivityBridge.statusSummary())
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                    Button("Stop legacy usage monitor (noop if already off)") {
                        ReshieldPolicy.setMode(.onThreshold)
                        _ = HardWindowMonitor.rearm(apps: [], reason: "manual_stop_usage")
                        logger.log("ATTN-P05B", "manual_stop_usage ok")
                        statusMessage = "Usage monitor stopped. Wall arms on Continue only."
                    }
                }

                Section("P05 — Friction ladder") {
                    Text("Per-app continues_today drive shield copy. Never Mind does not bump Continue count. No Continue-button delay (API unavailable).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(InterventionState.mappingDescription())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(InterventionState.statusSummary(apps: trackedApps.apps))
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                    if let config = ShieldCopySettings.suite?.string(forKey: "attention.p05.last_level_config") {
                        row("Last shield config", config)
                    }
                    Button("Reset today's Continue / Never Mind counts") {
                        InterventionState.resetToday()
                        logger.log("ATTN-P05", "reset_today local_day=\(InterventionState.todayString())")
                        statusMessage = "Reset today's friction counts — next shield should be L0."
                    }
                    if let first = trackedApps.apps.first {
                        Button("Debug +1 Continue for \(first.userLabel)") {
                            let result = InterventionState.debugBumpContinue(appID: first.id)
                            logger.log(
                                "ATTN-P05",
                                "debug_bump label=\(first.userLabel) prev_level=\(result.prev) next_level=\(result.next) continues=\(result.count)"
                            )
                            statusMessage = "Debug bump \(first.userLabel) → L\(result.next) (continues=\(result.count)). Re-open shield to see copy."
                        }
                    }
                }

                // TEMP DEBUG — remove before v1 freeze (see docs/TEMP_DEBUG_RESETS.md)
                Section("TEMP DEBUG resets (remove later)") {
                    Text("Testing only. Per-app reset is on each tracked app row. Global wipe clears Home/XP event log + friction counts.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("TEMP: Wipe ALL Home/XP events", role: .destructive) {
                        let note = TodayStatsStore.shared.tempWipeAllForTesting()
                        statusMessage = "TEMP wipe done. \(note) Open Home — should be zeros."
                    }
                }

                Section("P04 — Access window (status)") {
                    Text("Default window length lives in Settings (P08). Per-app override is on each tracked app row. Host on_window_end remains secondary to hard threshold.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    row("Policy", "on_threshold (hard) · host on_window_end is secondary")
                    row("Unit", "access_window / usage duration (not open / not session_end)")
                    row("Preferred (Settings)", "\(AccessWindowBridge.preferredDurationSeconds())s")

                    Text(accessWindow.statusText)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)

                    Text(accessWindow.ruleText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Refresh window status") {
                        accessWindow.sync(
                            reason: "manual_refresh",
                            attentionForeground: true,
                            apps: trackedApps.apps
                        )
                        logger.log("ATTN-P04", "manual_refresh \(AccessWindowBridge.statusSummary().replacingOccurrences(of: "\n", with: " | "))")
                    }
                }

                Section("P03 — Shield actions") {
                    Text("Never Mind = stay blocked (intentional choice). Continue = unblock + start access_window; extra tap to open; re-shield at window end (P04).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    row("Last action", lastActionLine)
                    row("Host note", ShieldActionBridge.suite?.string(forKey: ShieldActionBridge.hostNeededNoteKey) ?? ShieldActionBridge.hostNeededDefault)
                    row("Extension note", ShieldActionBridge.extensionNote())
                    row("Events stored", "\(ShieldActionBridge.loadEvents().count)")
                    Button("Refresh last action from App Group") {
                        refreshShieldAction(reason: "manual")
                    }
                }

                Section("P02 — Shield") {
                    row("State", shield.lastWriteActive ? "active" : "cleared")
                    row("Last write", shield.lastWriteAt ?? "none")
                    row("Labels", shield.lastWriteLabels.isEmpty ? "—" : shield.lastWriteLabels)
                    Text(shield.statusLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    Button("Shield all") {
                        shield.shieldSelected(apps: trackedApps.apps, logTag: "ATTN-P02")
                        ReshieldPolicy.setMode(.onThreshold)
                        // Drop any prior Continue wall so a leftover intervalDidEnd doesn't
                        // immediately re-block after the next Continue.
                        HardWindowMonitor.clearWallPending(reason: "shield_all")
                        _ = HardWindowMonitor.rearm(apps: [], reason: "shield_all")
                        logger.log(
                            "ATTN-P05B",
                            "shield_all wall_only \(HardWindowMonitor.statusLine())"
                        )
                        statusMessage = trackedApps.apps.isEmpty
                            ? "No tracked apps to shield."
                            : "Shield applied. Wall closer arms on Continue (~window length). Force-quit Attention OK."
                    }
                    .disabled(!authApproved || trackedApps.apps.isEmpty)

                    Button("Clear shields", role: .destructive) {
                        HardWindowMonitor.clearWallPending(reason: "clear_shields")
                        _ = HardWindowMonitor.rearm(apps: [], reason: "clear_shields")
                        shield.clearShield(logTag: "ATTN-P02")
                        statusMessage = "Shields cleared. Tracked apps should open normally."
                    }

                    Text("Force-quit Attention or reboot — shields should still block tracked apps until Clear. Untracked apps must open normally.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Actions") {
                    Button("Add one app") {
                        beginAddOneApp()
                    }
                    .disabled(!authApproved)

                    if !trackedApps.apps.isEmpty {
                        Button(isSelectingToRemove ? "Done selecting" : "Select to remove…") {
                            isSelectingToRemove.toggle()
                            removeIDs = []
                        }
                        if isSelectingToRemove {
                            Button("Remove selected (\(removeIDs.count))", role: .destructive) {
                                removeSelected()
                            }
                            .disabled(removeIDs.isEmpty)
                        }
                        Button("Clear all tracked apps", role: .destructive) {
                            trackedApps.clearAll()
                            selection = trackedApps.lastSelection
                            shield.syncWithTrackedApps(trackedApps.apps, reason: "clear_all_tracked")
                            statusMessage = "Cleared all tracked apps."
                            isSelectingToRemove = false
                            removeIDs = []
                        }
                    }

                    if !authApproved {
                        Text("Approve Family Controls on the Shell tab first.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Tracked (\(trackedApps.apps.count))") {
                    if trackedApps.apps.isEmpty {
                        Text("None yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(trackedApps.apps) { app in
                            trackedAppRow(app)
                        }
                        .onDelete(perform: deleteAtOffsets)
                    }
                }

                Section("Recent P01–P05 logs") {
                    let recent = Array(
                        logger.lines
                            .filter {
                                $0.tag.hasPrefix("ATTN-P0")
                            }
                            .suffix(14)
                            .reversed()
                    )
                    if recent.isEmpty {
                        Text("No P0x lines yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(recent) { entry in
                            Text(entry.formatted)
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .navigationTitle("Apps")
            .familyActivityPicker(
                headerText: trackedApps.apps.isEmpty
                    ? "Pick exactly one app to track."
                    : "Keep already-tracked apps checked. Add exactly one new app. Unchecking tracked apps is rejected — use Remove instead.",
                isPresented: $showPicker,
                selection: $selection
            )
            .onChange(of: showPicker) { _, isPresented in
                if !isPresented {
                    handlePickerDismissed()
                }
            }
            .sheet(item: $namingSession) { session in
                NamingAppsView(
                    token: session.token,
                    onCancel: {
                        namingSession = nil
                        revertSelectionToTracked()
                        statusMessage = "Naming cancelled — previous tracked apps unchanged."
                        logger.log("ATTN-P01", "naming_cancelled")
                    },
                    onSave: { label, token in
                        let added = trackedApps.addTrackedApp(label: label, token: token)
                        selection = trackedApps.lastSelection
                        namingSession = nil
                        shield.syncWithTrackedApps(trackedApps.apps, reason: "added_one")
                        statusMessage = "Added “\(label)” id \(added.id.uuidString). Existing apps kept their ids."
                    }
                )
            }
            .onAppear {
                selection = trackedApps.lastSelection
                logger.log("ATTN-P01", "apps_screen_appear count=\(trackedApps.apps.count)")
                logger.log(
                    "ATTN-P02",
                    "shield_status_appear active=\(shield.lastWriteActive) at=\(shield.lastWriteAt ?? "nil")"
                )
                refreshShieldAction(reason: "onAppear")
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    refreshShieldAction(reason: "scene_active")
                }
            }
        }
    }

    private func refreshShieldAction(reason: String) {
        lastActionLine = ShieldActionBridge.lastActionSummary()
        if let consumed = ShieldActionBridge.consumeNewActionForHost() {
            lastActionLine = consumed.summary
            var msg = "ATTN-P03 host_seen \(consumed.summary)"
            if let latency = consumed.latencySeconds {
                msg += " host_seen_latency_s=\(String(format: "%.2f", latency))"
            }
            msg += " reason=\(reason) note=\(ShieldActionBridge.extensionNote())"
            logger.log("ATTN-P03", msg)
            if consumed.summary.contains("last_shield_action=continue") {
                shield.reconcileFromExtensionFlag(reason: reason)
                accessWindow.sync(
                    reason: "after_continue_\(reason)",
                    attentionForeground: true,
                    apps: trackedApps.apps
                )
                if let transition = ShieldCopySettings.suite?.string(forKey: "attention.m11.last_continue_transition") {
                    logger.log("ATTN-P05", "continue_transition \(transition)")
                }
            } else if consumed.summary.contains("intentional_choice") || consumed.summary.contains("never_mind") {
                logger.log("ATTN-P05", "intentional_choice_no_continue_bump \(consumed.summary)")
            }
            statusMessage = "Shield action: \(consumed.summary)"
        } else {
            logger.log("ATTN-P03", "host_poll reason=\(reason) \(lastActionLine)")
            accessWindow.sync(
                reason: "poll_\(reason)",
                attentionForeground: true,
                apps: trackedApps.apps
            )
        }
    }

    @ViewBuilder
    private func trackedAppRow(_ app: TrackedApp) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if isSelectingToRemove {
                Image(systemName: removeIDs.contains(app.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(removeIDs.contains(app.id) ? Color.accentColor : .secondary)
                    .padding(.top, 2)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(app.userLabel)
                    .font(.headline)
                Text("id \(app.id.uuidString)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Text("Window ≈ UI \(Self.formatDuration(app.windowDurationSeconds)) / wall \(Self.formatDuration(HardWindowMonitor.wallClockSeconds(forUsageWindowSeconds: app.windowDurationSeconds))) (usage OFF)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !isSelectingToRemove {
                    Picker("Window", selection: Binding(
                        get: { app.windowDurationSeconds },
                        set: { newValue in
                            trackedApps.setWindowDuration(appID: app.id, seconds: newValue)
                            _ = HardWindowMonitor.rearm(apps: trackedApps.apps, reason: "duration_change")
                        }
                    )) {
                        ForEach(AccessWindowBridge.durationChoices, id: \.seconds) { choice in
                            Text(choice.label).tag(choice.seconds)
                        }
                    }
                    .font(.caption)

                    Button("Try system token refresh") {
                        if trackedApps.attemptSystemTokenRefresh(for: app.id) {
                            selection = trackedApps.lastSelection
                            statusMessage = "System Token.refresh OK for “\(app.userLabel)” (same id)."
                        } else {
                            statusMessage = "System refresh failed for “\(app.userLabel)” — use Re-bind."
                        }
                    }
                    .font(.caption)

                    Button("Re-bind token (picker)") {
                        beginTokenRefresh(for: app.id)
                    }
                    .font(.caption)

                    Button("Remove", role: .destructive) {
                        trackedApps.removeApps(ids: [app.id])
                        selection = trackedApps.lastSelection
                        shield.syncWithTrackedApps(trackedApps.apps, reason: "remove_one")
                        _ = HardWindowMonitor.rearm(apps: trackedApps.apps, reason: "remove_one")
                        statusMessage = "Removed “\(app.userLabel)”."
                    }
                    .font(.caption)

                    // TEMP DEBUG — remove before v1 freeze (see docs/TEMP_DEBUG_RESETS.md)
                    Button("TEMP: Reset counts for this app", role: .destructive) {
                        let note = TodayStatsStore.shared.tempResetAppForTesting(
                            appID: app.id,
                            label: app.userLabel
                        )
                        statusMessage = "TEMP reset “\(app.userLabel)”. \(note)"
                    }
                    .font(.caption)
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard isSelectingToRemove else { return }
            if removeIDs.contains(app.id) {
                removeIDs.remove(app.id)
            } else {
                removeIDs.insert(app.id)
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }

    private static func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        if seconds % 60 == 0 { return "\(seconds / 60) min" }
        return "\(seconds / 60)m \(seconds % 60)s"
    }

    private func deleteAtOffsets(_ offsets: IndexSet) {
        let ids = Set(offsets.map { trackedApps.apps[$0].id })
        let labels = offsets.map { trackedApps.apps[$0].userLabel }
        trackedApps.removeApps(ids: ids)
        selection = trackedApps.lastSelection
        shield.syncWithTrackedApps(trackedApps.apps, reason: "swipe_delete")
        statusMessage = "Removed \(labels.joined(separator: ", "))."
    }

    private func removeSelected() {
        let labels = trackedApps.apps.filter { removeIDs.contains($0.id) }.map(\.userLabel)
        trackedApps.removeApps(ids: removeIDs)
        selection = trackedApps.lastSelection
        shield.syncWithTrackedApps(trackedApps.apps, reason: "remove_selected")
        statusMessage = "Removed \(labels.joined(separator: ", "))."
        isSelectingToRemove = false
        removeIDs = []
    }

    private func beginAddOneApp() {
        refreshTargetID = nil
        isSelectingToRemove = false
        removeIDs = []
        statusMessage = trackedApps.apps.isEmpty
            ? "Pick exactly one app, then name it."
            : "Keep existing apps checked. Check exactly one additional app. Do not uncheck tracked apps."
        selection = trackedApps.selectionFromTrackedApps()
        showPicker = true
        logger.log("ATTN-P01", "picker_open mode=add_one already=\(trackedApps.apps.count)")
    }

    private func beginTokenRefresh(for id: UUID) {
        refreshTargetID = id
        isSelectingToRemove = false
        removeIDs = []
        statusMessage = "Pick the same app again to re-bind its token for “\(trackedApps.app(id: id)?.userLabel ?? id.uuidString)”."
        selection = trackedApps.selectionFromTrackedApps()
        showPicker = true
        logger.log("ATTN-P01", "picker_open mode=rebind id=\(id.uuidString)")
    }

    private func revertSelectionToTracked() {
        selection = trackedApps.selectionFromTrackedApps()
        trackedApps.updateLastSelection(selection)
    }

    private func handlePickerDismissed() {
        let tokens = Array(selection.applicationTokens)

        if let refreshID = refreshTargetID {
            refreshTargetID = nil
            finishTokenRefresh(id: refreshID, tokens: tokens)
            return
        }

        let removed = trackedApps.removedTrackedTokens(in: selection)
        if !removed.isEmpty {
            let removedLabels = trackedApps.labels(forTokens: removed)
            revertSelectionToTracked()
            logger.log(
                "ATTN-P01",
                "add_rejected reason=unchecked_tracked removedCount=\(removed.count) labels=[\(removedLabels.joined(separator: ","))]"
            )
            statusMessage = "Add cancelled: you unchecked tracked app(s) (\(removedLabels.joined(separator: ", "))). Use Remove in the app instead — Apple’s picker cannot lock those checkboxes."
            return
        }

        let newTokens = trackedApps.newTokens(in: selection)

        if newTokens.isEmpty {
            revertSelectionToTracked()
            logger.log(
                "ATTN-P01",
                "add_rejected reason=no_new_token totalSelected=\(tokens.count) alreadyTracked=\(trackedApps.apps.count)"
            )
            statusMessage = tokens.isEmpty
                ? "Picker closed with nothing selected."
                : "No new app detected. Keep existing apps checked and add exactly one new app."
            return
        }

        if newTokens.count > 1 {
            revertSelectionToTracked()
            logger.log("ATTN-P01", "add_rejected reason=too_many_new newCount=\(newTokens.count)")
            statusMessage = "Add exactly one new app at a time (you added \(newTokens.count) new). Existing apps were not changed."
            return
        }

        let tokenToName = newTokens[0]
        logger.log("ATTN-P01", "picker_closed newApps=1 → naming")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            namingSession = NamingSession(token: tokenToName)
        }
    }

    private func finishTokenRefresh(id: UUID, tokens: [ApplicationToken]) {
        guard let label = trackedApps.app(id: id)?.userLabel else {
            logger.log("ATTN-P01", "token_refresh_failed reason=unknown_id")
            statusMessage = "Token refresh failed — unknown id."
            revertSelectionToTracked()
            return
        }

        let existingOthers = Set(trackedApps.apps.filter { $0.id != id }.map(\.token))
        let candidates = tokens.filter { !existingOthers.contains($0) }

        let chosen: ApplicationToken?
        if tokens.count == 1 {
            chosen = tokens[0]
        } else if candidates.count == 1 {
            chosen = candidates[0]
        } else if candidates.isEmpty, let first = tokens.first {
            chosen = first
        } else {
            chosen = nil
        }

        guard let newToken = chosen else {
            logger.log(
                "ATTN-P01",
                "token_refresh_failed reason=ambiguous_selection label=\(label) tokenCount=\(tokens.count)"
            )
            statusMessage = "Token refresh failed — pick exactly one app (got \(tokens.count))."
            revertSelectionToTracked()
            return
        }

        if trackedApps.refreshToken(for: id, newToken: newToken) {
            selection = trackedApps.lastSelection
            statusMessage = "Token re-bound for “\(label)” (same id)."
        } else {
            statusMessage = "Token refresh failed for “\(label)”."
            revertSelectionToTracked()
        }
    }
}

#Preview {
    ProductTrackedAppsView()
        .environmentObject(TrackedAppsStore.shared)
        .environmentObject(ShieldController.shared)
        .environmentObject(AccessWindowController.shared)
        .environmentObject(TestLogger.shared)
}
