import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            SetupView()
                .tabItem { Label("Setup", systemImage: "gearshape") }

            ExperimentsView()
                .tabItem { Label("Experiments", systemImage: "flask") }

            LogsView()
                .tabItem { Label("Logs", systemImage: "list.bullet.rectangle") }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(TestLogger.shared)
}
