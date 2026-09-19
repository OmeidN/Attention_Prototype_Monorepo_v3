import SwiftUI
import os

/// P00+ product host. Lab experiment controllers are not wired into the primary UI.
let productShellLogger = Logger(subsystem: "attention.p00", category: "lifecycle")

@main
struct AttentionAPITestApp: App {
    @StateObject private var logger = TestLogger.shared
    @StateObject private var trackedApps = TrackedAppsStore.shared
    @StateObject private var shield = ShieldController.shared
    @StateObject private var accessWindow = AccessWindowController.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Production defaults for P05A — hard threshold closer (set-and-forget; may yank).
        ReshieldPolicy.setMode(.onThreshold)
        ReshieldPolicy.setUnsafeInterrupt(true)
        AccessWindowBridge.setHonestUnit("access_window")
        AccessWindowController.shared.setReshieldMode(.onThreshold)
        AccessWindowController.shared.setUnsafeInterrupt(true)
        ReshieldPolicy.setAcceptableModeNote("on_threshold hard_yank set-and-forget")

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
        TestLogger.shared.log(
            "ATTN-P02",
            "shield_at_launch active=\(ShieldController.shared.lastWriteActive) status=\(ShieldController.shared.statusLine)"
        )
        TestLogger.shared.log(
            "ATTN-P04",
            "policy reshield_mode=\(ReshieldPolicy.mode().rawValue) unsafe_interrupt=\(ReshieldPolicy.unsafeInterrupt()) preferred_duration_s=\(AccessWindowBridge.preferredDurationSeconds()) unit=access_window"
        )
        TestLogger.shared.log(
            "ATTN-P05A",
            "hard_closer=on_threshold may_yank=true \(HardWindowMonitor.statusLine())"
        )
        let rolled = InterventionState.ensureToday()
        if rolled {
            TestLogger.shared.log(
                "ATTN-P05",
                "day_rollover local_day=\(InterventionState.todayString()) — continues/never_mind cleared"
            )
        }
        TestLogger.shared.log("ATTN-P05", "friction \(InterventionState.mappingDescription())")
        productShellLogger.log("app_launched")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(logger)
                .environmentObject(trackedApps)
                .environmentObject(shield)
                .environmentObject(accessWindow)
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
                let auth = FamilyControlsAuth.statusLabel
                TestLogger.shared.log("ATTN-P00", "auth_on_active status=\(auth)")
                if FamilyControlsAuth.status != .approved {
                    ShieldController.shared.markAuthLostUI()
                    TestLogger.shared.log("ATTN-P02", "auth_lost status=\(auth)")
                }
                TrackedAppsStore.shared.load()
                TestLogger.shared.log(
                    "ATTN-P01",
                    "tracked_apps_on_active count=\(TrackedAppsStore.shared.apps.count)"
                )
                TestLogger.shared.log(
                    "ATTN-P02",
                    "shield_on_active active=\(ShieldController.shared.lastWriteActive)"
                )
                AccessWindowController.shared.sync(
                    reason: "app_scene_active",
                    attentionForeground: true,
                    apps: TrackedAppsStore.shared.apps
                )
                let rolled = InterventionState.ensureToday()
                if rolled {
                    TestLogger.shared.log(
                        "ATTN-P05",
                        "day_rollover local_day=\(InterventionState.todayString()) — continues/never_mind cleared"
                    )
                }
            } else if newPhase == .background {
                AccessWindowController.shared.sync(
                    reason: "app_scene_background",
                    attentionForeground: false,
                    apps: TrackedAppsStore.shared.apps
                )
            }
        }
    }
}
