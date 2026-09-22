import SwiftUI

/// Production primary UI. Lab Experiments tabs are not shown.
struct RootView: View {
    var body: some View {
        TabView {
            ProductTodayHomeView()
                .tabItem { Label("Home", systemImage: "house") }

            ProductTrackedAppsView()
                .tabItem { Label("Apps", systemImage: "app.badge") }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(TestLogger.shared)
        .environmentObject(TrackedAppsStore.shared)
        .environmentObject(ShieldController.shared)
        .environmentObject(AccessWindowController.shared)
        .environmentObject(TodayStatsStore.shared)
        .environmentObject(ScoringStore.shared)
}
