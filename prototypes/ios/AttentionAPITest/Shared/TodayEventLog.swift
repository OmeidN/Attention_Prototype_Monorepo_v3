import Foundation

/// P06: one logged behavioral event for Today Home (not opens / not sessions).
struct TodayEvent: Codable, Equatable, Identifiable {
    let id: UUID
    /// `intentional_choice` | `continue` | `access_window_start` | `access_window_end` | `reshield_debug`
    let type: String
    let trackedAppId: UUID?
    let userLabel: String?
    let timestamp: Date
    /// Window length (seconds) when known — start planned duration or end elapsed.
    let durationSeconds: Int?
    let meta: String?
}

/// Append-only App Group event log for P06 ingest. Extensions + host both write here.
enum TodayEventLog {
    static let eventsKey = "attention.p06.events"
    static let maxEvents = 500

    static var suite: UserDefaults? { ShieldCopySettings.suite }

    static func append(
        type: String,
        trackedAppId: UUID?,
        userLabel: String?,
        durationSeconds: Int? = nil,
        meta: String? = nil,
        at: Date = Date(),
        id: UUID = UUID()
    ) {
        var events = load()
        // Dedup by id if caller reuses ShieldActionEvent.eventId
        if events.contains(where: { $0.id == id }) { return }
        events.append(
            TodayEvent(
                id: id,
                type: type,
                trackedAppId: trackedAppId,
                userLabel: userLabel,
                timestamp: at,
                durationSeconds: durationSeconds,
                meta: meta
            )
        )
        if events.count > maxEvents {
            events.removeFirst(events.count - maxEvents)
        }
        save(events)
    }

    static func load() -> [TodayEvent] {
        guard let data = suite?.data(forKey: eventsKey),
              let decoded = try? JSONDecoder().decode([TodayEvent].self, from: data)
        else { return [] }
        return decoded
    }

    static func save(_ events: [TodayEvent]) {
        guard let data = try? JSONEncoder().encode(events) else { return }
        suite?.set(data, forKey: eventsKey)
    }

    static func events(on day: Date, calendar: Calendar = .current) -> [TodayEvent] {
        load().filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
            .sorted { $0.timestamp > $1.timestamp }
    }

    static func exportText(limit: Int = 40) -> String {
        let day = events(on: Date())
        let lines = day.prefix(limit).map { e in
            let label = e.userLabel ?? "NO_LABEL"
            let dur = e.durationSeconds.map { " dur_s=\($0)" } ?? ""
            let meta = e.meta.map { " \($0)" } ?? ""
            return "\(ISO8601DateFormatter().string(from: e.timestamp)) \(e.type) label=\(label)\(dur)\(meta)"
        }
        return lines.isEmpty ? "(no Today events yet)" : lines.joined(separator: "\n")
    }
}

/// Aggregates honest Today metrics from `TodayEventLog` (P06).
@MainActor
final class TodayStatsStore: ObservableObject {
    static let shared = TodayStatsStore()

    struct AppBreakdown: Identifiable {
        var id: String { key }
        let key: String
        let label: String
        var neverMinds: Int
        var continues: Int
        var windows: Int
        var windowSeconds: Int
    }

    @Published private(set) var neverMindsToday = 0
    @Published private(set) var continuesToday = 0
    @Published private(set) var windowsToday = 0
    @Published private(set) var windowSecondsToday = 0
    @Published private(set) var perApp: [AppBreakdown] = []
    @Published private(set) var recent: [TodayEvent] = []
    @Published private(set) var lastIngestAt: String = "never"
    @Published private(set) var lastIngestNote: String = ""

