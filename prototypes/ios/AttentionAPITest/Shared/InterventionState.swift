import Foundation
import ManagedSettings

/// Per-app Continue / Never Mind counts for today (local calendar). Drives shield friction levels (M11).
enum InterventionState {
    static let dayKey = "attention.m11.local_day"
    static let continuePrefix = "attention.m11.continue_count."
    static let neverMindPrefix = "attention.m11.never_mind_count."
    static let lastLevelKey = "attention.m11.last_level_shown"
    static let lastLevelAppKey = "attention.m11.last_level_app"
    static let trustNoteKey = "attention.m11.trustworthiness_note"
    static let fallbackBanner =
        "If extension state fails, production should use one shield and move progression to goals/XP."

    static var suite: UserDefaults? { ShieldCopySettings.suite }

    /// Level from today's Continue count for that app (before this choice increments).
    /// 0 Continues → L0; 1–2 → L1; ≥3 → L2.
    static func level(forContinueCount count: Int) -> Int {
        if count <= 0 { return 0 }
        if count <= 2 { return 1 }
        return 2
    }

    static func mappingDescription() -> String {
        "per-app continues_today 0→L0 soft | 1–2→L1 reminder | ≥3→L2 are-you-sure (copy/icon only; no Continue delay API)"
    }

    static func todayString() -> String {
        let cal = Calendar.current
        let parts = cal.dateComponents([.year, .month, .day], from: Date())
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// Ensures local-day key is current. Returns `true` if the day rolled over and counts were cleared.
    @discardableResult
    static func ensureToday() -> Bool {
        let today = todayString()
        let stored = suite?.string(forKey: dayKey)
        if stored != today {
            clearAllCounts()
            suite?.set(today, forKey: dayKey)
            return stored != nil // true only if we had a previous day (not first install)
        }
        return false
    }

    static func trackedAppID(for token: ApplicationToken) -> UUID? {
        guard let data = suite?.data(forKey: ShieldCopySettings.trackedAppsKey),
              let apps = try? JSONDecoder().decode([TrackedApp].self, from: data)
        else { return nil }
        return apps.first(where: { $0.token == token })?.id
    }

    static func continueCount(appID: UUID) -> Int {
        ensureToday()
        suite?.synchronize()
        let stored = suite?.integer(forKey: continuePrefix + appID.uuidString) ?? 0
        // Shield copy must match Home. Home uses TodayEventLog; the prefix
        // counter can stay 0 if a process missed a write or UserDefaults lagged.
        let logged = TodayEventLog.events(on: Date()).filter {
            $0.type == "continue" && $0.trackedAppId == appID
        }.count
        return max(stored, logged)
    }

    static func neverMindCount(appID: UUID) -> Int {
        ensureToday()
        return suite?.integer(forKey: neverMindPrefix + appID.uuidString) ?? 0
    }

    static func level(for appID: UUID) -> Int {
        level(forContinueCount: continueCount(appID: appID))
    }

    /// Returns (previousLevel, nextLevel, continueCountAfter).
    @discardableResult
    static func recordContinue(appID: UUID?) -> (prev: Int, next: Int, count: Int) {
        ensureToday()
        guard let appID else { return (0, 0, 0) }
        let stored = suite?.integer(forKey: continuePrefix + appID.uuidString) ?? 0
        let prev = level(forContinueCount: stored)
        let nextCount = stored + 1
        suite?.set(nextCount, forKey: continuePrefix + appID.uuidString)
        suite?.synchronize()
        let next = level(forContinueCount: nextCount)
        return (prev, next, nextCount)
    }

    @discardableResult
    static func recordNeverMind(appID: UUID?) -> Int {
        ensureToday()
        guard let appID else { return 0 }
        let n = neverMindCount(appID: appID) + 1
        suite?.set(n, forKey: neverMindPrefix + appID.uuidString)
        return n
    }

    static func debugBumpContinue(appID: UUID) -> (prev: Int, next: Int, count: Int) {
        recordContinue(appID: appID)
    }

    static func resetToday() {
        clearAllCounts()
        suite?.set(todayString(), forKey: dayKey)
    }

    /// TEMP DEBUG (remove later): zero Continue / Never Mind counts for one tracked app today.
    static func resetCounts(appID: UUID) {
        ensureToday()
        suite?.removeObject(forKey: continuePrefix + appID.uuidString)
        suite?.removeObject(forKey: neverMindPrefix + appID.uuidString)
    }

    static func setTrustNote(_ note: String) {
        suite?.set(note, forKey: trustNoteKey)
    }

    static func trustNote() -> String {
        suite?.string(forKey: trustNoteKey) ?? ""
    }

    static func markLevelShown(level: Int, label: String) {
        suite?.set(level, forKey: lastLevelKey)
        suite?.set(label, forKey: lastLevelAppKey)
    }

    static func statusSummary(apps: [TrackedApp]) -> String {
        ensureToday()
        let day = suite?.string(forKey: dayKey) ?? todayString()
        let rows = apps.map { app in
            let c = continueCount(appID: app.id)
            let n = neverMindCount(appID: app.id)
            let lvl = level(forContinueCount: c)
            return "\(app.userLabel): continues=\(c) never_mind=\(n) level=\(lvl)"
        }.joined(separator: "\n")
        let lastLvl = suite?.object(forKey: lastLevelKey) as? Int
        let lastApp = suite?.string(forKey: lastLevelAppKey) ?? "?"
        return """
        local_day=\(day)
        \(mappingDescription())
        \(rows.isEmpty ? "(no tracked apps)" : rows)
        last_shield_level_shown=\(lastLvl.map(String.init) ?? "none") app=\(lastApp)
        fallback: \(fallbackBanner)
        """
    }

    private static func clearAllCounts() {
        guard let suite else { return }
        for key in suite.dictionaryRepresentation().keys {
            if key.hasPrefix(continuePrefix) || key.hasPrefix(neverMindPrefix) {
                suite.removeObject(forKey: key)
            }
        }
    }
}
