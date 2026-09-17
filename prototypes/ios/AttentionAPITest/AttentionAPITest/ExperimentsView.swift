import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity

struct ExperimentsView: View {
    @EnvironmentObject private var logger: TestLogger
    @EnvironmentObject private var trackedApps: TrackedAppsStore
    @EnvironmentObject private var shield: ShieldController
    @EnvironmentObject private var deviceActivity: DeviceActivityMonitoring
    @EnvironmentObject private var openTrial: OpenTrialStore
    @EnvironmentObject private var accessWindow: AccessWindowController
    @EnvironmentObject private var stressChecklist: StressChecklistStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var selection = FamilyActivitySelection()
    @State private var showPicker = false
    @State private var namingSession: NamingSession?
    @State private var refreshTargetID: UUID?
    @State private var statusMessage: String?
    @State private var probeSummary: String?
    @State private var writeCount = 0
    @State private var isSelectingToRemove = false
    @State private var removeIDs: Set<UUID> = []
    @State private var shieldCopyVariant = ShieldCopySettings.readVariant() ?? "A"
    @State private var lastShieldActionLine = ShieldActionBridge.lastActionSummary()
    @State private var lastActionLatencyText: String?
    @State private var hostAppNeededNote = ShieldActionBridge.suite?.string(forKey: ShieldActionBridge.hostNeededNoteKey) ?? "no — confirmed M06"
    @State private var m07StatusText = DeviceActivityBridge.statusSummary()
    @State private var m07WaitingText = DeviceActivityBridge.waitingSinceLine()
    @State private var m08SideChannelText = DeviceActivityReportBridge.hostSideChannelSummary()
    @State private var hostActivityProbeText = "host_activityData: not run yet"
    @State private var lastSeenThresholdAt: String? = DeviceActivityBridge.suite?.string(forKey: DeviceActivityBridge.lastThresholdAtKey)
    @State private var isProbingHostActivity = false
    @State private var m11StatusText = InterventionState.statusSummary(apps: TrackedAppsStore.shared.apps)
    @State private var m11TrustNote = InterventionState.trustNote()

    private var authApproved: Bool {
        FamilyControlsAuth.status == .approved
    }

    private var shieldButtonTitle: String {
        let labels = trackedApps.userLabels
        if labels.isEmpty { return "Shield selected (none tracked)" }
        return "Shield selected: \(labels.joined(separator: ", "))"
    }

