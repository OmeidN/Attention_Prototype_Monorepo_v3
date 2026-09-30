import SwiftUI

/// P13 — local recap from TodayEventLog. Rules-based lines only. No AI. No open counts.
struct ProductRecapView: View {
    @EnvironmentObject private var logger: TestLogger
    @EnvironmentObject private var today: TodayStatsStore
    @EnvironmentObject private var scoring: ScoringStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var days: [TodayEventLog.DayRecap] = []

    var body: some View {
        NavigationStack {
            List {
                Section("P13 — Recap") {
                    Text("Local recap")
                        .font(.title2.weight(.bold))
                    Text(insightLine)
                        .font(.body.weight(.semibold))
                    Text("From logged Never Mind, Continue, and access-window events. Not opens. Not sessions. Not Screen Time Report. No AI.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Today") {
                    metric("Never Minds", "\(today.neverMindsToday)")
                    metric("Continues", "\(today.continuesToday)")
                    metric("Access windows", "\(today.windowsToday)")
                    metric("Window time", formatDuration(today.windowSecondsToday))
                    metric("Goals hit", "\(goalsHit)/\(scoring.goals.count)")
                    metric("Never Mind streak", "\(scoring.streak) day\(scoring.streak == 1 ? "" : "s")")
                    metric("XP today", "\(scoring.dailyXP)")
                }

                Section("Last 7 days") {
                    let maxNM = max(days.map(\.neverMinds).max() ?? 1, 1)
                    if days.allSatisfy({ $0.neverMinds == 0 && $0.continues == 0 && $0.windows == 0 }) {
                        Text("No events in the last 7 days.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(days) { day in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dayLabel(day))
                                .font(.headline)
                            Text("Never Mind \(day.neverMinds) · Continue \(day.continues) · Windows \(day.windows) · \(formatDuration(day.windowSeconds))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            GeometryReader { geo in
                                let width = geo.size.width * CGFloat(day.neverMinds) / CGFloat(maxNM)
                                Rectangle()
                                    .fill(day.neverMinds == 0 ? Color.secondary.opacity(0.25) : Color.accentColor)
                                    .frame(width: max(width, day.neverMinds == 0 ? 4 : 8), height: 8)
                            }
                            .frame(height: 8)
                        }
                        .padding(.vertical, 2)
                    }
                    Text("Bar length is Never Minds that day, scaled to the busiest day in this week.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Recap")
            .onAppear { reload(reason: "onAppear") }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { reload(reason: "scene_active") }
            }
        }
    }

    private var goalsHit: Int {
        scoring.goals.filter(\.done).count
    }

    private var insightLine: String {
        let nm = today.neverMindsToday
        let cont = today.continuesToday
        let windows = today.windowsToday
        if nm == 0 && cont == 0 && windows == 0 {
            return "No choices logged today yet."
        }
        let goalBit = scoring.goals.isEmpty ? "" : " Goals hit \(goalsHit)/\(scoring.goals.count)."
        let streakBit = scoring.streak > 0 ? " Streak \(scoring.streak)." : ""
        let rest = "\(cont) Continue\(cont == 1 ? "" : "s"), \(windows) access window\(windows == 1 ? "" : "s").\(goalBit)\(streakBit)"
        if nm == 0 {
            return "No Never Minds yet today. \(rest)"
        }
        let times = nm == 1 ? "once" : "\(nm) times"
        return "You chose Never Mind \(times) today (+\(nm * ScoringRules.neverMindXP) XP). \(rest)"
    }

    private func reload(reason: String) {
        _ = today.ingest(reason: "recap_\(reason)")
        days = TodayEventLog.lastDays(count: 7)
        let summary = days.map { "\($0.dayKey) nm=\($0.neverMinds) c=\($0.continues) w=\($0.windows)" }.joined(separator: " | ")
        logger.log("ATTN-P13", "recap_ready \(reason) \(insightLine) days=[\(summary)]")
    }

    private func dayLabel(_ day: TodayEventLog.DayRecap) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d"
        let name = formatter.string(from: day.day)
        if Calendar.current.isDateInToday(day.day) { return "\(name) (today)" }
        return name
    }

    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m) min" : "\(m)m \(s)s"
    }

    private func metric(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .font(.body.monospacedDigit().weight(.semibold))
        }
    }
}
