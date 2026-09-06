import SwiftUI

struct SetupView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var lastActiveTimestamp = TestLogger.isoString(Date())
    @State private var authStatusLabel = FamilyControlsAuth.statusLabel
    @State private var authErrorText: String?
    @State private var isRequestingAuth = false

    var body: some View {
        NavigationStack {
            List {
                Section("Milestone") {
                    row("App", "AttentionAPITest")
                    row("Current", "Milestone 02 — Family Controls Authorization")
                    row("Also", "M00 + M01 shell still present")
                }

                // M00's evidence that the app is alive and re-activating.
                Section("M00 timestamp") {
                    Text(lastActiveTimestamp)
                        .font(.system(.body, design: .monospaced))
                    Text("Updates on appear and whenever the app becomes active. Leave the app and come back — this must change.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Device") {
                    row("Hardware", DeviceInfo.hardwareIdentifier)
                    row("OS", DeviceInfo.systemVersion)
                    row("Environment", DeviceInfo.isSimulator ? "SIMULATOR — Screen Time results here are not trustworthy" : "Physical device")
                }

                Section("Build") {
                    row("Bundle id", DeviceInfo.bundleIdentifier)
                    row("Version", DeviceInfo.versionAndBuild)
                    row("Entitlements", "AttentionAPITest.entitlements (Family Controls)")
                }

                Section("Storage") {
                    row("Experiment state", ExperimentStore.shared.backingDescription)
                    row("foundation_ok", ExperimentStore.shared.bool("foundation_ok") ? "true" : "false")
                }

                Section("M02 — Family Controls auth") {
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

                    Text("Requires Screen Time set up on this iPhone, and an Apple ID that is not a managed child account. Simulator is not valid for PASS.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Screen Time APIs") {
                    Text("M02: AuthorizationCenter only. Picker is M03. Shields are M04.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Setup")
        }
        .onAppear {
            stamp()
            refreshAuthStatus(reason: "onAppear")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                stamp()
                refreshAuthStatus(reason: "scene_active")
            }
        }
    }

    private func stamp() {
        lastActiveTimestamp = TestLogger.isoString(Date())
        milestone00Logger.log("setup_visible \(lastActiveTimestamp, privacy: .public)")
        TestLogger.shared.log("ATTN-M00", "setup_timestamp \(lastActiveTimestamp)")
    }

    private func refreshAuthStatus(reason: String) {
        authStatusLabel = FamilyControlsAuth.statusLabel
        TestLogger.shared.log("ATTN-M02", "status_refresh reason=\(reason) status=\(authStatusLabel)")
    }

    @MainActor
    private func requestAuthorization() async {
        authErrorText = nil
        isRequestingAuth = true
        TestLogger.shared.log("ATTN-M02", "request_start for=individual")
        do {
            try await FamilyControlsAuth.requestIndividual()
            refreshAuthStatus(reason: "request_success")
            TestLogger.shared.log("ATTN-M02", "request_success status=\(authStatusLabel)")
        } catch {
            authErrorText = error.localizedDescription
            refreshAuthStatus(reason: "request_failure")
            TestLogger.shared.log("ATTN-M02", "request_failure \(error.localizedDescription)")
        }
        isRequestingAuth = false
    }

    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
    }
}

#Preview {
    SetupView()
}
