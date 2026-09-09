import Foundation

/// App Group bridge for DeviceActivityReport numbers (M08).
/// Host cannot read DeviceActivityReport's configuration API — only this side-channel or iOS 26.4+ activityData.
enum DeviceActivityReportBridge {
    static let contextName = "Total Activity"

    static let lastWrittenAtKey = "attention.m08.report_last_written_at"
    static let durationSecondsKey = "attention.m08.report_total_duration_seconds"
    static let pickupsKey = "attention.m08.report_total_pickups"
    static let summaryKey = "attention.m08.report_summary"
    static let appGroupWriteAttemptedKey = "attention.m08.report_appgroup_write_attempted"

    /// DeviceActivityReport is a sandboxed SwiftUI view; there is no host getter for its configuration.
    static let reportAPIHostReadableClaim =
        "report_host_readable=false — DeviceActivityReport is display-only (SwiftUI embed); no host API to read its number"

    static var suite: UserDefaults? { ShieldCopySettings.suite }

    static func writeFromReport(durationSeconds: TimeInterval, pickups: Int, summary: String) {
        suite?.set(true, forKey: appGroupWriteAttemptedKey)
        suite?.set(ISO8601DateFormatter().string(from: Date()), forKey: lastWrittenAtKey)
        suite?.set(durationSeconds, forKey: durationSecondsKey)
        suite?.set(pickups, forKey: pickupsKey)
        suite?.set(summary, forKey: summaryKey)
    }

    static func hostSideChannelSummary() -> String {
        let attempted = suite?.bool(forKey: appGroupWriteAttemptedKey) == true
        let at = suite?.string(forKey: lastWrittenAtKey) ?? "never"
        let dur = suite?.double(forKey: durationSecondsKey) ?? 0
        let pickups = suite?.integer(forKey: pickupsKey) ?? 0
        let summary = suite?.string(forKey: summaryKey) ?? "nil"
        return """
        report_api: display-only (no host getter)
        appgroup_sidechannel_attempted=\(attempted)
        last_written=\(at)
        duration_s=\(Int(dur)) pickups=\(pickups)
        summary=\(summary)
        NOTE: pickups are NOT validated as opens
        """
    }
}
