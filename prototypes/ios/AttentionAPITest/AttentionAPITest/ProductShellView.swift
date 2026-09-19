import SwiftUI
import os

/// P00 product host shell — auth + identity only. No picker, shields, or lab Experiments.
struct ProductShellView: View {
    @EnvironmentObject private var logger: TestLogger
    @Environment(\.scenePhase) private var scenePhase

    @State private var timestampISO = TestLogger.isoString(Date())
    @State private var authStatusLabel = FamilyControlsAuth.statusLabel
    @State private var authErrorText: String?
    @State private var isRequestingAuth = false

    private let p00Logger = Logger(subsystem: "attention.p00", category: "shell")

    var body: some View {
        NavigationStack {
            List {
                Section("Attention") {
                    Text("Attention")
                        .font(.largeTitle.weight(.bold))
                    Text("P00 — Product Shell")
                        .font(.headline)
                    Text("Access Window Model · production host")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Lifecycle timestamp") {
                    Text(timestampISO)
                        .font(.system(.body, design: .monospaced))
                    Text("Updates on appear and when the app becomes active.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Family Controls") {
                    row("authorizationStatus", authStatusLabel)
                    Button(isRequestingAuth ? "Requesting…" : "Request individual authorization") {
                        Task { await requestAuthorization() }
                    }
                    .disabled(isRequestingAuth)

                    if let authErrorText {
                        Text(authErrorText)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.red)
                            .textSelection(.enabled)
                    }

                    Text("Requires Screen Time set up on this iPhone. Simulator is not valid for PASS.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Identity") {
                    row("Display name", "Attention")
                    row("Bundle id", DeviceInfo.bundleIdentifier)
                    row("App Group", ExperimentStore.appGroupID)
                    row("Team", "VPG6W79282")
                    row("Boundary", "evolved lab project (P00)")
                    row("Device", DeviceInfo.isSimulator ? "SIMULATOR — not trustworthy" : DeviceInfo.hardwareIdentifier)
                    row("OS", DeviceInfo.systemVersion)
                }

                Section("Home (placeholder)") {
                    Text("Default closer: hard usage threshold (P05A) — may yank; Attention need not stay open. Today metrics are P06.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Recent P00 logs") {
                    let p00Lines = Array(
                        logger.lines
                            .filter { $0.tag == "ATTN-P00" }
                            .suffix(8)
                            .reversed()
                    )
                    if p00Lines.isEmpty {
                        Text("No ATTN-P00 lines yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(p00Lines) { entry in
                            Text(entry.formatted)
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .navigationTitle("Attention")
        }
        .onAppear {
            stamp(reason: "onAppear")
            refreshAuth(reason: "onAppear")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                stamp(reason: "scene_active")
                refreshAuth(reason: "scene_active")
            }
        }
    }

    private func stamp(reason: String) {
        timestampISO = TestLogger.isoString(Date())
        p00Logger.log("timestamp reason=\(reason, privacy: .public) at=\(timestampISO, privacy: .public)")
        logger.log("ATTN-P00", "timestamp reason=\(reason) at=\(timestampISO)")
    }

    private func refreshAuth(reason: String) {
        authStatusLabel = FamilyControlsAuth.statusLabel
        logger.log("ATTN-P00", "status_refresh reason=\(reason) status=\(authStatusLabel)")
    }

    @MainActor
    private func requestAuthorization() async {
        authErrorText = nil
        isRequestingAuth = true
        logger.log("ATTN-P00", "request_start for=individual")
        do {
            try await FamilyControlsAuth.requestIndividual()
            refreshAuth(reason: "request_success")
            logger.log("ATTN-P00", "request_success status=\(authStatusLabel)")
        } catch {
            authErrorText = error.localizedDescription
            refreshAuth(reason: "request_failure")
            logger.log("ATTN-P00", "request_failure \(error.localizedDescription)")
        }
        isRequestingAuth = false
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
}

#Preview {
    ProductShellView()
        .environmentObject(TestLogger.shared)
}
