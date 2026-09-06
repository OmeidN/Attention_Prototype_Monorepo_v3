import SwiftUI

struct ExperimentsView: View {
    @EnvironmentObject private var logger: TestLogger
    @State private var writeCount = 0

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("M02 auth lives on Setup")
                        .font(.headline)
                    Text("Request Family Controls authorization from the Setup tab. Picker / shields arrive in later milestones. This tab stays for log plumbing and future experiments.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Log plumbing") {
                    Button("Write a test log line") {
                        writeCount += 1
                        logger.log("ATTN-M01", "test_button_pressed count=\(writeCount)")
                    }
                    Text("Lines written this session: \(writeCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Experiments")
        }
    }
}

#Preview {
    ExperimentsView()
        .environmentObject(TestLogger.shared)
}
