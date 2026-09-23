import SwiftUI

/// Production primary UI. Lab Experiments tabs are not shown.
/// P09: first launch shows onboarding; a completed flag skips straight to Home.
struct RootView: View {
    @EnvironmentObject private var onboarding: OnboardingStore

    var body: some View {
        Group {
            if onboarding.isComplete {
                mainTabs
            } else {
                ProductOnboardingView(isReplay: false)
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { onboarding.showTipsReplay },
            set: { onboarding.showTipsReplay = $0 }
        )) {
            ProductOnboardingView(isReplay: true)
        }
    }

    private var mainTabs: some View {
        TabView {
            ProductTodayHomeView()
                .tabItem { Label("Home", systemImage: "house") }

            ProductTrackedAppsView()
                .tabItem { Label("Apps", systemImage: "app.badge") }

            ProductSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }

            ProductDogfoodView()
                .tabItem { Label("Dogfood", systemImage: "checklist") }
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
        .environmentObject(AttentionSettingsStore.shared)
        .environmentObject(OnboardingStore.shared)
        .environmentObject(DogfoodChecklistStore.shared)
}