    private var reportFilter: DeviceActivityFilter {
        let start = Calendar.current.startOfDay(for: Date())
        return DeviceActivityFilter(
            segment: .daily(during: DateInterval(start: start, end: Date())),
            applications: trackedApps.trackedTokens
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Milestone") {
                    Text("M12 — Stress / failure")
                        .font(.headline)
                    Text("Tick each row after you run it. Logs must still Copy after failures. No new Screen Time APIs.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(stressChecklist.summaryLine())
                        .font(.system(.caption, design: .monospaced))
                }

                if !authApproved {
                    Section("Authorization") {
                        Text("Family Controls status: \(FamilyControlsAuth.statusLabel). Approve on Setup (M02) before picking apps.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Counts") {
                    row("Tracked apps", "\(trackedApps.applicationCount)")
                    row("CategoryToken (last picker)", "\(trackedApps.categoryCount)")
                    row("WebDomainToken (last picker)", "\(trackedApps.webDomainCount)")
                }

                Section("Tracked apps (user labels)") {
                    if trackedApps.apps.isEmpty {
                        Text("None yet. Use Add one app…")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(trackedApps.apps) { app in
                            trackedAppRow(app)
                        }
                        .onDelete(perform: isSelectingToRemove ? nil : deleteAtOffsets)
                    }
                }

                Section("M04 — Basic shield") {
                    Text(shield.statusLine)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)

                    Button(shieldButtonTitle) {
                        shield.shieldSelected(apps: trackedApps.apps)
                        statusMessage = "Shield applied to: \(trackedApps.userLabels.joined(separator: ", ")). Open those apps from Home — look for custom M05 copy."
                    }
                    .disabled(trackedApps.apps.isEmpty || !authApproved)

                    Button("Clear shield", role: .destructive) {
                        shield.clearShield()
                        statusMessage = "Shield cleared (last write). Open tracked apps to confirm they launch."
                    }

                    Text("Status is last successful write from this app — not an OS readback.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("M05 — Shield copy variant") {
                    Picker("shield_copy_variant", selection: $shieldCopyVariant) {
                        Text("A").tag("A")
                        Text("B").tag("B")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: shieldCopyVariant) { _, newValue in
                        writeShieldVariant(newValue)
                    }

                    Text("Current App Group value: \(ShieldCopySettings.readVariant() ?? "nil")")
                        .font(.system(.caption, design: .monospaced))

                    Text("Change A↔B, then reopen a shielded app (no rebuild). Subtitle should flip.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("M06 — Last shield action") {
                    Text(lastShieldActionLine)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)

                    if let lastActionLatencyText {
                        Text(lastActionLatencyText)
                            .font(.system(.caption, design: .monospaced))
                    }

                    Text("host_app_needed: \(hostAppNeededNote)")
                        .font(.caption)

                    TextField("Note if Continue required opening Attention…", text: $hostAppNeededNote)
                        .onChange(of: hostAppNeededNote) { _, newValue in
                            ShieldActionBridge.suite?.set(newValue, forKey: ShieldActionBridge.hostNeededNoteKey)
                        }

                    Button("Refresh action from App Group") {
                        refreshShieldActionFromBridge(reason: "manual")
                    }

                    Text("Continue = clear token + `.close` + starts M09 access window. Host re-shields after window (deferred if Attention background).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("M09 — Access window") {
                    Text(accessWindow.statusText)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)

                    Picker("Window length", selection: Binding(
                        get: { accessWindow.durationSeconds },
                        set: { accessWindow.setDurationSeconds($0) }
                    )) {
                        ForEach(AccessWindowBridge.durationChoices, id: \.seconds) { choice in
                            Text(choice.label).tag(choice.seconds)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Honest unit (your pick)", selection: Binding(
                        get: { accessWindow.honestUnit },
                        set: { accessWindow.setHonestUnit($0) }
                    )) {
                        Text("access_window").tag("access_window")
                        Text("usage_time").tag("usage_time")
                        Text("session").tag("session")
                    }

                    Button("Refresh window from App Group") {
                        accessWindow.sync(
                            reason: "manual",
                            attentionForeground: scenePhase == .active,
                            apps: trackedApps.apps
                        )
                        statusMessage = "Synced access window state."
                    }

                    if let first = trackedApps.apps.first {
                        Button("Debug: start \(AccessWindowBridge.preferredDurationSeconds())s window for \(first.userLabel)") {
                            accessWindow.debugStartWindow(for: first)
                            statusMessage = "Debug window armed for \(first.userLabel). Leave Attention in background to test defer; return to re-shield."
                        }
                    }

                    Button("Cancel active window", role: .destructive) {
                        accessWindow.cancelActiveWindow(reason: "manual_cancel")
                        statusMessage = "Access window cancelled (no reshield)."
                    }

                    Text("After Continue (or debug start): stay in app inside window → usable; leave/return inside window → still unshielded; after end + Attention foreground → shielded from Home (if mode=on_window_end). Optional: Start M07 monitor for usage_checkpoint / on_threshold.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("M10 — Re-shield mode") {
                    Text(accessWindow.reshieldStatusText)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)

                    Picker("Mode", selection: Binding(
                        get: { accessWindow.reshieldMode },
                        set: { accessWindow.setReshieldMode($0) }
                    )) {
                        Text("on_window_end").tag(ReshieldMode.onWindowEnd)
                        Text("on_threshold").tag(ReshieldMode.onThreshold)
                        Text("manual_only").tag(ReshieldMode.manualOnly)
                    }

                    Toggle(isOn: Binding(
                        get: { accessWindow.unsafeInterrupt },
                        set: { accessWindow.setUnsafeInterrupt($0) }
                    )) {
                        Text("unsafe_interrupt (yank mid-use)")
                            .foregroundStyle(accessWindow.unsafeInterrupt ? .red : .primary)
                    }

                    if accessWindow.unsafeInterrupt {
                        Text("UNSAFE: may re-shield while the tracked app is still foreground. Leave OFF unless testing interrupt.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button("Manual re-shield now") {
                        accessWindow.manualReshieldNow(apps: trackedApps.apps)
                        statusMessage = "Manual re-shield requested."
                    }
                    .disabled(trackedApps.apps.isEmpty || !authApproved)

                    TextField(
                        "Production-acceptable mode note…",
                        text: Binding(
                            get: { accessWindow.acceptableModeNote },
                            set: { accessWindow.setAcceptableModeNote($0) }
                        )
                    )

                    Text("Test: window-end in-app (default=no interrupt); window-end after leave; on_threshold after ~1 min use (Start M07); rapid reopen ×5 around end.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("M11 — Friction levels") {
                    Text(m11StatusText)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)

                    Text(InterventionState.mappingDescription())
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Refresh M11 counts") {
                        m11StatusText = InterventionState.statusSummary(apps: trackedApps.apps)
                        statusMessage = "Refreshed intervention counts."
                    }

                    if let first = trackedApps.apps.first {
                        Button("Debug +1 Continue for \(first.userLabel)") {
                            let (prev, next, count) = InterventionState.debugBumpContinue(appID: first.id)
                            TestLogger.shared.log(
                                "ATTN-M11",
                                "debug_bump label=\(first.userLabel) prev_level=\(prev) next_level=\(next) continues=\(count)"
                            )
                            m11StatusText = InterventionState.statusSummary(apps: trackedApps.apps)
                            statusMessage = "Debug +1 Continue. Re-open shielded \(first.userLabel) to see level."
                        }
                    }

                    Button("Reset today (all apps)", role: .destructive) {
                        InterventionState.resetToday()
                        TestLogger.shared.log("ATTN-M11", "reset_today")
                        m11StatusText = InterventionState.statusSummary(apps: trackedApps.apps)
                        statusMessage = "Reset today's Continue / Never Mind counts."
                    }

                    TextField(
                        "Trust note: trustworthy / fragile / unusable…",
                        text: $m11TrustNote
                    )
                    .onChange(of: m11TrustNote) { _, newValue in
                        InterventionState.setTrustNote(newValue)
                        TestLogger.shared.log("ATTN-M11", "trustworthiness=\(newValue)")
                    }

                    Text("Continue 3× (re-shield between). Expect L0→L1→L2 on shield subtitle. Force-quit host, open shielded app — level still correct? Never Mind must not bump continues.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("M12 — Stress checklist") {
                    Text("UUID store unchanged. If auth revoked: Setup shows status; shield UI clears; app must not crash.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(stressChecklist.items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle(isOn: Binding(
                                get: { item.done },
                                set: { stressChecklist.setDone(id: item.id, done: $0) }
                            )) {
                                Text(item.title)
                                    .font(.caption)
                            }
                            TextField(
                                "result: pass/fail/skip…",
                                text: Binding(
                                    get: { item.result },
                                    set: { stressChecklist.setResult(id: item.id, result: $0) }
                                )
                            )
                            .font(.caption)
                            TextField(
                                "notes…",
                                text: Binding(
                                    get: { item.notes },
                                    set: { stressChecklist.setNotes(id: item.id, notes: $0) }
                                )
                            )
                            .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }

                    TextField(
                        "Full-day reliability % / notes…",
                        text: Binding(
                            get: { stressChecklist.fullDayReliabilityNote },
                            set: { stressChecklist.setFullDayNote($0) }
                        )
                    )

                    Button("Reset stress checklist", role: .destructive) {
                        stressChecklist.resetChecklist()
                        statusMessage = "Stress checklist reset."
                    }

                    Text("After each stress: open Logs → Copy all still works. Paste ATTN-M12 lines when done.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("M07 — Device Activity monitor") {
                    Text(m07StatusText)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)

                    Text(m07WaitingText)
                        .font(.system(.caption, design: .monospaced))

                    Button(deviceActivity.isMonitoring ? "Restart monitor for tracked apps" : "Start monitor (all-day)") {
                        deviceActivity.start(apps: trackedApps.apps)
                        refreshM07FromBridge(reason: "start")
                        if let err = deviceActivity.lastError {
                            statusMessage = "Monitor start failed: \(err)"
                        } else {
                            statusMessage = "Monitoring started — use a tracked app for >\(deviceActivity.thresholdMinutes) min. Do not call this an open."
                        }
                    }
                    .disabled(trackedApps.apps.isEmpty || !authApproved)

                    Button("Stop monitor", role: .destructive) {
                        deviceActivity.stop()
                        refreshM07FromBridge(reason: "stop")
                        statusMessage = "Monitoring stopped (no orphan schedule)."
                    }

                    Button("Refresh callbacks from App Group") {
                        refreshM07FromBridge(reason: "manual")
                    }

                    if let err = deviceActivity.lastError {
                        Text("last_error: \(err)")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .textSelection(.enabled)
                    }

                    Text("Callbacks write timestamps to App Group only. Return to Attention to see them. Idle without tracked apps should not fire threshold.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("M08 — DeviceActivityReport (embed)") {
                    Text("Not validated as opens until the trial says so.")
                        .font(.caption)
                        .foregroundStyle(.red)

                    DeviceActivityReport(
                        .init(DeviceActivityReportBridge.contextName),
                        filter: reportFilter
                    )
                    .frame(minHeight: 88)

                    Text(m08SideChannelText)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)

                    Button("Refresh App Group side-channel from report") {
                        m08SideChannelText = DeviceActivityReportBridge.hostSideChannelSummary()
                        TestLogger.shared.log("ATTN-M08", "sidechannel_refresh \(m08SideChannelText.replacingOccurrences(of: "\n", with: " | "))")
                        statusMessage = "Read report App Group keys (only updates after report extension ran makeConfiguration)."
                    }

                    Text(hostActivityProbeText)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)

                    Button(isProbingHostActivity ? "Probing host activityData…" : "Probe host DeviceActivityData.activityData (iOS 26.4+)") {
                        Task { await runHostActivityProbe() }
                    }
                    .disabled(trackedApps.apps.isEmpty || !authApproved || isProbingHostActivity)
                }

                Section("M08 — Open trial (ground truth)") {
                    Text("Rule: M07 cannot see launches (duration thresholds). Tap Truth +1 each time you launch a tracked app from Home. Optionally Restart monitor between launches if you want threshold_event chances.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(openTrial.summaryLine())
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)

                    Button("Truth +1 (I just launched a tracked app)") {
                        openTrial.bumpTruth()
                        statusMessage = openTrial.summaryLine()
                    }

                    Button("Mark threshold_event detect +1 (saw new M07 fire)") {
                        openTrial.bumpThresholdDetect(reason: "manual")
                        statusMessage = openTrial.summaryLine()
                    }

                    Button("Reset trial counters", role: .destructive) {
                        openTrial.reset()
                        statusMessage = openTrial.summaryLine()
                    }

                    TextField("Notes (recents contrast, shielded?, decision…)", text: $openTrial.notes)
                        .onChange(of: openTrial.notes) { _, _ in
                            openTrial.persistNotes()
                        }

                    Text("Stop summary when done: truth / detections / misses / false positives. Decide opens validated | not opens | inconclusive.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Manage tracked apps") {
                    Button(trackedApps.apps.isEmpty ? "Add one app…" : "Add another app…") {
                        beginAddOneApp()
                    }
                    .disabled(!authApproved || isSelectingToRemove)

                    Text("Apple’s picker cannot lock checkboxes. If you uncheck an already-tracked app while adding, we reject the add and keep your list. Use Remove below instead.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if isSelectingToRemove {
                        Button("Remove \(removeIDs.count) selected", role: .destructive) {
                            removeSelected()
                        }
                        .disabled(removeIDs.isEmpty)

                        Button("Cancel multi-remove") {
                            isSelectingToRemove = false
                            removeIDs = []
                        }
                    } else {
                        Button("Select apps to remove…") {
                            isSelectingToRemove = true
                            removeIDs = []
                            statusMessage = "Tap apps to select, then Remove. Or swipe a row to delete one."
                        }
                        .disabled(trackedApps.apps.isEmpty)
                    }

                    Button("Clear all tracked apps", role: .destructive) {
                        shield.clearShield()
                        trackedApps.clearAll()
                        selection = FamilyActivitySelection()
                        isSelectingToRemove = false
                        removeIDs = []
                        statusMessage = "Tracked apps and shield cleared."
                        probeSummary = nil
                    }

                    Button("Probe token display names") {
                        Task { await runNameProbe() }
                    }
                    .disabled(trackedApps.apps.isEmpty)
                }

                if let statusMessage {
                    Section("Status") {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let probeSummary {
                    Section("Token name probe (M03 fact check)") {
                        Text(probeSummary)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }

                Section("Log plumbing") {
                    Button("Write a test log line") {
                        writeCount += 1
                        logger.log("ATTN-M01", "test_button_pressed count=\(writeCount)")
                    }
                }
            }
            .navigationTitle("Experiments")
            .familyActivityPicker(
                headerText: trackedApps.apps.isEmpty
                    ? "Pick exactly one app to track."
                    : "Keep already-tracked apps checked. Add exactly one new app. Unchecking tracked apps is rejected — use Remove in the app instead.",
                isPresented: $showPicker,
                selection: $selection
            )
            .onChange(of: showPicker) { _, isPresented in
                if !isPresented {
                    handlePickerDismissed()
                }
            }
            .sheet(item: $namingSession) { session in
                NamingAppsView(
                    token: session.token,
                    onCancel: {
                        namingSession = nil
                        revertSelectionToTracked()
                        statusMessage = "Naming cancelled — previous tracked apps unchanged."
                    },
                    onSave: { label, token in
                        let added = trackedApps.addTrackedApp(label: label, token: token)
                        selection = trackedApps.lastSelection
                        namingSession = nil
                        statusMessage = "Added “\(label)” id \(added.id.uuidString). Existing apps kept their ids."
                    }
                )
            }
            .onAppear {
                selection = trackedApps.lastSelection
                if ShieldCopySettings.readVariant() == nil {
                    writeShieldVariant("A")
                }
                shieldCopyVariant = ShieldCopySettings.readVariant() ?? "A"
                deviceActivity.refreshFromStore()
                refreshShieldActionFromBridge(reason: "onAppear")
                refreshM07FromBridge(reason: "onAppear")
                m08SideChannelText = DeviceActivityReportBridge.hostSideChannelSummary()
                m11StatusText = InterventionState.statusSummary(apps: trackedApps.apps)
                accessWindow.sync(
                    reason: "onAppear",
                    attentionForeground: true,
                    apps: trackedApps.apps
                )
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    if !authApproved {
                        statusMessage = "Authorization is \(FamilyControlsAuth.statusLabel). Re-approve on Setup if needed."
                    }
                    refreshShieldActionFromBridge(reason: "scene_active")
                    refreshM07FromBridge(reason: "scene_active")
                    accessWindow.sync(
                        reason: "scene_active",
                        attentionForeground: true,
                        apps: trackedApps.apps
                    )
                } else if phase == .background {
                    accessWindow.sync(
                        reason: "scene_background",
                        attentionForeground: false,
                        apps: trackedApps.apps
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func trackedAppRow(_ app: TrackedApp) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if isSelectingToRemove {
                Image(systemName: removeIDs.contains(app.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(removeIDs.contains(app.id) ? Color.accentColor : .secondary)
                    .padding(.top, 2)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(app.userLabel)
                    .font(.system(.body, design: .monospaced))
                Text("id \(app.id.uuidString)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                if !isSelectingToRemove {
                    Button("Replace token for this label") {
                        beginTokenRefresh(for: app.id)
                    }
                    .font(.caption)

                    Button("Remove this app", role: .destructive) {
                        trackedApps.removeApps(ids: [app.id])
                        selection = trackedApps.lastSelection
                        statusMessage = "Removed “\(app.userLabel)”."
                    }
                    .font(.caption)
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard isSelectingToRemove else { return }
            if removeIDs.contains(app.id) {
                removeIDs.remove(app.id)
            } else {
                removeIDs.insert(app.id)
            }
        }
    }

    private func deleteAtOffsets(_ offsets: IndexSet) {
        let ids = Set(offsets.map { trackedApps.apps[$0].id })
        let labels = offsets.map { trackedApps.apps[$0].userLabel }
        trackedApps.removeApps(ids: ids)
        selection = trackedApps.lastSelection
        statusMessage = "Removed \(labels.joined(separator: ", "))."
    }

    private func removeSelected() {
        let labels = trackedApps.apps.filter { removeIDs.contains($0.id) }.map(\.userLabel)
        trackedApps.removeApps(ids: removeIDs)
        selection = trackedApps.lastSelection
        statusMessage = "Removed \(labels.joined(separator: ", "))."
        isSelectingToRemove = false
        removeIDs = []
    }

    private func beginAddOneApp() {
        refreshTargetID = nil
        isSelectingToRemove = false
        removeIDs = []
        statusMessage = trackedApps.apps.isEmpty
            ? "Pick exactly one app, then name it."
            : "Keep existing apps checked. Check exactly one additional app. Do not uncheck tracked apps."
        selection = trackedApps.selectionFromTrackedApps()
        showPicker = true
    }

    private func beginTokenRefresh(for id: UUID) {
        refreshTargetID = id
        isSelectingToRemove = false
        removeIDs = []
        statusMessage = "Pick the same app again to re-bind its token for “\(trackedApps.app(id: id)?.userLabel ?? id.uuidString)”."
        selection = trackedApps.selectionFromTrackedApps()
        showPicker = true
    }

    private func revertSelectionToTracked() {
        selection = trackedApps.selectionFromTrackedApps()
        trackedApps.updateLastSelection(selection)
    }

    private func handlePickerDismissed() {
        let tokens = Array(selection.applicationTokens)

        if let refreshID = refreshTargetID {
            refreshTargetID = nil
            finishTokenRefresh(id: refreshID, tokens: tokens)
            return
        }

        let removed = trackedApps.removedTrackedTokens(in: selection)
        if !removed.isEmpty {
            let removedLabels = trackedApps.labels(forTokens: removed)
            revertSelectionToTracked()
            TestLogger.shared.log(
                "ATTN-M03",
                "add_rejected reason=unchecked_tracked removedCount=\(removed.count) labels=[\(removedLabels.joined(separator: ","))]"
            )
            statusMessage = "Add cancelled: you unchecked tracked app(s) (\(removedLabels.joined(separator: ", "))). Use Remove in Experiments instead — Apple’s picker cannot lock those checkboxes."
            return
        }

        let newTokens = trackedApps.newTokens(in: selection)

        if newTokens.isEmpty {
            revertSelectionToTracked()
            TestLogger.shared.log(
                "ATTN-M03",
                "add_rejected reason=no_new_token totalSelected=\(tokens.count) alreadyTracked=\(trackedApps.apps.count)"
            )
            statusMessage = tokens.isEmpty
                ? "Picker closed with nothing selected."
                : "No new app detected. Keep existing apps checked and add exactly one new app."
            return
        }

        if newTokens.count > 1 {
            revertSelectionToTracked()
            TestLogger.shared.log(
                "ATTN-M03",
                "add_rejected reason=too_many_new newCount=\(newTokens.count)"
            )
            statusMessage = "Add exactly one new app at a time (you added \(newTokens.count) new). Existing apps were not changed."
            return
        }

        let tokenToName = newTokens[0]
        TestLogger.shared.log(
            "ATTN-M03",
            "picker_closed newApps=1 totalSelected=\(tokens.count) → naming one (deferred)"
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            namingSession = NamingSession(token: tokenToName)
        }
    }

    private func finishTokenRefresh(id: UUID, tokens: [ApplicationToken]) {
        guard let label = trackedApps.app(id: id)?.userLabel else {
            TestLogger.shared.log("ATTN-M03", "token_refresh_failed reason=unknown_id")
            statusMessage = "Token refresh failed — unknown id."
            revertSelectionToTracked()
            return
        }

        let existingOthers = Set(trackedApps.apps.filter { $0.id != id }.map(\.token))
        let candidates = tokens.filter { !existingOthers.contains($0) }

        let chosen: ApplicationToken?
        if tokens.count == 1 {
            chosen = tokens[0]
        } else if candidates.count == 1 {
            chosen = candidates[0]
        } else if candidates.isEmpty, let first = tokens.first {
            chosen = first
        } else {
            chosen = nil
        }

        guard let newToken = chosen else {
            TestLogger.shared.log(
                "ATTN-M03",
                "token_refresh_failed reason=ambiguous_selection label=\(label) tokenCount=\(tokens.count)"
            )
            statusMessage = "Token refresh failed — pick exactly one app (got \(tokens.count))."
            revertSelectionToTracked()
            return
        }

        if trackedApps.refreshToken(for: id, newToken: newToken) {
            selection = trackedApps.lastSelection
            statusMessage = "Token refreshed for “\(label)” (same id)."
        } else {
            statusMessage = "Token refresh failed for “\(label)”."
            revertSelectionToTracked()
        }
    }

    private func runNameProbe() async {
        let result = await TokenNameProbe.run(selectedTokens: trackedApps.apps.map(\.token))
        probeSummary = result.summary
        TestLogger.shared.log("ATTN-M03", "token_name_probe \(result.summary)")
        statusMessage = "Name probe logged — see section below and Logs."
    }

    private func writeShieldVariant(_ variant: String) {
        ShieldCopySettings.writeVariant(variant)
        TestLogger.shared.log("ATTN-M05", "shield_config_variant_written variant=\(variant)")
        statusMessage = "Wrote shield_copy_variant=\(variant) to App Group. Re-open a shielded app to see it."
    }

    private func refreshShieldActionFromBridge(reason: String) {
        lastShieldActionLine = ShieldActionBridge.lastActionSummary()
        if let consumed = ShieldActionBridge.consumeNewActionForHost() {
            lastShieldActionLine = consumed.summary
            if let latency = consumed.latencySeconds {
                lastActionLatencyText = String(format: "host_seen_latency≈%.2fs (extension write → host foreground)", latency)
            }
            TestLogger.shared.log(
                "ATTN-M06",
                "\(consumed.summary) reason=\(reason) latency=\(consumed.latencySeconds.map { String(format: "%.2f" , $0) } ?? "n/a")"
            )
            if let transition = ShieldCopySettings.suite?.string(forKey: "attention.m11.last_continue_transition"),
               consumed.summary.contains("continue") {
                TestLogger.shared.log("ATTN-M11", "continue_transition \(transition) reason=\(reason)")
                ShieldCopySettings.suite?.removeObject(forKey: "attention.m11.last_continue_transition")
            }
            m11StatusText = InterventionState.statusSummary(apps: trackedApps.apps)
            statusMessage = "Read shield action from App Group."
            accessWindow.sync(
                reason: "after_shield_action_\(reason)",
                attentionForeground: scenePhase == .active,
                apps: trackedApps.apps
            )
        }
    }

    private func refreshM07FromBridge(reason: String) {
        deviceActivity.refreshFromStore()
        m07StatusText = DeviceActivityBridge.statusSummary()
        m07WaitingText = DeviceActivityBridge.waitingSinceLine()
        let thresholdAt = DeviceActivityBridge.suite?.string(forKey: DeviceActivityBridge.lastThresholdAtKey)
        let intervalStart = DeviceActivityBridge.suite?.string(forKey: DeviceActivityBridge.lastIntervalStartKey)
        let kind = DeviceActivityBridge.suite?.string(forKey: DeviceActivityBridge.lastCallbackKindKey) ?? "none"
        let thresholdLabels = DeviceActivityBridge.suite?.string(forKey: DeviceActivityBridge.lastThresholdLabelsKey) ?? ""
        if let thresholdAt {
            if let previous = lastSeenThresholdAt, previous != thresholdAt {
                openTrial.bumpThresholdDetect(reason: "auto_\(reason)")
                accessWindow.noteUsageCheckpointIfNeeded(
                    thresholdAt: thresholdAt,
                    labels: thresholdLabels,
                    reason: reason
                )
            }
            lastSeenThresholdAt = thresholdAt
        }
        TestLogger.shared.log(
            "ATTN-M07",
            "status_refresh reason=\(reason) monitoring=\(deviceActivity.isMonitoring) last_callback=\(kind) intervalDidStart=\(intervalStart ?? "none") eventDidReachThreshold=\(thresholdAt ?? "none")"
        )
    }

    @MainActor
    private func runHostActivityProbe() async {
        isProbingHostActivity = true
        defer { isProbingHostActivity = false }
        if #available(iOS 26.4, *) {
            let result = await HostActivityDataProbe.run(tokens: trackedApps.trackedTokens)
            hostActivityProbeText = result.summary
            TestLogger.shared.log("ATTN-M08", result.summary)
            statusMessage = result.error == nil ? "Host activityData probe finished." : "Host activityData failed — see text."
        } else {
            hostActivityProbeText = HostActivityDataProbe.unsupportedSummary()
            TestLogger.shared.log("ATTN-M08", hostActivityProbeText)
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
        }
    }
}

#Preview {
    ExperimentsView()
        .environmentObject(TestLogger.shared)
        .environmentObject(TrackedAppsStore.shared)
        .environmentObject(ShieldController.shared)
        .environmentObject(DeviceActivityMonitoring.shared)
        .environmentObject(OpenTrialStore.shared)
        .environmentObject(AccessWindowController.shared)
        .environmentObject(StressChecklistStore.shared)
}
