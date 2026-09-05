import Foundation
import os

/// One timestamped line in the prototype's on-device log.
struct LogLine: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let tag: String
    let message: String

    var formatted: String {
        "\(TestLogger.isoString(timestamp)) [\(tag)] \(message)"
    }
}

/// Ring-buffer logger whose output is readable on the phone itself.
///
/// Xcode's console is not a dependable channel for this lab: from M05 onward the
/// shield and monitor extensions run in separate processes, and most Screen Time
/// behavior has to be exercised untethered.
final class TestLogger: ObservableObject {
    static let shared = TestLogger()

    /// Lines are persisted so a process death does not erase evidence.
    private static let storageKey = "attention.testlogger.lines"
    private static let capacity = 500

    @Published private(set) var lines: [LogLine] = []

    private let osLogger = Logger(subsystem: "attention.apitest", category: "prototype")
    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.lines = Self.loadPersisted(from: defaults)
    }

    // MARK: - Writing

    func log(_ tag: String, _ message: String) {
        let line = LogLine(id: UUID(), timestamp: Date(), tag: tag, message: message)
        osLogger.log("\(line.formatted, privacy: .public)")

        DispatchQueue.main.async {
            self.lines.append(line)
            if self.lines.count > Self.capacity {
                self.lines.removeFirst(self.lines.count - Self.capacity)
            }
            self.persist()
        }
    }

    func clear() {
        DispatchQueue.main.async {
            self.lines.removeAll()
            self.persist()
        }
    }

    /// Newest first, which is how the Logs tab reads.
    var reverseChronological: [LogLine] {
        lines.reversed()
    }

    func exportText() -> String {
        reverseChronological.map(\.formatted).joined(separator: "\n")
    }

    // MARK: - Persistence

    private func persist() {
        guard let data = try? JSONEncoder().encode(lines) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    private static func loadPersisted(from defaults: UserDefaults) -> [LogLine] {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([LogLine].self, from: data)
        else { return [] }
        return decoded
    }

    // MARK: - Formatting

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func isoString(_ date: Date) -> String {
        isoFormatter.string(from: date)
    }
}
