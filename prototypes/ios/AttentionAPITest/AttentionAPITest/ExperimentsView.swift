import SwiftUI

struct ExperimentsView: View {
    @EnvironmentObject private var logger: TestLogger
    @State private var writeCount = 0

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("M01 — no experiments yet")
                        .font(.headline)
                    Text("Screen Time experiments start at M02. This tab exists so later milestones have somewhere to live.")
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
