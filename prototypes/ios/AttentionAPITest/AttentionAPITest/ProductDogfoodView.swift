import SwiftUI
import UIKit

/// P11 — human-ticked stress + all-day dogfood. No new Screen Time product APIs.
struct ProductDogfoodView: View {
    @EnvironmentObject private var logger: TestLogger
    @EnvironmentObject private var trackedApps: TrackedAppsStore
    @EnvironmentObject private var shield: ShieldController
    @EnvironmentObject private var today: TodayStatsStore
    @EnvironmentObject private var settings: AttentionSettingsStore
    @EnvironmentObject private var dogfood: DogfoodChecklistStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var authStatusLabel = FamilyControlsAuth.statusLabel
    @State private var authErrorText: String?
    @State private var isRequestingAuth = false
    @State private var statusMessage = ""
    @State private var exportBlob = ""

    var body: some View {
        NavigationStack {
            List {
                Section("P11 — Dogfood") {
                    Text("Stress + all-day")
                        .font(.title2.weight(.bold))
                    Text("Tick each row after you try it. Result: pass, fail, or note. This screen does not add a new shield behavior. Copy logs still works if something fails.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(dogfood.summaryLine())
                        .font(.caption.monospaced())
                }

                if FamilyControlsAuth.status != .approved {
                    Section("Screen Time authorization") {
                        Text("Not approved (\(authStatusLabel)). Shields are not trusted until you authorize again. Attention should stay open — this is not a crash.")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        Button(isRequestingAuth ? "Requesting…" : "Re-authorize Screen Time") {
                            Task { await requestAuthorization() }
                        }
                        .disabled(isRequestingAuth)
                        if let authErrorText {
                            Text(authErrorText)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .textSelection(.enabled)
                        }
                    }
                }

                Section("Now") {
                    row("Auth", authStatusLabel)
                    row("Local day", InterventionState.todayString())
                    row("Shield UI", shield.lastWriteActive ? "active" : "not marked active")
                    row("Continues today", "\(today.continuesToday)")
                    row(
                        "Remaining / budget",
                        "\(settings.continuesRemaining(continuesToday: today.continuesToday)) / \(settings.continueBudget)"
                    )
                    Text("UUID is the id. Tokens are handles. Labels:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if trackedApps.apps.isEmpty {
                        Text("No tracked apps.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(trackedApps.apps) { app in
                            Text("\(app.userLabel)  \(app.id.uuidString)")
                                .font(.caption2.monospaced())
                                .textSelection(.enabled)
                        }
                    }
                }

                Section("Checklist") {
                    ForEach(dogfood.items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle(isOn: Binding(
                                get: { item.done },
                                set: { dogfood.setDone(id: item.id, done: $0) }
                            )) {
                                Text(item.title)
                                    .font(.body)
                            }
                            TextField("pass / fail / skip", text: Binding(
                                get: { item.result },
                                set: { dogfood.setResult(id: item.id, result: $0) }
                            ))
                            .font(.caption)
                            TextField("notes", text: Binding(
                                get: { item.notes },
                                set: { dogfood.setNotes(id: item.id, notes: $0) }
                            ))
                            .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("All-day wear") {
                    Text("Morning, midday, evening. Note misses, late re-shields, and anything that did not match the wall closer. Full-day was skipped in the lab.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("morning / midday / evening notes", text: Binding(
                        get: { dogfood.allDayNote },
                        set: { dogfood.setAllDayNote($0) }
                    ), axis: .vertical)
                    .lineLimit(3...8)
                }

                Section("Export") {
                    Button("Copy checklist + logs") {
                        copyExport()
                    }
                    Button("Refresh export text") {
                        exportBlob = combinedExport()
                    }
                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                    if !exportBlob.isEmpty {
                        Text(exportBlob)
                            .font(.system(.caption2, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    Text("Copy uses the pasteboard. It does not need Screen Time authorization.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Reset checklist", role: .destructive) {
                        dogfood.resetChecklist()
                        statusMessage = "Checklist reset."
                    }
                }

                Section("Recent ATTN-P11") {
                    let lines = Array(logger.lines.filter { $0.tag == "ATTN-P11" }.suffix(8).reversed())
                    if lines.isEmpty {
                        Text("No ATTN-P11 lines yet.")
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
            .navigationTitle("Dogfood")
            .onAppear {
                refresh()
                logger.log("ATTN-P11", "dogfood_screen \(dogfood.summaryLine()) auth=\(authStatusLabel)")
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { refresh() }
            }
        }
    }

    private func refresh() {
        authStatusLabel = FamilyControlsAuth.statusLabel
        _ = today.ingest(reason: "dogfood")
    }

    private func combinedExport() -> String {
        """
        \(dogfood.exportBlock())
        local_day=\(InterventionState.todayString())
        auth=\(FamilyControlsAuth.statusLabel)
        continues_today=\(today.continuesToday)
        budget=\(settings.continueBudget)
        --- logs ---
        \(logger.exportText())
        """
    }

    private func copyExport() {
        let text = combinedExport()
        exportBlob = text
        UIPasteboard.general.string = text
        statusMessage = "Copied checklist + \(logger.lines.count) log lines."
        logger.log("ATTN-P11", "logs_copied lines=\(logger.lines.count)")
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .font(.caption.monospaced())
                .textSelection(.enabled)
        }
    }

    @MainActor
    private func requestAuthorization() async {
        authErrorText = nil
        isRequestingAuth = true
        logger.log("ATTN-P11", "auth_request_start")
        do {
            try await FamilyControlsAuth.requestIndividual()
            authStatusLabel = FamilyControlsAuth.statusLabel
            logger.log("ATTN-P11", "auth_request_success status=\(authStatusLabel)")
        } catch {
            authErrorText = error.localizedDescription
            authStatusLabel = FamilyControlsAuth.statusLabel
            logger.log("ATTN-P11", "auth_request_failure \(error.localizedDescription)")
        }
        isRequestingAuth = false
    }
}
