import SwiftUI
import UIKit

struct LogsView: View {
    @EnvironmentObject private var logger: TestLogger
    @State private var copyConfirmation: String?

    var body: some View {
        NavigationStack {
            List {
                if let copyConfirmation {
                    Text(copyConfirmation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if logger.lines.isEmpty {
                    Text("No log lines yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(logger.reverseChronological) { line in
                        Text(line.formatted)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Logs (\(logger.lines.count))")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear", role: .destructive) {
                        logger.clear()
                        copyConfirmation = nil
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Copy all") {
                        UIPasteboard.general.string = logger.exportText()
                        copyConfirmation = "Copied \(logger.lines.count) lines to the clipboard."
                    }
                }
            }
        }
    }
}

#Preview {
    LogsView()
        .environmentObject(TestLogger.shared)
}
