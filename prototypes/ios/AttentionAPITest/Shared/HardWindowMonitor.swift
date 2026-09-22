import Foundation
import DeviceActivity
import ManagedSettings

/// P05B wall-clock closer (Attention may be quit). In-app usage threshold is off — DA was unreliable vs wall.
enum HardWindowMonitor {
    static let activityRaw = "attention.p05a.hard_window"
    static var activityName: DeviceActivityName { DeviceActivityName(activityRaw) }

    static let wallActivityRaw = "attention.p05b.wall_clock"
    static var wallActivityName: DeviceActivityName { DeviceActivityName(wallActivityRaw) }

    static let lastArmAtKey = "attention.p05a.last_arm_at"
    static let lastArmErrorKey = "attention.p05a.last_arm_error"
    static let lastArmSummaryKey = "attention.p05a.last_arm_summary"
    /// ISO timestamp of last usage-monitor arm — legacy; usage closer disabled.
    static let lastUsageArmAtKey = "attention.p05a.last_usage_arm_at"
    /// Wall-clock when user hit Continue.
    static let continueSessionAtKey = "attention.p05a.continue_session_at"
    static let lastUsageThresholdSecondsKey = "attention.p05a.last_usage_threshold_s"
    static let lastPrematureIgnoreKey = "attention.p05a.last_premature_threshold_ignore"
    static let lastUsageThresholdDecisionKey = "attention.p05a.last_usage_threshold_decision"
    static let prematureRetryCountKey = "attention.p05a.premature_retry_count"
    static let maxPrematureRetries = 0

    /// In-app DeviceActivity usage closer disabled — wall-only after Continue.
    static let usageCloserEnabled = false

    /// Legacy single-pending keys (kept for status / migration).
    static let wallPendingIdKey = "attention.p05b.wall_pending_app_id"
    static let wallPendingLabelKey = "attention.p05b.wall_pending_label"
    static let wallEndAtKey = "attention.p05b.wall_end_at"
    static let wallSecondsKey = "attention.p05b.wall_seconds"
    static let wallArmSummaryKey = "attention.p05b.wall_arm_summary"
    static let lastHybridCloseKey = "attention.p05b.last_hybrid_close"
    /// JSON map appUUID → PendingWall (per-app independent timers).
    static let wallPendingMapKey = "attention.p05b.wall_pending_map_v1"

    struct PendingWall: Codable {
        var appID: String
        var label: String
        var wallSeconds: Int
        var endAt: String
        var continuedAt: String
    }

    static var suite: UserDefaults? { ShieldCopySettings.suite }

    /// Product wall = access window, floored at 60s (15s debug + 1 min → 60s; 5 min → 5 min).
    /// DeviceActivitySchedule requires ≥15 minutes span (see `armWallClock` past-padding); end is minute-aligned.
    static func wallClockSeconds(forUsageWindowSeconds usage: Int) -> Int {
        max(60, max(15, usage))
    }

    /// Legacy helper for UI — usage closer is off; value unused for monitoring.
    static func deviceActivityThresholdSeconds(forUsageWindowSeconds usage: Int) -> Int {
        wallClockSeconds(forUsageWindowSeconds: usage)
    }

    /// Apple: DeviceActivity schedule interval must be ≥ 15 minutes or startMonitoring throws intervalTooShort.
    static let deviceActivityMinIntervalSeconds = 15 * 60

    /// Per-app wall activities so Continue on A does not cancel B's timer.
    static let wallActivityPrefix = "attention.p05b.wall."
    static let wallArmCode = "wall_multi_v1"

    static func wallActivityName(forAppID id: UUID) -> DeviceActivityName {
        DeviceActivityName("\(wallActivityPrefix)\(id.uuidString)")
    }

    static func appID(fromWallActivityRaw raw: String) -> UUID? {
        guard raw.hasPrefix(wallActivityPrefix) else {
            // Legacy single activity name — fall back to map / legacy key.
            if raw == wallActivityRaw { return pendingWallAppID() }
            return nil
        }
        return UUID(uuidString: String(raw.dropFirst(wallActivityPrefix.count)))
    }

