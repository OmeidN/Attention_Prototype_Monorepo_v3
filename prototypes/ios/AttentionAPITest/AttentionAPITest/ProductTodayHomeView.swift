import SwiftUI

/// P06 — honest Today home from ingested shield / access_window events (not opens / not sessions).
struct ProductTodayHomeView: View {
    @EnvironmentObject private var logger: TestLogger
    @EnvironmentObject private var trackedApps: TrackedAppsStore
    @EnvironmentObject private var shield: ShieldController
    @EnvironmentObject private var today: TodayStatsStore
    @EnvironmentObject private var scoring: ScoringStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var authStatusLabel = FamilyControlsAuth.statusLabel
    @State private var authErrorText: String?
    @State private var isRequestingAuth = false
    @State private var exportBlob = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Today") {
                    Text("Attention")
                        .font(.largeTitle.weight(.bold))
                    Text("P07 — Goals / XP / Streak")
                        .font(.headline)
                    Text("Counts + reinforcement from Never Mind / Continue / access_window events. Not opens. Not sessions. Not Screen Time Report.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("XP & streak") {
                    metric("Total XP", "\(scoring.totalXP)")
                    metric("XP today", "\(scoring.dailyXP)")
                    metric("Never Mind streak", "\(scoring.streak) day\(scoring.streak == 1 ? "" : "s")")
                    if let last = scoring.streakLastDay {
                        Text("Last streak day: \(last)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(scoring.weightsLine)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                Section("Today’s goals") {
                    ForEach(scoring.goals) { goal in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: goal.done ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(goal.done ? .green : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(goal.title)
                                    .font(.body.weight(.semibold))
                                Text(goal.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(goal.progressLabel)
                                    .font(.caption.monospacedDigit())
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                if FamilyControlsAuth.status != .approved {
                    Section("Authorize") {
                        row("authorizationStatus", authStatusLabel)
                        Button(isRequestingAuth ? "Requesting…" : "Request Screen Time authorization") {
                            Task { await requestAuthorization() }
                        }
                        .disabled(isRequestingAuth)
                        if let authErrorText {
                            Text(authErrorText)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        Text("Auth required before shields and Today events can flow.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if trackedApps.apps.isEmpty {
                    Section("Setup") {
                        Text("No tracked apps yet.")
                            .foregroundStyle(.secondary)
                        Text("Go to the Apps tab → add apps with labels → Shield all.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Today totals") {
                    metric("Never Minds (intentional choices)", "\(today.neverMindsToday)")
                    metric("Continues", "\(today.continuesToday)")
                    metric("Access windows", "\(today.windowsToday)")
                    metric("Window time", formatDuration(today.windowSecondsToday))
                    Text("Window time = elapsed (or planned) access_window length from logged start/end — not Screen Time minutes.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Section("Shield / apps") {
                    row("Shield", shield.lastWriteActive ? "active" : "cleared")
                    row("Tracked", trackedApps.apps.isEmpty
                        ? "none"
                        : trackedApps.apps.map(\.userLabel).joined(separator: ", "))
                }

                if !today.perApp.isEmpty {
                    Section("Per app (today)") {
                        ForEach(today.perApp) { row in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.label)
                                    .font(.headline)
                                Text("Never Mind \(row.neverMinds) · Continue \(row.continues) · Windows \(row.windows) · \(formatDuration(row.windowSeconds))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                Section("Recent events (today)") {
                    if today.recent.isEmpty {
                        Text("No events ingested yet. Use a shield Never Mind / Continue, then reopen Attention.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(today.recent) { event in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(eventLine(event))
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }

                Section("Ingest / dogfood") {
                    row("Last ingest", today.lastIngestAt)
                    Text(today.lastIngestNote.isEmpty ? "—" : today.lastIngestNote)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    Text(scoring.lastAwardNote.isEmpty ? "—" : scoring.lastAwardNote)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    Button("Ingest now") {
                        _ = today.ingest(reason: "manual")
                        exportBlob = TodayEventLog.exportText()
                    }
                    Button("Refresh export text") {
                        exportBlob = TodayEventLog.exportText()
                    }
                    if !exportBlob.isEmpty {
                        Text(exportBlob)
                            .font(.system(.caption2, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }

                Section("Recent ATTN-P06 / P07 logs") {
                    let lines = Array(
                        logger.lines
                            .filter { $0.tag == "ATTN-P06" || $0.tag == "ATTN-P07" }
                            .suffix(10)
                            .reversed()
                    )
                    if lines.isEmpty {
                        Text("No ATTN-P06/P07 lines yet.")
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
            .navigationTitle("Home")
        }
        .onAppear {
            authStatusLabel = FamilyControlsAuth.statusLabel
            scoring.loadPersisted()
            _ = today.ingest(reason: "onAppear")
            exportBlob = TodayEventLog.exportText()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                authStatusLabel = FamilyControlsAuth.statusLabel
                _ = today.ingest(reason: "scene_active")
            }
        }
    }

    private func eventLine(_ e: TodayEvent) -> String {
        let t = ISO8601DateFormatter().string(from: e.timestamp)
        let label = e.userLabel ?? "NO_LABEL"
        let dur = e.durationSeconds.map { " \($0)s" } ?? ""
        return "\(t) \(e.type) \(label)\(dur)"
    }

    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m) min" : "\(m)m \(s)s"
    }

    private func metric(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .font(.body.monospacedDigit().weight(.semibold))
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }

    @MainActor
    private func requestAuthorization() async {
        authErrorText = nil
        isRequestingAuth = true
        logger.log("ATTN-P06", "auth_request_start")
        do {
            try await FamilyControlsAuth.requestIndividual()
            authStatusLabel = FamilyControlsAuth.statusLabel
            logger.log("ATTN-P06", "auth_request_success status=\(authStatusLabel)")
        } catch {
            authErrorText = error.localizedDescription
            logger.log("ATTN-P06", "auth_request_failure \(error.localizedDescription)")
        }
        isRequestingAuth = false
    }
}

#Preview {
    ProductTodayHomeView()
        .environmentObject(TestLogger.shared)
        .environmentObject(TrackedAppsStore.shared)
        .environmentObject(ShieldController.shared)
        .environmentObject(TodayStatsStore.shared)
        .environmentObject(ScoringStore.shared)
}
