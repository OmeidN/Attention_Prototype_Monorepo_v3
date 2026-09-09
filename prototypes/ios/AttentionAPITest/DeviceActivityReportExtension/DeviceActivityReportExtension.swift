import DeviceActivity
import ExtensionKit
import ManagedSettings
import SwiftUI

@main
struct AttentionDeviceActivityReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { config in
            TotalActivityView(config: config)
        }
    }
}

extension DeviceActivityReport.Context {
    static let totalActivity = Self(DeviceActivityReportBridge.contextName)
}

struct ReportConfiguration {
    let summaryLine: String
    let durationSeconds: TimeInterval
    let pickups: Int
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (ReportConfiguration) -> TotalActivityView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> ReportConfiguration {
        var duration: TimeInterval = 0
        var pickups = 0
        var rows = 0

        for await deviceData in data {
            for await segment in deviceData.activitySegments {
                var sawApps = false
                for await category in segment.categories {
                    for await app in category.applications {
                        sawApps = true
                        rows += 1
                        pickups += app.numberOfPickups
                        duration += app.totalActivityDuration
                    }
                }
                if !sawApps {
                    duration += segment.totalActivityDuration
                }
            }
        }

        let minutes = Int(duration / 60)
        let seconds = Int(duration) % 60
        let summary = "duration=\(minutes)m\(seconds)s pickups=\(pickups) apps=\(rows) NOT_OPENS"

        DeviceActivityReportBridge.writeFromReport(
            durationSeconds: duration,
            pickups: pickups,
            summary: summary
        )

        return ReportConfiguration(summaryLine: summary, durationSeconds: duration, pickups: pickups)
    }
}

struct TotalActivityView: View {
    let config: ReportConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("M08 Report (extension)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(config.summaryLine)
                .font(.system(.body, design: .monospaced))
            Text("pickups shown are NOT validated as opens")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }
}
