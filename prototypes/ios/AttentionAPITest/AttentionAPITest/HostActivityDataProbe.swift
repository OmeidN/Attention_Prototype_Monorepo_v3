import Foundation
import DeviceActivity
import ManagedSettings
import SwiftUI

/// Host-side probe of iOS 26.4+ DeviceActivityData.activityData (separate from Report embed).
enum HostActivityDataProbe {
    struct Result {
        var durationSeconds: TimeInterval
        var pickups: Int
        var appRows: Int
        var error: String?
        var summary: String
    }

    @available(iOS 26.4, *)
    static func run(tokens: Set<ApplicationToken>) async -> Result {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let filter = DeviceActivityFilter(
            segment: .daily(during: DateInterval(start: startOfDay, end: Date())),
            applications: tokens
        )

        var duration: TimeInterval = 0
        var pickups = 0
        var rows = 0

        do {
            for try await data in DeviceActivityData.activityData(filteredBy: filter, using: .live) {
                for await segment in data.activitySegments {
                    var sawApps = false
                    for await category in segment.categories {
                        for await appActivity in category.applications {
                            sawApps = true
                            rows += 1
                            duration += appActivity.totalActivityDuration
                            pickups += appActivity.numberOfPickups
                        }
                    }
                    if !sawApps {
                        duration += segment.totalActivityDuration
                    }
                }
            }
            let summary = "host_activityData duration_s=\(Int(duration)) pickups=\(pickups) app_rows=\(rows) (pickups≠validated opens)"
            return Result(durationSeconds: duration, pickups: pickups, appRows: rows, error: nil, summary: summary)
        } catch {
            return Result(
                durationSeconds: 0,
                pickups: 0,
                appRows: 0,
                error: String(describing: error),
                summary: "host_activityData FAILED error=\(error)"
            )
        }
    }

    static func unsupportedSummary() -> String {
        "host_activityData requires iOS 26.4+ (this build probes at runtime)"
    }
}
