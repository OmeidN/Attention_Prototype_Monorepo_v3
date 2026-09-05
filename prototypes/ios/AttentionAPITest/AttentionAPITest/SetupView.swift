import SwiftUI

struct SetupView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var lastActiveTimestamp = TestLogger.isoString(Date())

    var body: some View {
        NavigationStack {
            List {
                Section("Milestone") {
                    row("App", "AttentionAPITest")
                    row("Current", "Milestone 00 — Local Development Setup")
                    row("Also", "M01 — Experiment Shell")
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
                }

                Section("Storage") {
                    row("Experiment state", ExperimentStore.shared.backingDescription)
                    row("foundation_ok", ExperimentStore.shared.bool("foundation_ok") ? "true" : "false")
                }

                Section("Screen Time APIs") {
                    Text("None yet. Authorization is M02, the app picker is M03, shields are M04.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Setup")
        }
        .onAppear(perform: stamp)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { stamp() }
        }
    }

    private func stamp() {
        lastActiveTimestamp = TestLogger.isoString(Date())
        milestone00Logger.log("setup_visible \(lastActiveTimestamp, privacy: .public)")
        TestLogger.shared.log("ATTN-M00", "setup_timestamp \(lastActiveTimestamp)")
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
