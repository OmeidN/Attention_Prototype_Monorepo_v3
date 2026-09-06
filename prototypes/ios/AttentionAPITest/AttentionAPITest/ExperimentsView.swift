import SwiftUI
import FamilyControls
import ManagedSettings

struct ExperimentsView: View {
    @EnvironmentObject private var logger: TestLogger
    @EnvironmentObject private var trackedApps: TrackedAppsStore
    @EnvironmentObject private var shield: ShieldController
    @Environment(\.scenePhase) private var scenePhase

    @State private var selection = FamilyActivitySelection()
    @State private var showPicker = false
    @State private var namingSession: NamingSession?
    @State private var refreshTargetID: UUID?
    @State private var statusMessage: String?
    @State private var probeSummary: String?
    @State private var writeCount = 0
    @State private var isSelectingToRemove = false
    @State private var removeIDs: Set<UUID> = []

    private var authApproved: Bool {
        FamilyControlsAuth.status == .approved
    }

    private var shieldButtonTitle: String {
        let labels = trackedApps.userLabels
        if labels.isEmpty { return "Shield selected (none tracked)" }
        return "Shield selected: \(labels.joined(separator: ", "))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Milestone") {
                    Text("M04 — Basic shielding (+ M03 tracked apps)")
                        .font(.headline)
                    Text("Apply/clear Apple’s default shield on tracked apps. One-at-a-time add still applies.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !authApproved {
                    Section("Authorization") {
                        Text("Family Controls status: \(FamilyControlsAuth.statusLabel). Approve on Setup (M02) before picking apps.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Counts") {
                    row("Tracked apps", "\(trackedApps.applicationCount)")
                    row("CategoryToken (last picker)", "\(trackedApps.categoryCount)")
                    row("WebDomainToken (last picker)", "\(trackedApps.webDomainCount)")
                }

                Section("Tracked apps (user labels)") {
                    if trackedApps.apps.isEmpty {
                        Text("None yet. Use Add one app…")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(trackedApps.apps) { app in
                            trackedAppRow(app)
                        }
                        .onDelete(perform: isSelectingToRemove ? nil : deleteAtOffsets)
                    }
                }

                Section("M04 — Basic shield") {
                    Text(shield.statusLine)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)

                    Button(shieldButtonTitle) {
                        shield.shieldSelected(apps: trackedApps.apps)
                        statusMessage = "Shield applied to: \(trackedApps.userLabels.joined(separator: ", ")). Open those apps from Home to verify."
                    }
                    .disabled(trackedApps.apps.isEmpty || !authApproved)

                    Button("Clear shield", role: .destructive) {
                        shield.clearShield()
                        statusMessage = "Shield cleared (last write). Open tracked apps to confirm they launch."
                    }

                    Text("Uses Apple’s default shield UI (custom copy is M05). Status is last successful write from this app — not an OS readback.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Manage tracked apps") {
                    Button(trackedApps.apps.isEmpty ? "Add one app…" : "Add another app…") {
                        beginAddOneApp()
                    }
                    .disabled(!authApproved || isSelectingToRemove)

                    Text("Apple’s picker cannot lock checkboxes. If you uncheck an already-tracked app while adding, we reject the add and keep your list. Use Remove below instead.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if isSelectingToRemove {
                        Button("Remove \(removeIDs.count) selected", role: .destructive) {
                            removeSelected()
                        }
                        .disabled(removeIDs.isEmpty)

                        Button("Cancel multi-remove") {
                            isSelectingToRemove = false
                            removeIDs = []
                        }
                    } else {
                        Button("Select apps to remove…") {
                            isSelectingToRemove = true
                            removeIDs = []
                            statusMessage = "Tap apps to select, then Remove. Or swipe a row to delete one."
                        }
                        .disabled(trackedApps.apps.isEmpty)
                    }

                    Button("Clear all tracked apps", role: .destructive) {
                        shield.clearShield()
                        trackedApps.clearAll()
                        selection = FamilyActivitySelection()
                        isSelectingToRemove = false
                        removeIDs = []
                        statusMessage = "Tracked apps and shield cleared."
                        probeSummary = nil
                    }

                    Button("Probe token display names") {
                        Task { await runNameProbe() }
                    }
                    .disabled(trackedApps.apps.isEmpty)
                }

                if let statusMessage {
                    Section("Status") {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let probeSummary {
                    Section("Token name probe (M03 fact check)") {
                        Text(probeSummary)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }

                Section("Log plumbing") {
                    Button("Write a test log line") {
                        writeCount += 1
                        logger.log("ATTN-M01", "test_button_pressed count=\(writeCount)")
                    }
                }
            }
            .navigationTitle("Experiments")
            .familyActivityPicker(
                headerText: trackedApps.apps.isEmpty
                    ? "Pick exactly one app to track."
                    : "Keep already-tracked apps checked. Add exactly one new app. Unchecking tracked apps is rejected — use Remove in the app instead.",
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
                    },
                    onSave: { label, token in
                        let added = trackedApps.addTrackedApp(label: label, token: token)
                        selection = trackedApps.lastSelection
                        namingSession = nil
                        statusMessage = "Added “\(label)” id \(added.id.uuidString). Existing apps kept their ids."
                    }
                )
            }
            .onAppear {
                selection = trackedApps.lastSelection
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    if !authApproved {
                        statusMessage = "Authorization is \(FamilyControlsAuth.statusLabel). Re-approve on Setup if needed."
                    }
                }
            }
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
                    .font(.system(.body, design: .monospaced))
                Text("id \(app.id.uuidString)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                if !isSelectingToRemove {
                    Button("Replace token for this label") {
                        beginTokenRefresh(for: app.id)
                    }
                    .font(.caption)

                    Button("Remove this app", role: .destructive) {
                        trackedApps.removeApps(ids: [app.id])
                        selection = trackedApps.lastSelection
                        statusMessage = "Removed “\(app.userLabel)”."
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

    private func deleteAtOffsets(_ offsets: IndexSet) {
        let ids = Set(offsets.map { trackedApps.apps[$0].id })
        let labels = offsets.map { trackedApps.apps[$0].userLabel }
        trackedApps.removeApps(ids: ids)
        selection = trackedApps.lastSelection
        statusMessage = "Removed \(labels.joined(separator: ", "))."
    }

    private func removeSelected() {
        let labels = trackedApps.apps.filter { removeIDs.contains($0.id) }.map(\.userLabel)
        trackedApps.removeApps(ids: removeIDs)
        selection = trackedApps.lastSelection
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
    }

    private func beginTokenRefresh(for id: UUID) {
        refreshTargetID = id
        isSelectingToRemove = false
        removeIDs = []
        statusMessage = "Pick the same app again to re-bind its token for “\(trackedApps.app(id: id)?.userLabel ?? id.uuidString)”."
        selection = trackedApps.selectionFromTrackedApps()
        showPicker = true
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
            TestLogger.shared.log(
                "ATTN-M03",
                "add_rejected reason=unchecked_tracked removedCount=\(removed.count) labels=[\(removedLabels.joined(separator: ","))]"
            )
            statusMessage = "Add cancelled: you unchecked tracked app(s) (\(removedLabels.joined(separator: ", "))). Use Remove in Experiments instead — Apple’s picker cannot lock those checkboxes."
            return
        }

        let newTokens = trackedApps.newTokens(in: selection)

        if newTokens.isEmpty {
            revertSelectionToTracked()
            TestLogger.shared.log(
                "ATTN-M03",
                "add_rejected reason=no_new_token totalSelected=\(tokens.count) alreadyTracked=\(trackedApps.apps.count)"
            )
            statusMessage = tokens.isEmpty
                ? "Picker closed with nothing selected."
                : "No new app detected. Keep existing apps checked and add exactly one new app."
            return
        }

        if newTokens.count > 1 {
            revertSelectionToTracked()
            TestLogger.shared.log(
                "ATTN-M03",
                "add_rejected reason=too_many_new newCount=\(newTokens.count)"
            )
            statusMessage = "Add exactly one new app at a time (you added \(newTokens.count) new). Existing apps were not changed."
            return
        }

        let tokenToName = newTokens[0]
        TestLogger.shared.log(
            "ATTN-M03",
            "picker_closed newApps=1 totalSelected=\(tokens.count) → naming one (deferred)"
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            namingSession = NamingSession(token: tokenToName)
        }
    }

    private func finishTokenRefresh(id: UUID, tokens: [ApplicationToken]) {
        guard let label = trackedApps.app(id: id)?.userLabel else {
            TestLogger.shared.log("ATTN-M03", "token_refresh_failed reason=unknown_id")
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
            TestLogger.shared.log(
                "ATTN-M03",
                "token_refresh_failed reason=ambiguous_selection label=\(label) tokenCount=\(tokens.count)"
            )
            statusMessage = "Token refresh failed — pick exactly one app (got \(tokens.count))."
            revertSelectionToTracked()
            return
        }

        if trackedApps.refreshToken(for: id, newToken: newToken) {
            selection = trackedApps.lastSelection
            statusMessage = "Token refreshed for “\(label)” (same id)."
        } else {
            statusMessage = "Token refresh failed for “\(label)”."
            revertSelectionToTracked()
        }
    }

    private func runNameProbe() async {
        let result = await TokenNameProbe.run(selectedTokens: trackedApps.apps.map(\.token))
        probeSummary = result.summary
        TestLogger.shared.log("ATTN-M03", "token_name_probe \(result.summary)")
        statusMessage = "Name probe logged — see section below and Logs."
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
        }
    }
}

#Preview {
    ExperimentsView()
        .environmentObject(TestLogger.shared)
        .environmentObject(TrackedAppsStore.shared)
        .environmentObject(ShieldController.shared)
}
