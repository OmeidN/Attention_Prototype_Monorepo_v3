import Foundation
import DeviceActivity
import ManagedSettings

/// P05A/P05B: usage-threshold + wall-clock hybrid closer (Attention may be quit).
enum HardWindowMonitor {
    static let activityRaw = "attention.p05a.hard_window"
    static var activityName: DeviceActivityName { DeviceActivityName(activityRaw) }

    static let wallActivityRaw = "attention.p05b.wall_clock"
    static var wallActivityName: DeviceActivityName { DeviceActivityName(wallActivityRaw) }

    static let lastArmAtKey = "attention.p05a.last_arm_at"
    static let lastArmErrorKey = "attention.p05a.last_arm_error"
    static let lastArmSummaryKey = "attention.p05a.last_arm_summary"
    /// ISO timestamp of last usage-monitor arm — used to ignore immediate false threshold fires.
    static let lastUsageArmAtKey = "attention.p05a.last_usage_arm_at"
    /// Shortest per-app threshold (seconds) from last rearm — grace floor for premature ignore.
    static let lastUsageThresholdSecondsKey = "attention.p05a.last_usage_threshold_s"
    static let lastPrematureIgnoreKey = "attention.p05a.last_premature_threshold_ignore"
    /// Set by tryReshieldFromMonitorExtension: premature | applied | no_targets | wrong_mode
    static let lastUsageThresholdDecisionKey = "attention.p05a.last_usage_threshold_decision"

    static let wallPendingIdKey = "attention.p05b.wall_pending_app_id"
    static let wallPendingLabelKey = "attention.p05b.wall_pending_label"
    static let wallEndAtKey = "attention.p05b.wall_end_at"
    static let wallSecondsKey = "attention.p05b.wall_seconds"
    static let wallArmSummaryKey = "attention.p05b.wall_arm_summary"
    static let lastHybridCloseKey = "attention.p05b.last_hybrid_close"

    static var suite: UserDefaults? { ShieldCopySettings.suite }

    /// Product-facing wall duration (leave-early backup). Usage path can still be shorter.
    /// DeviceActivitySchedule itself requires ≥15 minutes (see `armWallClock` past-padding).
    static func wallClockSeconds(forUsageWindowSeconds usage: Int) -> Int {
        let clamped = max(15, usage)
        if clamped <= 15 { return 60 }
        return clamped + 60
    }

    /// Apple: DeviceActivity schedule interval must be ≥ 15 minutes or startMonitoring throws intervalTooShort.
    static let deviceActivityMinIntervalSeconds = 15 * 60

    /// Bumped when wall-arm algorithm changes — must appear in `wall_arm_ok` / failed lines after install.
    static let wallArmCode = "pad15m_v2"

    static func mappingDescription() -> String {
        "hybrid: usage≈window OR wall (15s→60s debug; else window+60s). DA schedule padded ≥15m (past start, \(wallArmCode))."
    }

    static func dateComponents(forSeconds seconds: Int) -> DateComponents {
        let clamped = max(15, seconds)
        if clamped % 60 == 0 {
            return DateComponents(minute: clamped / 60)
        }
        if clamped >= 60 {
            return DateComponents(minute: clamped / 60, second: clamped % 60)
        }
        return DateComponents(second: clamped)
    }

    /// Stop + start all-day monitoring with one event per tracked app (threshold = that app's window).
    @discardableResult
    static func rearm(apps: [TrackedApp], reason: String) -> String? {
        let center = DeviceActivityCenter()
        center.stopMonitoring([activityName])

        guard !apps.isEmpty else {
            DeviceActivityBridge.markMonitoringStopped()
            let msg = "rearm_cleared reason=\(reason) apps=0"
            suite?.set(msg, forKey: lastArmSummaryKey)
            suite?.set(ISO8601DateFormatter().string(from: Date()), forKey: lastArmAtKey)
            suite?.removeObject(forKey: lastArmErrorKey)
            return nil
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )

        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        var parts: [String] = []
        var minThreshold = Int.max
        for app in apps {
            let secs = max(15, app.windowDurationSeconds)
            minThreshold = min(minThreshold, secs)
            let name = DeviceActivityEvent.Name(app.id.uuidString)
            // includesPastActivity=false (iOS 17.4+): otherwise today's prior Instagram use (≥15s) makes
            // eventDidReachThreshold fire immediately on every Continue rearm → shield never lifts.
            let threshold = dateComponents(forSeconds: secs)
            if #available(iOS 17.4, *) {
                events[name] = DeviceActivityEvent(
                    applications: [app.token],
                    threshold: threshold,
                    includesPastActivity: false
                )
            } else {
                events[name] = DeviceActivityEvent(
                    applications: [app.token],
                    threshold: threshold
                )
            }
            let wall = wallClockSeconds(forUsageWindowSeconds: secs)
            parts.append("\(app.userLabel)=use\(secs)s/wall\(wall)s")
        }
        if minThreshold == Int.max { minThreshold = 15 }

