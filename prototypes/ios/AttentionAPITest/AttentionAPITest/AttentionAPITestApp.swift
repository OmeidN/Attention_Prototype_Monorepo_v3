import SwiftUI
import os

/// P00+ product host. Lab experiment controllers are not wired into the primary UI.
let productShellLogger = Logger(subsystem: "attention.p00", category: "lifecycle")

@main
struct AttentionAPITestApp: App {
    @StateObject private var logger = TestLogger.shared
    @StateObject private var trackedApps = TrackedAppsStore.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        TestLogger.shared.log(
            "ATTN-P00",
            "app_launched product_shell=true bundle=\(DeviceInfo.bundleIdentifier) app_group=\(ExperimentStore.appGroupID) boundary=evolved_lab_project"
        )
        TestLogger.shared.log(
            "ATTN-P00",
            "auth_at_launch status=\(FamilyControlsAuth.statusLabel)"
        )
        TestLogger.shared.log(
            "ATTN-P01",
            "tracked_apps_at_launch count=\(TrackedAppsStore.shared.apps.count) labels=[\(TrackedAppsStore.shared.userLabels.joined(separator: ","))]"
        )
        productShellLogger.log("app_launched")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(logger)
                .environmentObject(trackedApps)
        }
        .onChange(of: scenePhase) { _, newPhase in
            let name: String
            switch newPhase {
            case .active: name = "scene_active"
            case .inactive: name = "scene_inactive"
            case .background: name = "scene_background"
            @unknown default: name = "scene_unknown"
            }
            productShellLogger.log("\(name, privacy: .public)")
            TestLogger.shared.log("ATTN-P00", name)

            if newPhase == .active {
                TestLogger.shared.log(
                    "ATTN-P00",
                    "auth_on_active status=\(FamilyControlsAuth.statusLabel)"
                )
                TrackedAppsStore.shared.load()
                TestLogger.shared.log(
                    "ATTN-P01",
                    "tracked_apps_on_active count=\(TrackedAppsStore.shared.apps.count)"
                )
            }
        }
    }
}