    /// Ingest App Group shield events + window bridge cursors into `TodayEventLog`, then refresh counts.
    @discardableResult
    func ingest(reason: String) -> String {
        var added = 0

        // 1) Shield action queue → typed Today events (deduped by event id)
        for e in ShieldActionBridge.loadEvents() {
            let before = TodayEventLog.load().count
            let type: String
            if e.action == "intentional_choice" || e.action == "never_mind" {
                type = "intentional_choice"
            } else if e.action == "continue" {
                type = "continue"
            } else {
                type = e.action
            }
            TodayEventLog.append(
                type: type,
                trackedAppId: e.trackedAppId,
                userLabel: e.userLabel,
                at: e.timestamp,
                id: e.eventId
            )
            if TodayEventLog.load().count > before { added += 1 }
        }

        // 2) Window start cursor (extension may have begun window before host ran)
        let startAt = AccessWindowBridge.suite?.string(forKey: AccessWindowBridge.startedAtKey)
        let lastStart = AccessWindowBridge.suite?.string(forKey: Self.lastIngestedStartKey)
        if let startAt, startAt != lastStart {
            let dur = AccessWindowBridge.suite?.object(forKey: AccessWindowBridge.durationKey) as? Int
            let id = AccessWindowBridge.trackedId()
            let label = AccessWindowBridge.label()
            let ts = ISO8601DateFormatter().date(from: startAt) ?? Date()
            let already = TodayEventLog.load().contains {
                $0.type == "access_window_start" && abs($0.timestamp.timeIntervalSince(ts)) < 2
            }
            if !already {
                TodayEventLog.append(
                    type: "access_window_start",
                    trackedAppId: id,
                    userLabel: label,
                    durationSeconds: dur,
                    meta: "ingest_cursor",
                    at: ts
                )
                added += 1
            }
            AccessWindowBridge.suite?.set(startAt, forKey: Self.lastIngestedStartKey)
        }

        // 3) Re-shield / window end cursor
        let reshieldAt = AccessWindowBridge.suite?.string(forKey: AccessWindowBridge.lastReshieldAtKey)
        let lastEnd = AccessWindowBridge.suite?.string(forKey: Self.lastIngestedReshieldKey)
        if let reshieldAt, reshieldAt != lastEnd {
            let mech = AccessWindowBridge.suite?.string(forKey: AccessWindowBridge.lastReshieldMechanismKey) ?? "?"
            let planned = AccessWindowBridge.suite?.object(forKey: AccessWindowBridge.durationKey) as? Int
            var elapsed = planned
            if let startRaw = AccessWindowBridge.suite?.string(forKey: AccessWindowBridge.startedAtKey),
               let start = ISO8601DateFormatter().date(from: startRaw),
               let end = ISO8601DateFormatter().date(from: reshieldAt) {
                elapsed = max(0, Int(end.timeIntervalSince(start)))
            }
            let endTs = ISO8601DateFormatter().date(from: reshieldAt) ?? Date()
            let alreadyEnd = TodayEventLog.load().contains {
                $0.type == "access_window_end" && abs($0.timestamp.timeIntervalSince(endTs)) < 2
            }
            if !alreadyEnd {
                TodayEventLog.append(
                    type: "access_window_end",
                    trackedAppId: AccessWindowBridge.trackedId(),
                    userLabel: AccessWindowBridge.label(),
                    durationSeconds: elapsed,
                    meta: "mechanism=\(mech)",
                    at: endTs
                )
                TodayEventLog.append(
                    type: "reshield_debug",
                    trackedAppId: AccessWindowBridge.trackedId(),
                    userLabel: AccessWindowBridge.label(),
                    meta: mech,
                    at: endTs
                )
                added += 2
            }
            AccessWindowBridge.suite?.set(reshieldAt, forKey: Self.lastIngestedReshieldKey)
        }

        refreshCounts()
        lastIngestAt = TestLogger.isoString(Date())
        lastIngestNote = "reason=\(reason) added≈\(added) today_events=\(recent.count)"
        TestLogger.shared.log("ATTN-P06", "ingest \(lastIngestNote)")
        return lastIngestNote
    }

    func refreshCounts() {
        let today = TodayEventLog.events(on: Date())
        recent = Array(today.prefix(30))
        neverMindsToday = today.filter { $0.type == "intentional_choice" }.count
        continuesToday = today.filter { $0.type == "continue" }.count
        let starts = today.filter { $0.type == "access_window_start" }
        let ends = today.filter { $0.type == "access_window_end" }
        windowsToday = max(starts.count, ends.count)
        windowSecondsToday = ends.compactMap(\.durationSeconds).reduce(0, +)
        if windowSecondsToday == 0 {
            // Fallback: planned durations from starts if ends not ingested yet
            windowSecondsToday = starts.compactMap(\.durationSeconds).reduce(0, +)
        }

        var map: [String: AppBreakdown] = [:]
        for e in today {
            let label = e.userLabel ?? "NO_LABEL"
            let key = e.trackedAppId?.uuidString ?? label
            var row = map[key] ?? AppBreakdown(
                key: key,
                label: label,
                neverMinds: 0,
                continues: 0,
                windows: 0,
                windowSeconds: 0
            )
            switch e.type {
            case "intentional_choice": row.neverMinds += 1
            case "continue": row.continues += 1
            case "access_window_start": row.windows += 1
            case "access_window_end":
                row.windowSeconds += e.durationSeconds ?? 0
            default: break
            }
            map[key] = row
        }
        perApp = map.values.sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
    }

    private static let lastIngestedStartKey = "attention.p06.last_ingested_window_start_at"
    private static let lastIngestedReshieldKey = "attention.p06.last_ingested_reshield_at"
}