        do {
            try center.startMonitoring(activityName, during: schedule, events: events)
            let maxMinutes = apps.map { max(15, $0.windowDurationSeconds) }.max().map { max(1, $0 / 60) } ?? 1
            DeviceActivityBridge.markMonitoringStarted(
                ids: apps.map(\.id.uuidString),
                labels: apps.map(\.userLabel),
                thresholdMinutes: maxMinutes
            )
            let armAt = ISO8601DateFormatter().string(from: Date())
            let summary = "rearm_ok reason=\(reason) apps=\(apps.count) [\(parts.joined(separator: ","))] hybrid=usage+wall past_activity=false"
            suite?.set(summary, forKey: lastArmSummaryKey)
            suite?.set(armAt, forKey: lastArmAtKey)
            suite?.set(armAt, forKey: lastUsageArmAtKey)
            suite?.set(minThreshold, forKey: lastUsageThresholdSecondsKey)
            suite?.removeObject(forKey: lastArmErrorKey)
            return nil
        } catch {
            let err = String(describing: error)
            suite?.set(err, forKey: lastArmErrorKey)
            suite?.set("rearm_failed reason=\(reason) error=\(err)", forKey: lastArmSummaryKey)
            suite?.set(ISO8601DateFormatter().string(from: Date()), forKey: lastArmAtKey)
            DeviceActivityBridge.markMonitoringStopped()
            return err
        }
    }

    /// True when threshold fired too soon after arm (known DeviceActivity false positive).
    /// Caller should not re-shield; wall-clock backup still closes the door.
    static func shouldIgnorePrematureUsageThreshold() -> Bool {
        guard let raw = suite?.string(forKey: lastUsageArmAtKey),
              let armAt = ISO8601DateFormatter().date(from: raw)
        else { return false }
        let threshold = suite?.object(forKey: lastUsageThresholdSecondsKey) as? Int ?? 15
        // Allow a few seconds of slop under the configured window; anything sooner is bogus.
        let grace = TimeInterval(max(8, min(threshold - 2, 45)))
        let elapsed = Date().timeIntervalSince(armAt)
        if elapsed < grace {
            let note = "premature_threshold_ignored elapsed_s=\(Int(elapsed)) grace_s=\(Int(grace)) threshold_s=\(threshold) at=\(ISO8601DateFormatter().string(from: Date()))"
            suite?.set(note, forKey: lastPrematureIgnoreKey)
            return true
        }
        return false
    }

    /// One-shot wall-clock schedule for the Continued app (closes even if user left the app).
    ///
    /// Apple requires schedule span ≥ 15 minutes (`intervalTooShort` otherwise). For shorter
    /// product walls we pad `intervalStart` into the past so `intervalDidEnd` still lands near
    /// now + wallSeconds (Screen Time workaround). Components are minute-aligned (no seconds).
    @discardableResult
    static func armWallClock(for app: TrackedApp, reason: String) -> String? {
        let center = DeviceActivityCenter()
        center.stopMonitoring([wallActivityName])

        let usage = max(15, app.windowDurationSeconds)
        let wallSecs = wallClockSeconds(forUsageWindowSeconds: usage)
        let calendar = Calendar.current
        let now = Date()

        // Whole minutes only — DeviceActivity often ignores/truncates seconds.
        let wallMinutes = max(1, (wallSecs + 59) / 60)
        guard let nowMinute = calendar.date(bySetting: .second, value: 0, of: now),
              let end = calendar.date(byAdding: .minute, value: wallMinutes + 1, to: nowMinute),
              let start = calendar.date(byAdding: .minute, value: -15, to: end)
        else {
            let msg = "wall_arm_failed reason=\(reason) error=date_math code=\(wallArmCode)"
            suite?.set(msg, forKey: wallArmSummaryKey)
            return "date_math"
        }

        // Midnight: keep a valid same-day ≥15m span ending today if possible.
        var startDate = start
        var endDate = end
        if !calendar.isDate(startDate, inSameDayAs: endDate) {
            if let eod = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: nowMinute),
               let sod = calendar.date(byAdding: .minute, value: -15, to: eod),
               calendar.isDate(sod, inSameDayAs: eod) {
                startDate = sod
                endDate = eod
            }
        }

        let startDC = DateComponents(
            hour: calendar.component(.hour, from: startDate),
            minute: calendar.component(.minute, from: startDate)
        )
        let endDC = DateComponents(
            hour: calendar.component(.hour, from: endDate),
            minute: calendar.component(.minute, from: endDate)
        )

        let schedule = DeviceActivitySchedule(
            intervalStart: startDC,
            intervalEnd: endDC,
            repeats: false
        )

        let spanMinutes = Int(endDate.timeIntervalSince(startDate) / 60)
        let next = schedule.nextInterval
        let nextDesc: String
        if let next {
            let nextSpan = Int(next.end.timeIntervalSince(next.start))
            nextDesc = "next=\(ISO8601DateFormatter().string(from: next.start))→\(ISO8601DateFormatter().string(from: next.end)) next_span_s=\(nextSpan)"
        } else {
            nextDesc = "next=nil"
        }

        let padPastS = max(0, Int(now.timeIntervalSince(startDate)))
        let untilEndS = max(0, Int(endDate.timeIntervalSince(now)))
        suite?.set(app.id.uuidString, forKey: wallPendingIdKey)
        suite?.set(app.userLabel, forKey: wallPendingLabelKey)
        suite?.set(wallSecs, forKey: wallSecondsKey)
        suite?.set(ISO8601DateFormatter().string(from: endDate), forKey: wallEndAtKey)

        do {
            try center.startMonitoring(wallActivityName, during: schedule, events: [:])
            let summary = "wall_arm_ok code=\(wallArmCode) reason=\(reason) label=\(app.userLabel) usage_s=\(usage) wall_s=\(wallSecs) span_m=\(spanMinutes) pad_past_s=\(padPastS) until_end_s=\(untilEndS) end=\(suite?.string(forKey: wallEndAtKey) ?? "?") \(nextDesc)"
            suite?.set(summary, forKey: wallArmSummaryKey)
            return next == nil ? "wall_armed_but_nextInterval_nil" : nil
        } catch {
            let err = String(describing: error)
            suite?.set("wall_arm_failed code=\(wallArmCode) reason=\(reason) error=\(err) wall_s=\(wallSecs) span_m=\(spanMinutes) \(nextDesc)", forKey: wallArmSummaryKey)
            return err
        }
    }

    static func clearWallPending(reason: String) {
        suite?.removeObject(forKey: wallPendingIdKey)
        suite?.removeObject(forKey: wallPendingLabelKey)
        let center = DeviceActivityCenter()
        center.stopMonitoring([wallActivityName])
        suite?.set("wall_cleared reason=\(reason)", forKey: wallArmSummaryKey)
    }

    static func pendingWallAppID() -> UUID? {
        guard let raw = suite?.string(forKey: wallPendingIdKey) else { return nil }
        return UUID(uuidString: raw)
    }

    static func statusLine() -> String {
        let summary = suite?.string(forKey: lastArmSummaryKey) ?? "never_armed"
        let wall = suite?.string(forKey: wallArmSummaryKey) ?? "wall_never"
        let close = suite?.string(forKey: lastHybridCloseKey) ?? "none"
        return "\(summary) | \(wall) | last_close=\(close)"
    }
}
