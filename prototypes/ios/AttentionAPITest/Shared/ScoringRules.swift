import Foundation

/// P07: simple local scoring weights (tune later). All inputs are logged events — never opens/Report.
enum ScoringRules {
    static let neverMindXP = 10
    static let continueXP = 0
    /// Bonus when access_window_end elapsed ≤ that window’s planned/preferred length.
    static let shortWindowBonusXP = 5

    static let goalNeverMindMin = 1
    static let goalNeverMindStretch = 3
    static let goalContinuesMax = 5
    static let goalWindowSecondsMax = 15 * 60

    static func weightsDescription() -> String {
        "NM=+\(neverMindXP) Cont=+\(continueXP) short_window=+\(shortWindowBonusXP) if end≤planned; goals: NM≥\(goalNeverMindMin)/≥\(goalNeverMindStretch), Cont≤\(goalContinuesMax), window≤\(goalWindowSecondsMax / 60)m"
    }

    /// XP awarded for a single event (0 if not scored).
    static func xp(for event: TodayEvent, preferredWindowSeconds: Int) -> Int {
        switch event.type {
        case "intentional_choice":
            return neverMindXP
        case "continue":
            return continueXP
        case "access_window_end":
            let elapsed = event.durationSeconds ?? Int.max
            let cap = max(15, preferredWindowSeconds)
            return elapsed <= cap ? shortWindowBonusXP : 0
        default:
            return 0
        }
    }

    static func totalXP(events: [TodayEvent], preferredWindowSeconds: Int) -> Int {
        events.reduce(0) { $0 + xp(for: $1, preferredWindowSeconds: preferredWindowSeconds) }
    }

    /// Consecutive local days ending today (or yesterday if today has no NM yet) with ≥1 intentional_choice.
    static func neverMindStreak(events: [TodayEvent], now: Date = Date(), calendar: Calendar = .current) -> (count: Int, lastDay: String?) {
        let nmDays: Set<DateComponents> = Set(
            events.filter { $0.type == "intentional_choice" }
                .map { calendar.dateComponents([.year, .month, .day], from: $0.timestamp) }
        )
        func dayString(_ dc: DateComponents) -> String {
            String(format: "%04d-%02d-%02d", dc.year ?? 0, dc.month ?? 0, dc.day ?? 0)
        }
        func hasNM(_ date: Date) -> Bool {
            let dc = calendar.dateComponents([.year, .month, .day], from: date)
            return nmDays.contains(dc)
        }

        var cursor = calendar.startOfDay(for: now)
        // If today has no Never Mind yet, streak can still show through yesterday.
        if !hasNM(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                return (0, nil)
            }
            cursor = yesterday
            if !hasNM(cursor) { return (0, nil) }
        }

        var count = 0
        var last: String?
        while hasNM(cursor) {
            count += 1
            last = dayString(calendar.dateComponents([.year, .month, .day], from: cursor))
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
            if count > 400 { break }
        }
        return (count, last)
    }

    struct DailyGoal: Identifiable, Equatable {
        let id: String
        let title: String
        let detail: String
        let done: Bool
        let progressLabel: String
    }

    static func dailyGoals(
        neverMinds: Int,
        continues: Int,
        windowSeconds: Int
    ) -> [DailyGoal] {
        [
            DailyGoal(
                id: "nm1",
                title: "At least 1 Never Mind",
                detail: "Intentional choice today",
                done: neverMinds >= goalNeverMindMin,
                progressLabel: "\(neverMinds)/\(goalNeverMindMin)"
            ),
            DailyGoal(
                id: "nm3",
                title: "3 Never Minds",
                detail: "Stretch intentional choices",
                done: neverMinds >= goalNeverMindStretch,
                progressLabel: "\(neverMinds)/\(goalNeverMindStretch)"
            ),
            DailyGoal(
                id: "cont",
                title: "≤ \(goalContinuesMax) Continues",
                detail: "Soft cap — not an opens metric",
                done: continues <= goalContinuesMax,
                progressLabel: "\(continues)/\(goalContinuesMax)"
            ),
            DailyGoal(
                id: "win",
                title: "≤ \(goalWindowSecondsMax / 60) min window time",
                detail: "Access window minutes today",
                done: windowSeconds <= goalWindowSecondsMax,
                progressLabel: "\(windowSeconds / 60)m/\(goalWindowSecondsMax / 60)m"
            ),
        ]
    }
}

