import DeviceActivity
import Foundation

/// M07: writes interval/threshold callbacks into the App Group for the host to read.
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        DeviceActivityBridge.recordIntervalStart(activity: activity.rawValue)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        DeviceActivityBridge.recordIntervalEnd(activity: activity.rawValue)
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        DeviceActivityBridge.recordThreshold(activity: activity.rawValue, eventRaw: event.rawValue)
    }
}