    static func isWallActivity(_ raw: String) -> Bool {
        raw.hasPrefix(wallActivityPrefix) || raw == wallActivityRaw
    }

    static func mappingDescription() -> String {
        "wall-only closer (per-app timers): 15s/1min → ~60s wall; longer → wall≈window. Continue one app leaves others shielded until their own Continue."
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

    /// Stops legacy usage-threshold monitoring. Does not start it (`usageCloserEnabled=false`).
    @discardableResult
    static func rearm(apps: [TrackedApp], reason: String) -> String? {
        let center = DeviceActivityCenter()
        center.stopMonitoring([activityName])
        DeviceActivityBridge.markMonitoringStopped()

        let parts = apps.map { app -> String in
            let secs = max(15, app.windowDurationSeconds)
            let wall = wallClockSeconds(forUsageWindowSeconds: secs)
            return "\(app.userLabel)=ui\(secs)s/wall\(wall)s"
        }
        let armAt = ISO8601DateFormatter().string(from: Date())
        let summary = "usage_closer=off reason=\(reason) apps=\(apps.count) [\(parts.joined(separator: ","))] wall_only"
        suite?.set(summary, forKey: lastArmSummaryKey)
        suite?.set(armAt, forKey: lastArmAtKey)
        suite?.removeObject(forKey: lastArmErrorKey)
        suite?.set(0, forKey: prematureRetryCountKey)
        if reason == "continue" {
            suite?.set(armAt, forKey: continueSessionAtKey)
        }
        return nil
    }

    /// Minimum wall-clock seconds since Continue before we trust a usage-threshold callback.
    /// Keep this short: each premature *re-arm* resets usage accumulation (`includesPastActivity=false`),
    /// so a long gate + many rearms made 1‑min windows feel like 2+ minutes.
    static func minElapsedBeforeUsageYank(thresholdSeconds: Int) -> TimeInterval {
        _ = thresholdSeconds
        return 15
    }

    /// True when threshold fired too soon after *Continue* (not after a premature re-arm).
    /// Caller should not re-shield; should re-arm usage monitoring so a later real yank can fire.
    static func shouldIgnorePrematureUsageThreshold() -> Bool {
        let threshold = suite?.object(forKey: lastUsageThresholdSecondsKey) as? Int ?? 60
        let minElapsed = minElapsedBeforeUsageYank(thresholdSeconds: threshold)

        let anchorRaw = suite?.string(forKey: continueSessionAtKey)
            ?? suite?.string(forKey: lastUsageArmAtKey)
        guard let anchorRaw,
              let anchor = ISO8601DateFormatter().date(from: anchorRaw)
        else { return false }

        let elapsed = Date().timeIntervalSince(anchor)
        if elapsed < minElapsed {
            let note = "premature_threshold_ignored elapsed_since_continue_s=\(Int(elapsed)) min_s=\(Int(minElapsed)) threshold_s=\(threshold) at=\(ISO8601DateFormatter().string(from: Date()))"
            suite?.set(note, forKey: lastPrematureIgnoreKey)
            return true
        }
        return false
    }

    /// Usage closer disabled — never re-arm thresholds.
    @discardableResult
    static func rearmAfterPrematureIgnore() -> String {
        let msg = "usage_closer=off — ignore premature (wall-only)"
        suite?.set(msg, forKey: lastPrematureIgnoreKey)
        return msg
    }

    /// One-shot wall-clock schedule for one Continued app (independent of other apps' walls).
    ///
    /// Apple requires schedule span ≥ 15 minutes (`intervalTooShort` otherwise). For shorter
    /// product walls we pad `intervalStart` into the past so `intervalDidEnd` still lands near
    /// now + wallSeconds. End is rounded up to the next minute boundary (no extra +1 minute).
    ///
    /// Near local midnight, `end - 15m` can fall on the previous calendar day. Do **not** clamp
    /// to 23:59 today (that caused ~24h waits: until_end_s≈86000). Instead pull start to
    /// start-of-today and extend end only if the span would be under 15 minutes.
    @discardableResult
    static func armWallClock(for app: TrackedApp, reason: String) -> String? {
        let center = DeviceActivityCenter()
        let activity = wallActivityName(forAppID: app.id)
        // Only stop this app's prior wall — leave other apps' timers running.
        center.stopMonitoring([activity])
        // Also stop legacy single-name monitor if still around.
        center.stopMonitoring([wallActivityName])

        let usage = max(15, app.windowDurationSeconds)
        let wallSecs = wallClockSeconds(forUsageWindowSeconds: usage)
        let calendar = Calendar.current
        let now = Date()
        let dayStart = calendar.startOfDay(for: now)
        let iso = ISO8601DateFormatter()

        let endTarget = now.addingTimeInterval(TimeInterval(wallSecs))
        guard var endDate = calendar.date(bySetting: .second, value: 0, of: endTarget) else {
            let msg = "wall_arm_failed reason=\(reason) error=date_math code=\(wallArmCode) label=\(app.userLabel)"
            suite?.set(msg, forKey: wallArmSummaryKey)
            return "date_math"
        }
        if endDate.timeIntervalSince(now) < TimeInterval(wallSecs) {
            endDate = calendar.date(byAdding: .minute, value: 1, to: endDate) ?? endDate
        }

        var startDate = endDate.addingTimeInterval(-TimeInterval(deviceActivityMinIntervalSeconds))
        if startDate < dayStart {
            startDate = dayStart
            let minEnd = dayStart.addingTimeInterval(TimeInterval(deviceActivityMinIntervalSeconds))
            if endDate < minEnd {
                endDate = minEnd
            }
        }

        if !calendar.isDate(endDate, inSameDayAs: now) {
            endDate = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: now) ?? endDate
            startDate = endDate.addingTimeInterval(-TimeInterval(deviceActivityMinIntervalSeconds))
            if startDate < dayStart { startDate = dayStart }
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
        let untilEndS = max(0, Int(endDate.timeIntervalSince(now)))
        let next = schedule.nextInterval
        let nextDesc: String
        if let next {
            let nextSpan = Int(next.end.timeIntervalSince(next.start))
            let nextUntil = Int(next.end.timeIntervalSince(now))
            nextDesc = "next=\(iso.string(from: next.start))→\(iso.string(from: next.end)) next_span_s=\(nextSpan) next_until_s=\(nextUntil)"
            if nextUntil > wallSecs + 20 * 60 {
                let err = "wall_arm_rejected_far_next next_until_s=\(nextUntil) wall_s=\(wallSecs)"
                suite?.set("\(err) code=\(wallArmCode) reason=\(reason) label=\(app.userLabel) \(nextDesc)", forKey: wallArmSummaryKey)
                return err
            }
        } else {
            nextDesc = "next=nil"
        }

        if untilEndS > wallSecs + 20 * 60 {
            let err = "wall_arm_rejected_far_end until_end_s=\(untilEndS) wall_s=\(wallSecs)"
            suite?.set("\(err) code=\(wallArmCode) reason=\(reason) label=\(app.userLabel) \(nextDesc)", forKey: wallArmSummaryKey)
            return err
        }

        let padPastS = max(0, Int(now.timeIntervalSince(startDate)))
        let continuedAt = iso.string(from: now)
        let endAt = iso.string(from: endDate)
        var map = loadPendingMap()
        map[app.id.uuidString] = PendingWall(
            appID: app.id.uuidString,
            label: app.userLabel,
            wallSeconds: wallSecs,
            endAt: endAt,
            continuedAt: continuedAt
        )
        savePendingMap(map)
        // Legacy mirrors (last armed app) for older status readers.
        suite?.set(app.id.uuidString, forKey: wallPendingIdKey)
        suite?.set(app.userLabel, forKey: wallPendingLabelKey)
        suite?.set(wallSecs, forKey: wallSecondsKey)
        suite?.set(endAt, forKey: wallEndAtKey)
        suite?.set(continuedAt, forKey: continueSessionAtKey)

        do {
            try center.startMonitoring(activity, during: schedule, events: [:])
            let pendingLabels = map.values.map(\.label).sorted().joined(separator: ",")
            let summary = "wall_arm_ok code=\(wallArmCode) reason=\(reason) label=\(app.userLabel) usage_s=\(usage) wall_s=\(wallSecs) span_m=\(spanMinutes) pad_past_s=\(padPastS) until_end_s=\(untilEndS) end=\(endAt) pending=[\(pendingLabels)] \(nextDesc)"
            suite?.set(summary, forKey: wallArmSummaryKey)
            return next == nil ? "wall_armed_but_nextInterval_nil" : nil
        } catch {
            let err = String(describing: error)
            map.removeValue(forKey: app.id.uuidString)
            savePendingMap(map)
            suite?.set("wall_arm_failed code=\(wallArmCode) reason=\(reason) label=\(app.userLabel) error=\(err) wall_s=\(wallSecs) span_m=\(spanMinutes) \(nextDesc)", forKey: wallArmSummaryKey)
            return err
        }
    }

    static func loadPendingMap() -> [String: PendingWall] {
        guard let data = suite?.data(forKey: wallPendingMapKey),
              let decoded = try? JSONDecoder().decode([String: PendingWall].self, from: data)
        else { return [:] }
        return decoded
    }

    static func savePendingMap(_ map: [String: PendingWall]) {
        if map.isEmpty {
            suite?.removeObject(forKey: wallPendingMapKey)
            return
        }
        if let data = try? JSONEncoder().encode(map) {
            suite?.set(data, forKey: wallPendingMapKey)
        }
    }

    static func pendingWall(forAppID id: UUID) -> PendingWall? {
        loadPendingMap()[id.uuidString]
    }

    static func pendingWallAppIDs() -> Set<UUID> {
        Set(loadPendingMap().keys.compactMap { UUID(uuidString: $0) })
    }

    /// Clear one app's wall, or all if `appID` is nil.
    static func clearWallPending(reason: String, appID: UUID? = nil) {
        let center = DeviceActivityCenter()
        var map = loadPendingMap()
        if let appID {
            map.removeValue(forKey: appID.uuidString)
            center.stopMonitoring([wallActivityName(forAppID: appID)])
            suite?.set("wall_cleared reason=\(reason) label_id=\(appID.uuidString) remaining=\(map.count)", forKey: wallArmSummaryKey)
        } else {
            let names = map.keys.compactMap { UUID(uuidString: $0) }.map { wallActivityName(forAppID: $0) }
            if !names.isEmpty {
                center.stopMonitoring(names)
            }
            center.stopMonitoring([wallActivityName])
            map.removeAll()
            suite?.removeObject(forKey: wallPendingIdKey)
            suite?.removeObject(forKey: wallPendingLabelKey)
            suite?.set("wall_cleared reason=\(reason) all", forKey: wallArmSummaryKey)
        }
        savePendingMap(map)
        if let last = map.values.sorted(by: { $0.continuedAt > $1.continuedAt }).first {
            suite?.set(last.appID, forKey: wallPendingIdKey)
            suite?.set(last.label, forKey: wallPendingLabelKey)
            suite?.set(last.wallSeconds, forKey: wallSecondsKey)
            suite?.set(last.endAt, forKey: wallEndAtKey)
        } else {
            suite?.removeObject(forKey: wallPendingIdKey)
            suite?.removeObject(forKey: wallPendingLabelKey)
        }
    }

    static func pendingWallAppID() -> UUID? {
        if let id = pendingWallAppIDs().first { return id }
        guard let raw = suite?.string(forKey: wallPendingIdKey) else { return nil }
        return UUID(uuidString: raw)
    }

    static func statusLine() -> String {
        let summary = suite?.string(forKey: lastArmSummaryKey) ?? "never_armed"
        let wall = suite?.string(forKey: wallArmSummaryKey) ?? "wall_never"
        let close = suite?.string(forKey: lastHybridCloseKey) ?? "none"
        let pending = loadPendingMap().values.map(\.label).sorted().joined(separator: ",")
        let pendingNote = pending.isEmpty ? "pending=none" : "pending=[\(pending)]"
        return "\(summary) | \(wall) | \(pendingNote) | last_close=\(close)"
    }
}
