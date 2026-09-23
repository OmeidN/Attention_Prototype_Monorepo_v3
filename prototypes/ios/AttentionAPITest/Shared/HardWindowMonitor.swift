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
        /// New DeviceActivity name per Continue. `repeats: false` will not fire `intervalDidEnd` again on the same name.
        var session: Int
        /// Absolute seconds since 1970. Due checks prefer these over ISO strings.
        var continuedAtEpoch: TimeInterval
        var endAtEpoch: TimeInterval

        init(
            appID: String,
            label: String,
            wallSeconds: Int,
            endAt: String,
            continuedAt: String,
            session: Int,
            continuedAtEpoch: TimeInterval = 0,
            endAtEpoch: TimeInterval = 0
        ) {
            self.appID = appID
            self.label = label
            self.wallSeconds = wallSeconds
            self.endAt = endAt
            self.continuedAt = continuedAt
            self.session = session
            self.continuedAtEpoch = continuedAtEpoch
            self.endAtEpoch = endAtEpoch
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            appID = try c.decode(String.self, forKey: .appID)
            label = try c.decode(String.self, forKey: .label)
            wallSeconds = try c.decode(Int.self, forKey: .wallSeconds)
            endAt = try c.decode(String.self, forKey: .endAt)
            continuedAt = try c.decode(String.self, forKey: .continuedAt)
            session = try c.decodeIfPresent(Int.self, forKey: .session) ?? 0
            continuedAtEpoch = try c.decodeIfPresent(TimeInterval.self, forKey: .continuedAtEpoch) ?? 0
            endAtEpoch = try c.decodeIfPresent(TimeInterval.self, forKey: .endAtEpoch) ?? 0
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(appID, forKey: .appID)
            try c.encode(label, forKey: .label)
            try c.encode(wallSeconds, forKey: .wallSeconds)
            try c.encode(endAt, forKey: .endAt)
            try c.encode(continuedAt, forKey: .continuedAt)
            try c.encode(session, forKey: .session)
            try c.encode(continuedAtEpoch, forKey: .continuedAtEpoch)
            try c.encode(endAtEpoch, forKey: .endAtEpoch)
        }

        private enum CodingKeys: String, CodingKey {
            case appID, label, wallSeconds, endAt, continuedAt, session, continuedAtEpoch, endAtEpoch
        }
    }

    static let wallSessionCounterKey = "attention.p05b.wall_session_counter"

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
    static let wallArmCode = "wall_multi_v7"
    /// App Group file. UserDefaults in the monitor extension can serve a stale pending map.
    static let pendingFileName = "wall_pending_v6.json"
    static let earlyRearmCountKeyPrefix = "attention.p05b.early_rearm."
    static let maxEarlyRearms = 2
    /// Written by the monitor extension on every wall callback so a screenshot shows which extension binary ran.
    static let monitorBuildKey = "attention.p05b.monitor_build"
    /// True while `armWallClock` is stopping or starting. A synchronous `intervalDidEnd` from that stop must not close the new wall.
    private static var isArmingWall = false
    static var suppressWallCallbacks: Bool { isArmingWall }
    /// Ignore intervalDidEnd this many seconds before the armed end. Stale callbacks from the
    /// schedule we just replaced were re-shielding ~20–40s after Continue and clearing the new wall.
    static let wallEarlyIgnoreSlackSeconds = 20

    /// Stable name used before per-Continue sessions. Stop it so an old registration cannot close the new one.
    static func wallActivityName(forAppID id: UUID) -> DeviceActivityName {
        DeviceActivityName("\(wallActivityPrefix)\(id.uuidString)")
    }

    static func wallActivityName(appID: UUID, session: Int, endEpoch: Int = 0) -> DeviceActivityName {
        if endEpoch > 0 {
            return DeviceActivityName("\(wallActivityPrefix)\(appID.uuidString).\(session).\(endEpoch)")
        }
        return DeviceActivityName("\(wallActivityPrefix)\(appID.uuidString).\(session)")
    }

    static func nextWallSession() -> Int {
        let next = (suite?.object(forKey: wallSessionCounterKey) as? Int ?? 0) + 1
        suite?.set(next, forKey: wallSessionCounterKey)
        return next
    }

    /// `attention.p05b.wall.<uuid>` · `<uuid>.<session>` · `<uuid>.<session>.<endEpoch>`.
    static func parseWallActivity(_ raw: String) -> (appID: UUID, session: Int?, endEpoch: TimeInterval?)? {
        guard raw.hasPrefix(wallActivityPrefix) else { return nil }
        let rest = String(raw.dropFirst(wallActivityPrefix.count))
        let parts = rest.split(separator: ".").map(String.init)
        if parts.count >= 3,
           let id = UUID(uuidString: parts[0]),
           let session = Int(parts[1]),
           let endEpoch = TimeInterval(parts[2]) {
            return (id, session, endEpoch)
        }
        if parts.count == 2,
           let id = UUID(uuidString: parts[0]),
           let session = Int(parts[1]) {
            return (id, session, nil)
        }
        if let id = UUID(uuidString: rest) {
            return (id, nil, nil)
        }
        return nil
    }

    static func appID(fromWallActivityRaw raw: String) -> UUID? {
        if let parsed = parseWallActivity(raw) { return parsed.appID }
        if raw == wallActivityRaw { return pendingWallAppID() }
        return nil
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
        isArmingWall = true
        defer { isArmingWall = false }
        let center = DeviceActivityCenter()
        let session = nextWallSession()
        let previous = loadPendingMap()[app.id.uuidString]
        // Do not stopMonitoring first. That delivers intervalDidEnd for the old name and
        // was clearing the wall we are about to arm (~30s later, stale pending).

        let usage = max(15, app.windowDurationSeconds)
        let wallSecs = wallClockSeconds(forUsageWindowSeconds: usage)
        let calendar = Calendar.current
        let now = Date()
        let dayStart = calendar.startOfDay(for: now)
        let iso = ISO8601DateFormatter()

        let keepPriorEnd = reason.hasPrefix("early_rearm")
            && (previous?.endAtEpoch ?? 0) > now.timeIntervalSince1970 + 25
        let endTarget = keepPriorEnd
            ? Date(timeIntervalSince1970: previous?.endAtEpoch ?? now.timeIntervalSince1970)
            : now.addingTimeInterval(TimeInterval(wallSecs))
        guard var endDate = keepPriorEnd ? endTarget : calendar.date(bySetting: .second, value: 0, of: endTarget) else {
            let msg = "wall_arm_failed reason=\(reason) error=date_math code=\(wallArmCode) label=\(app.userLabel)"
            suite?.set(msg, forKey: wallArmSummaryKey)
            return "date_math"
        }
        if !keepPriorEnd, endDate.timeIntervalSince(now) < TimeInterval(wallSecs) {
            endDate = calendar.date(byAdding: .minute, value: 1, to: endDate) ?? endDate
        }
        if !keepPriorEnd {
            endDate = uniquedEndDate(desired: endDate, excludingAppID: app.id, calendar: calendar)
        }

        let startPad = deviceActivityMinIntervalSeconds + ((session % 5) * 60)
        var startDate = endDate.addingTimeInterval(-TimeInterval(startPad))
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
        if !keepPriorEnd {
            endDate = uniquedEndDate(desired: endDate, excludingAppID: app.id, calendar: calendar)
            startDate = endDate.addingTimeInterval(-TimeInterval(startPad))
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
        let continuedEpoch = (reason.hasPrefix("early_rearm") && (previous?.continuedAtEpoch ?? 0) > 0)
            ? (previous?.continuedAtEpoch ?? now.timeIntervalSince1970)
            : now.timeIntervalSince1970
        let continuedAt = iso.string(from: Date(timeIntervalSince1970: continuedEpoch))
        let endAt = iso.string(from: endDate)
        let pending = PendingWall(
            appID: app.id.uuidString,
            label: app.userLabel,
            wallSeconds: wallSecs,
            endAt: endAt,
            continuedAt: continuedAt,
            session: session,
            continuedAtEpoch: continuedEpoch,
            endAtEpoch: endDate.timeIntervalSince1970
        )
        _ = mutatePendingMap { map in
            map[app.id.uuidString] = pending
            return true
        }
        // Live marker first so a stopMonitoring-delivered intervalDidEnd can see the new session.
        writeLiveMarker(appID: app.id, session: session, endEpoch: endDate.timeIntervalSince1970)
        // Legacy mirrors (last armed app) for older status readers.
        suite?.set(app.id.uuidString, forKey: wallPendingIdKey)
        suite?.set(app.userLabel, forKey: wallPendingLabelKey)
        suite?.set(wallSecs, forKey: wallSecondsKey)
        suite?.set(endAt, forKey: wallEndAtKey)
        suite?.set(continuedAt, forKey: continueSessionAtKey)
        if reason == "continue" {
            setEarlyRearmCount(0, appID: app.id)
        }

        let activity = wallActivityName(appID: app.id, session: session, endEpoch: Int(endDate.timeIntervalSince1970))

        do {
            try center.startMonitoring(activity, during: schedule, events: [:])
            // Always drop this app's prior names. A leftover session's intervalDidEnd
            // arriving after the next Continue was wiping the new pending row.
            if let previous {
                var old = [
                    wallActivityName(appID: app.id, session: previous.session),
                    wallActivityName(forAppID: app.id)
                ]
                if previous.endAtEpoch > 0 {
                    old.append(wallActivityName(appID: app.id, session: previous.session, endEpoch: Int(previous.endAtEpoch)))
                }
                center.stopMonitoring(old)
            }
            let pendingLabels = loadPendingMap().values.map(\.label).sorted().joined(separator: ",")
            let summary = "wall_arm_ok code=\(wallArmCode) reason=\(reason) label=\(app.userLabel) session=\(session) usage_s=\(usage) wall_s=\(wallSecs) span_m=\(spanMinutes) pad_past_s=\(padPastS) until_end_s=\(untilEndS) end=\(endAt) pending=[\(pendingLabels)] \(nextDesc)"
            suite?.set(summary, forKey: wallArmSummaryKey)
            return next == nil ? "wall_armed_but_nextInterval_nil" : nil
        } catch {
            let err = String(describing: error)
            _ = mutatePendingMap { map in
                if map[app.id.uuidString]?.session == session {
                    map.removeValue(forKey: app.id.uuidString)
                    return true
                }
                return false
            }
            suite?.set("wall_arm_failed code=\(wallArmCode) reason=\(reason) label=\(app.userLabel) error=\(err) wall_s=\(wallSecs) span_m=\(spanMinutes) \(nextDesc)", forKey: wallArmSummaryKey)
            return err
        }
    }

    static var pendingFileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: ExperimentStore.appGroupID)?
            .appendingPathComponent(pendingFileName)
    }

    static func liveMarkerURL(appID: UUID) -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: ExperimentStore.appGroupID)?
            .appendingPathComponent("wall_live_\(appID.uuidString).txt")
    }

    static func writeLiveMarker(appID: UUID, session: Int, endEpoch: TimeInterval) {
        guard let url = liveMarkerURL(appID: appID),
              let data = "\(session) \(Int(endEpoch))\n".data(using: .utf8)
        else { return }
        writeCoordinated(data, to: url)
    }

    static func readLiveMarker(appID: UUID) -> (session: Int, endEpoch: TimeInterval)? {
        guard let url = liveMarkerURL(appID: appID),
              let data = readCoordinated(url),
              let raw = String(data: data, encoding: .utf8)
        else { return nil }
        let parts = raw.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
        guard parts.count >= 2, let session = Int(parts[0]), let end = TimeInterval(parts[1]) else { return nil }
        return (session, end)
    }

    static func removeLiveMarker(appID: UUID) {
        guard let url = liveMarkerURL(appID: appID) else { return }
        let coordinator = NSFileCoordinator()
        var error: NSError?
        coordinator.coordinate(writingItemAt: url, options: .forDeleting, error: &error) { url in
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// DeviceActivitySchedule is hour:minute only. Two walls that snap to the same minute
    /// share one interval; `repeats: false` then delivers at most one `intervalDidEnd`.
    static func uniquedEndDate(desired: Date, excludingAppID: UUID, calendar: Calendar) -> Date {
        var end = desired
        let usedMinutes = Set(
            loadPendingMap().values.compactMap { entry -> Int? in
                guard entry.appID != excludingAppID.uuidString, entry.endAtEpoch > 0 else { return nil }
                return Int(entry.endAtEpoch) / 60
            }
        )
        var guardCount = 0
        while usedMinutes.contains(Int(end.timeIntervalSince1970) / 60), guardCount < 8 {
            end = calendar.date(byAdding: .minute, value: 1, to: end) ?? end
            guardCount += 1
        }
        return end
    }

    private static func readCoordinated(_ url: URL) -> Data? {
        var result: Data?
        let coordinator = NSFileCoordinator()
        var error: NSError?
        coordinator.coordinate(readingItemAt: url, options: [], error: &error) { url in
            result = try? Data(contentsOf: url, options: .uncached)
        }
        return result
    }

    private static func writeCoordinated(_ data: Data, to url: URL) {
        let coordinator = NSFileCoordinator()
        var error: NSError?
        coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: &error) { url in
            try? data.write(to: url, options: .atomic)
        }
    }

    /// Read-modify-write under a file coordinator so a stale monitor snapshot cannot
    /// overwrite a newer Continue wall that the shield-action extension just wrote.
    @discardableResult
    static func mutatePendingMap(_ body: (inout [String: PendingWall]) -> Bool) -> Bool {
        guard let url = pendingFileURL else { return false }
        var committed = false
        let coordinator = NSFileCoordinator()
        var error: NSError?
        coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: &error) { url in
            var map: [String: PendingWall] = [:]
            if let data = try? Data(contentsOf: url, options: .uncached),
               let decoded = try? JSONDecoder().decode([String: PendingWall].self, from: data) {
                map = decoded
            }
            guard body(&map) else { return }
            persistPendingMap(map, fileURL: url)
            committed = true
        }
        return committed
    }

    static func loadPendingMap() -> [String: PendingWall] {
        if let url = pendingFileURL,
           let data = readCoordinated(url),
           let decoded = try? JSONDecoder().decode([String: PendingWall].self, from: data) {
            return decoded
        }
        return [:]
    }

    static func savePendingMap(_ map: [String: PendingWall]) {
        guard let url = pendingFileURL,
              let data = try? JSONEncoder().encode(map)
        else { return }
        writeCoordinated(data, to: url)
        persistPendingMapDefaults(map)
    }

    private static func persistPendingMap(_ map: [String: PendingWall], fileURL: URL) {
        if let data = try? JSONEncoder().encode(map) {
            try? data.write(to: fileURL, options: .atomic)
        }
        persistPendingMapDefaults(map)
    }

    private static func persistPendingMapDefaults(_ map: [String: PendingWall]) {
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

    /// True when this app's armed wall is allowed to close. Early = stale callback; do not clear pending.
    static func wallEndIsDue(appID: UUID, now: Date = Date()) -> (due: Bool, note: String) {
        guard let pending = pendingWall(forAppID: appID) else {
            return (false, "wall_ignored_no_pending id=\(appID.uuidString)")
        }
        let remaining: Int
        let elapsed: Int
        if pending.endAtEpoch > 0, pending.continuedAtEpoch > 0 {
            let nowEpoch = now.timeIntervalSince1970
            remaining = Int(pending.endAtEpoch - nowEpoch)
            elapsed = max(0, Int(nowEpoch - pending.continuedAtEpoch))
        } else if let end = ISO8601DateFormatter().date(from: pending.endAt) {
            remaining = Int(end.timeIntervalSince(now))
            if let started = ISO8601DateFormatter().date(from: pending.continuedAt) {
                elapsed = max(0, Int(now.timeIntervalSince(started)))
            } else {
                elapsed = 0
            }
        } else {
            return (false, "wall_ignored_bad_end label=\(pending.label) end=\(pending.endAt)")
        }
        // Product wall is `wallSeconds`. Minute snap can add up to ~60s, never subtract a whole window.
        // A callback ~30s after Continue must not count, even if `endAt` was misread.
        let minElapsed = max(15, pending.wallSeconds - wallEarlyIgnoreSlackSeconds)
        if elapsed < minElapsed || remaining > wallEarlyIgnoreSlackSeconds {
            return (false, "wall_ignored_early label=\(pending.label) session=\(pending.session) elapsed_s=\(elapsed) min_elapsed_s=\(minElapsed) remaining_s=\(remaining) end=\(pending.endAt)")
        }
        return (true, "wall_due label=\(pending.label) session=\(pending.session) elapsed_s=\(elapsed) remaining_s=\(remaining) end=\(pending.endAt)")
    }

    static func earlyRearmCount(appID: UUID) -> Int {
        suite?.object(forKey: earlyRearmCountKeyPrefix + appID.uuidString) as? Int ?? 0
    }

    static func setEarlyRearmCount(_ count: Int, appID: UUID) {
        suite?.set(count, forKey: earlyRearmCountKeyPrefix + appID.uuidString)
    }

    static func pendingWallAppIDs() -> Set<UUID> {
        Set(loadPendingMap().keys.compactMap { UUID(uuidString: $0) })
    }

    /// Clear one app's wall, or all if `appID` is nil.
    /// `expectedSession` must match the session on disk. A late callback for an older session must not delete a newer arm.
    @discardableResult
    static func clearWallPending(reason: String, appID: UUID? = nil, expectedSession: Int? = nil) -> Bool {
        if let appID, let expectedSession {
            let disk = loadPendingMap()[appID.uuidString]?.session
            if disk != expectedSession {
                suite?.set(
                    "wall_clear_aborted reason=\(reason) expected_session=\(expectedSession) disk_session=\(disk.map(String.init) ?? "none")",
                    forKey: wallArmSummaryKey
                )
                return false
            }
        }
        let center = DeviceActivityCenter()
        var removed: PendingWall?
        var clearedAll: [PendingWall] = []
        var remainingCount = 0
        let wrote = mutatePendingMap { map in
            if let appID {
                if let expectedSession, map[appID.uuidString]?.session != expectedSession {
                    return false
                }
                removed = map.removeValue(forKey: appID.uuidString)
                remainingCount = map.count
                return true
            }
            clearedAll = Array(map.values)
            remainingCount = 0
            map.removeAll()
            return true
        }
        if !wrote {
            let disk = appID.flatMap { loadPendingMap()[$0.uuidString]?.session }
            suite?.set(
                "wall_clear_aborted reason=\(reason) expected_session=\(expectedSession.map(String.init) ?? "none") disk_session=\(disk.map(String.init) ?? "none")",
                forKey: wallArmSummaryKey
            )
            return false
        }
        if let appID {
            removeLiveMarker(appID: appID)
            var names = [wallActivityName(forAppID: appID)]
            if let removed {
                names.append(wallActivityName(appID: appID, session: removed.session))
                if removed.endAtEpoch > 0 {
                    names.append(wallActivityName(appID: appID, session: removed.session, endEpoch: Int(removed.endAtEpoch)))
                }
            }
            center.stopMonitoring(names)
            let detail: String
            if let removed {
                detail = "label=\(removed.label) session=\(removed.session) end=\(removed.endAt) continued=\(removed.continuedAt)"
            } else {
                detail = "label_id=\(appID.uuidString)"
            }
            suite?.set("wall_cleared reason=\(reason) \(detail) remaining=\(remainingCount)", forKey: wallArmSummaryKey)
        } else {
            var names: [DeviceActivityName] = []
            for entry in clearedAll {
                guard let id = UUID(uuidString: entry.appID) else { continue }
                removeLiveMarker(appID: id)
                names.append(wallActivityName(forAppID: id))
                names.append(wallActivityName(appID: id, session: entry.session))
                if entry.endAtEpoch > 0 {
                    names.append(wallActivityName(appID: id, session: entry.session, endEpoch: Int(entry.endAtEpoch)))
                }
            }
            if !names.isEmpty {
                center.stopMonitoring(names)
            }
            center.stopMonitoring([wallActivityName])
            suite?.removeObject(forKey: wallPendingIdKey)
            suite?.removeObject(forKey: wallPendingLabelKey)
            suite?.set("wall_cleared reason=\(reason) all", forKey: wallArmSummaryKey)
        }
        let map = loadPendingMap()
        if let last = map.values.sorted(by: { $0.continuedAt > $1.continuedAt }).first {
            suite?.set(last.appID, forKey: wallPendingIdKey)
            suite?.set(last.label, forKey: wallPendingLabelKey)
            suite?.set(last.wallSeconds, forKey: wallSecondsKey)
            suite?.set(last.endAt, forKey: wallEndAtKey)
        } else {
            suite?.removeObject(forKey: wallPendingIdKey)
            suite?.removeObject(forKey: wallPendingLabelKey)
        }
        return true
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
        let monitor = suite?.string(forKey: monitorBuildKey) ?? "monitor_build=none"
        return "\(summary) | \(wall) | \(pendingNote) | \(monitor) | last_close=\(close)"
    }
}
