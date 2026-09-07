import Foundation
import ManagedSettings

/// One Intentional Choice (Never Mind) or Continue event from the shield action extension.
struct ShieldActionEvent: Codable, Equatable, Identifiable {
    var id: UUID { eventId }
    let eventId: UUID
    let trackedAppId: UUID?
    let userLabel: String?
    /// `never_mind` or `continue`
    let action: String
    let timestamp: Date
}

/// App Group bridge between ShieldActionExtension and the host app (M06).
enum ShieldActionBridge {
    static let lastActionKey = "attention.m06.last_shield_action"
    static let lastActionAtKey = "attention.m06.last_shield_action_at"
    static let lastActionIdKey = "attention.m06.last_shield_action_tracked_id"
    static let lastActionLabelKey = "attention.m06.last_shield_action_label"
    static let lastHostSeenAtKey = "attention.m06.last_action_host_seen_at"
    static let eventsKey = "attention.m06.intentional_and_continue_events"
    static let hostNeededNoteKey = "attention.m06.host_app_needed_note"

    static var suite: UserDefaults? { ShieldCopySettings.suite }

    static func trackedApp(for token: ApplicationToken) -> TrackedApp? {
        guard let data = suite?.data(forKey: ShieldCopySettings.trackedAppsKey),
              let apps = try? JSONDecoder().decode([TrackedApp].self, from: data)
        else { return nil }
        return apps.first(where: { $0.token == token })
    }

    static func record(action: String, token: ApplicationToken) -> ShieldActionEvent {
        let app = trackedApp(for: token)
        let now = Date()
        let event = ShieldActionEvent(
            eventId: UUID(),
            trackedAppId: app?.id,
            userLabel: app?.userLabel,
            action: action,
            timestamp: now
        )

        suite?.set(action, forKey: lastActionKey)
        suite?.set(ISO8601DateFormatter().string(from: now), forKey: lastActionAtKey)
        if let id = app?.id {
            suite?.set(id.uuidString, forKey: lastActionIdKey)
        }
        if let label = app?.userLabel {
            suite?.set(label, forKey: lastActionLabelKey)
        }

        var events = loadEvents()
        events.append(event)
        if events.count > 200 {
            events.removeFirst(events.count - 200)
        }
        if let data = try? JSONEncoder().encode(events) {
            suite?.set(data, forKey: eventsKey)
        }

        return event
    }

    static func loadEvents() -> [ShieldActionEvent] {
        guard let data = suite?.data(forKey: eventsKey),
              let decoded = try? JSONDecoder().decode([ShieldActionEvent].self, from: data)
        else { return [] }
        return decoded
    }

    static func lastActionSummary() -> String {
        let action = suite?.string(forKey: lastActionKey) ?? "none"
        let at = suite?.string(forKey: lastActionAtKey) ?? "?"
        let label = suite?.string(forKey: lastActionLabelKey) ?? "NO_LABEL"
        let id = suite?.string(forKey: lastActionIdKey) ?? "nil"
        return "last_shield_action=\(action) label=\(label) id=\(id) at=\(at)"
    }

    /// Host calls when becoming active. Returns latency seconds if this is a newly seen action.
    static func consumeNewActionForHost() -> (summary: String, latencySeconds: TimeInterval?)? {
        guard let at = suite?.string(forKey: lastActionAtKey) else { return nil }
        let seen = suite?.string(forKey: lastHostSeenAtKey)
        guard at != seen else { return nil }
        suite?.set(at, forKey: lastHostSeenAtKey)

        var latency: TimeInterval?
        let formatter = ISO8601DateFormatter()
        if let actionAt = formatter.date(from: at) {
            latency = Date().timeIntervalSince(actionAt)
        }
        return (lastActionSummary(), latency)
    }
}