/// Persists / republishes XP, streak, goals from `TodayEventLog` (recompute on ingest).
@MainActor
final class ScoringStore: ObservableObject {
    static let shared = ScoringStore()

    static let totalXPKey = "attention.p07.total_xp"
    static let dailyXPKey = "attention.p07.daily_xp"
    static let dailyXPDayKey = "attention.p07.daily_xp_day"
    static let streakKey = "attention.p07.streak"
    static let streakLastDayKey = "attention.p07.streak_last_day"
    static let lastAwardNoteKey = "attention.p07.last_award_note"

    @Published private(set) var totalXP = 0
    @Published private(set) var dailyXP = 0
    @Published private(set) var streak = 0
    @Published private(set) var streakLastDay: String?
    @Published private(set) var goals: [ScoringRules.DailyGoal] = []
    @Published private(set) var lastAwardNote = ""
    @Published private(set) var weightsLine = ScoringRules.weightsDescription()

    private var suite: UserDefaults? { ShieldCopySettings.suite }

    /// Recompute from full event log. Idempotent; safe after day changes.
    func recompute(
        neverMindsToday: Int,
        continuesToday: Int,
        windowSecondsToday: Int,
        reason: String
    ) {
        let preferred = AccessWindowBridge.preferredDurationSeconds()
        let all = TodayEventLog.load()
        let today = TodayEventLog.events(on: Date())

        let newTotal = ScoringRules.totalXP(events: all, preferredWindowSeconds: preferred)
        let newDaily = ScoringRules.totalXP(events: today, preferredWindowSeconds: preferred)
        let (streakCount, lastDay) = ScoringRules.neverMindStreak(events: all)
        let newGoals = ScoringRules.dailyGoals(
            neverMinds: neverMindsToday,
            continues: continuesToday,
            windowSeconds: windowSecondsToday
        )

        let prevTotal = suite?.object(forKey: Self.totalXPKey) as? Int ?? 0
        let delta = newTotal - prevTotal

        totalXP = newTotal
        dailyXP = newDaily
        streak = streakCount
        streakLastDay = lastDay
        goals = newGoals
        weightsLine = ScoringRules.weightsDescription()

        suite?.set(newTotal, forKey: Self.totalXPKey)
        suite?.set(newDaily, forKey: Self.dailyXPKey)
        suite?.set(InterventionState.todayString(), forKey: Self.dailyXPDayKey)
        suite?.set(streakCount, forKey: Self.streakKey)
        if let lastDay {
            suite?.set(lastDay, forKey: Self.streakLastDayKey)
        }
        let note = "reason=\(reason) total_xp=\(newTotal) daily_xp=\(newDaily) delta=\(delta) streak=\(streakCount) last_day=\(lastDay ?? "nil") goals_done=\(newGoals.filter(\.done).count)/\(newGoals.count)"
        lastAwardNote = note
        suite?.set(note, forKey: Self.lastAwardNoteKey)
        TestLogger.shared.log("ATTN-P07", "score \(note)")
        if delta != 0 {
            TestLogger.shared.log(
                "ATTN-P07",
                "award delta_xp=\(delta) at=\(TestLogger.isoString(Date())) weights=\(weightsLine)"
            )
        }
    }

    func loadPersisted() {
        totalXP = suite?.object(forKey: Self.totalXPKey) as? Int ?? 0
        dailyXP = suite?.object(forKey: Self.dailyXPKey) as? Int ?? 0
        streak = suite?.object(forKey: Self.streakKey) as? Int ?? 0
        streakLastDay = suite?.string(forKey: Self.streakLastDayKey)
        lastAwardNote = suite?.string(forKey: Self.lastAwardNoteKey) ?? ""
        weightsLine = ScoringRules.weightsDescription()
    }

    /// TEMP DEBUG (remove later): zero persisted XP/streak before recompute.
    func clearPersistedForTesting() {
        suite?.set(0, forKey: Self.totalXPKey)
        suite?.set(0, forKey: Self.dailyXPKey)
        suite?.set(0, forKey: Self.streakKey)
        suite?.removeObject(forKey: Self.streakLastDayKey)
        totalXP = 0
        dailyXP = 0
        streak = 0
        streakLastDay = nil
    }
}
