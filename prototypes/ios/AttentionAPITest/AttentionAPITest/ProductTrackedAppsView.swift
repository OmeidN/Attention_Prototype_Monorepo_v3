import SwiftUI
import FamilyControls
import ManagedSettings

/// P01 product Setup: pick → name → list. UUID PK. No shielding.
struct ProductTrackedAppsView: View {
    @EnvironmentObject private var trackedApps: TrackedAppsStore
    @EnvironmentObject private var logger: TestLogger

    @State private var selection = FamilyActivitySelection()
    @State private var showPicker = false
    @State private var namingSession: NamingSession?
    @State private var refreshTargetID: UUID?
    @State private var statusMessage = "Add apps one at a time. Name each yourself — Apple does not give us display names."
    @State private var isSelectingToRemove = false
    @State private var removeIDs: Set<UUID> = []

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
                        Button("Clear all", role: .destructive) {
                            trackedApps.clearAll()
                            selection = trackedApps.lastSelection
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

                Section("Recent P01 logs") {
                    let p01 = Array(
                        logger.lines
                            .filter { $0.tag == "ATTN-P01" }
                            .suffix(10)
                            .reversed()
                    )
                    if p01.isEmpty {
                        Text("No ATTN-P01 lines yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(p01) { entry in
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
                        statusMessage = "Added “\(label)” id \(added.id.uuidString). Existing apps kept their ids."
                    }
                )
            }
            .onAppear {
                selection = trackedApps.lastSelection
                logger.log("ATTN-P01", "apps_screen_appear count=\(trackedApps.apps.count)")
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
                    .font(.headline)
                Text("id \(app.id.uuidString)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                if !isSelectingToRemove {
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
        .environmentObject(TestLogger.shared)
}
