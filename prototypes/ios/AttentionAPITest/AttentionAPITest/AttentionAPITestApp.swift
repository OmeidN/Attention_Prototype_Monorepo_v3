import SwiftUI
import os

/// M00 asks for lifecycle events on the `attention.m00` subsystem specifically.
let milestone00Logger = Logger(subsystem: "attention.m00", category: "lifecycle")

@main
struct AttentionAPITestApp: App {
    @StateObject private var logger = TestLogger.shared
    @StateObject private var trackedApps = TrackedAppsStore.shared
    @StateObject private var shield = ShieldController.shared
    @StateObject private var deviceActivity = DeviceActivityMonitoring.shared
    @StateObject private var openTrial = OpenTrialStore.shared
    @StateObject private var accessWindow = AccessWindowController.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        ExperimentStore.shared.setBool(true, forKey: "foundation_ok")
        TestLogger.shared.log("ATTN-M01", "app_launched foundation_ok=true")
        TestLogger.shared.log(
            "ATTN-M03",
            "store_backing \(ExperimentStore.shared.backingDescription)"
        )
        if ShieldCopySettings.readVariant() == nil {
            ShieldCopySettings.writeVariant("A")
            TestLogger.shared.log("ATTN-M05", "shield_config_variant_written variant=A reason=launch_default")
        }
        DeviceActivityBridge.writeThresholdClaim()
        TestLogger.shared.log(
            "ATTN-M07",
            "threshold_unit_claim \(DeviceActivityBridge.thresholdUnitClaim)"
        )
        TestLogger.shared.log(
            "ATTN-M08",
            DeviceActivityReportBridge.reportAPIHostReadableClaim
        )
        TestLogger.shared.log(
            "ATTN-M09",
            "access_window_fallback preferred_duration_s=\(AccessWindowBridge.preferredDurationSeconds()) — not opens"
        )
        TestLogger.shared.log(
            "ATTN-M10",
            "reshield_mode=\(ReshieldPolicy.mode().rawValue) unsafe_interrupt=\(ReshieldPolicy.unsafeInterrupt()) — default safe"
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(logger)
                .environmentObject(trackedApps)
                .environmentObject(shield)
                .environmentObject(deviceActivity)
                .environmentObject(openTrial)
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
            milestone00Logger.log("\(name, privacy: .public)")
            TestLogger.shared.log("ATTN-M00", name)

            if newPhase == .active {
                AccessWindowController.shared.sync(
                    reason: "app_scene_active",
                    attentionForeground: true,
                    apps: TrackedAppsStore.shared.apps
                )
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
