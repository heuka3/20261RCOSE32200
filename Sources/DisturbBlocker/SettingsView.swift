import DisturbBlockerCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedRunningAppID: UUID?

    var body: some View {
        NavigationSplitView {
            List(selection: $model.selectedModeID) {
                ForEach(model.modes) { mode in
                    Text(mode.name).tag(Optional(mode.id))
                }
            }
            .navigationTitle("Modes")
            .toolbar {
                Button {
                    model.addMode()
                } label: {
                    Label("Add Mode", systemImage: "plus")
                }
                Button {
                    model.deleteSelectedMode()
                } label: {
                    Label("Delete Mode", systemImage: "trash")
                }
                .disabled(model.selectedModeID == nil)
            }
        } detail: {
            if let mode = model.selectedMode {
                ModeEditorView(mode: mode)
                    .environmentObject(model)
            } else {
                ContentUnavailableView("No Mode", systemImage: "moon", description: Text("Create a mode to begin."))
            }
        }
    }
}

struct ModeEditorView: View {
    @EnvironmentObject private var model: AppModel
    let mode: BlockMode

    @State private var newWebsiteRule = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PermissionPanel()

                SectionHeader("Mode")
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                    GridRow {
                        Text("Name")
                        TextField("Mode name", text: Binding(
                            get: { mode.name },
                            set: { value in model.updateSelectedMode { $0.name = value } }
                        ))
                    }
                    GridRow {
                        Text("Quick starts")
                        QuickStartDurationsEditor(mode: mode)
                    }
                    GridRow {
                        Text("Debug")
                        Toggle("Dry run", isOn: $model.isDryRun)
                    }
                }

                SectionHeader("Blocked Apps")
                RunningAppsPicker()
                EditableAppsList(mode: mode)

                SectionHeader("Website Rules")
                HStack {
                    TextField("URL contains, e.g. youtube or reddit.com", text: $newWebsiteRule)
                    Button {
                        let trimmed = newWebsiteRule.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        model.updateSelectedMode { $0.websiteRules.append(WebsiteRule(contains: trimmed)) }
                        newWebsiteRule = ""
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
                EditableWebsiteRulesList(mode: mode)

                SectionHeader("Schedules")
                EditableSchedulesList(mode: mode)

                SectionHeader("Recent Events")
                EventList(events: model.events)
            }
            .padding(24)
        }
    }
}

struct QuickStartDurationsEditor: View {
    @EnvironmentObject private var model: AppModel
    let mode: BlockMode

    @State private var newDurationText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(mode.quickStartDurationsMinutes, id: \.self) { duration in
                HStack {
                    Stepper(value: Binding(
                        get: { duration },
                        set: { newValue in replace(duration, with: newValue) }
                    ), in: 1...600) {
                        Text("\(duration) minutes")
                    }

                    Button {
                        model.updateSelectedMode {
                            $0.quickStartDurationsMinutes.removeAll { $0 == duration }
                            $0.quickStartDurationsMinutes = BlockMode.sanitizedQuickStartDurations($0.quickStartDurationsMinutes)
                        }
                    } label: {
                        Label("Remove", systemImage: "minus.circle")
                    }
                }
            }

            HStack {
                TextField("Minutes", text: $newDurationText)
                    .frame(width: 100)
                Button {
                    guard let minutes = Int(newDurationText.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
                    model.updateSelectedMode {
                        $0.quickStartDurationsMinutes = BlockMode.sanitizedQuickStartDurations($0.quickStartDurationsMinutes + [minutes])
                    }
                    newDurationText = ""
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
    }

    private func replace(_ oldDuration: Int, with newDuration: Int) {
        model.updateSelectedMode {
            $0.quickStartDurationsMinutes = BlockMode.sanitizedQuickStartDurations(
                $0.quickStartDurationsMinutes.map { $0 == oldDuration ? newDuration : $0 }
            )
        }
    }
}

struct PermissionPanel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(
                    model.permissions.accessibilityTrusted ? "Accessibility allowed" : "Accessibility not allowed",
                    systemImage: model.permissions.accessibilityTrusted ? "checkmark.circle" : "exclamationmark.triangle"
                )
                Spacer()
                Button("Refresh") { model.refreshPermissions() }
                Button("Open Settings") { model.openAccessibilitySettings() }
            }
            Text(model.permissions.automationNote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct RunningAppsPicker: View {
    @EnvironmentObject private var model: AppModel
    @State private var runningApps = AppBlockingEngine.runningSelectableApps()
    @State private var selectedAppID: UUID?

    var body: some View {
        HStack {
            Picker("Running app", selection: $selectedAppID) {
                Text("Select running app").tag(Optional<UUID>.none)
                ForEach(runningApps) { app in
                    Text(app.displayName).tag(Optional(app.id))
                }
            }
            Button("Refresh") {
                runningApps = AppBlockingEngine.runningSelectableApps()
            }
            Button {
                guard let selectedAppID,
                      let app = runningApps.first(where: { $0.id == selectedAppID })
                else { return }
                model.addRunningApp(app)
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
    }
}

struct EditableAppsList: View {
    @EnvironmentObject private var model: AppModel
    let mode: BlockMode

    var body: some View {
        Table(mode.blockedApps) {
            TableColumn("Name") { Text($0.displayName) }
            TableColumn("Bundle ID") { Text($0.bundleIdentifier).foregroundStyle(.secondary) }
            TableColumn("") { app in
                Button {
                    model.updateSelectedMode { $0.blockedApps.removeAll { $0.id == app.id } }
                } label: {
                    Label("Remove", systemImage: "minus.circle")
                }
            }
            .width(80)
        }
        .frame(minHeight: 120)
    }
}

struct EditableWebsiteRulesList: View {
    @EnvironmentObject private var model: AppModel
    let mode: BlockMode

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(mode.websiteRules) { rule in
                HStack {
                    Toggle("", isOn: Binding(
                        get: { rule.isEnabled },
                        set: { value in
                            model.updateSelectedMode { mode in
                                guard let index = mode.websiteRules.firstIndex(where: { $0.id == rule.id }) else { return }
                                mode.websiteRules[index].isEnabled = value
                            }
                        }
                    ))
                    TextField("URL contains", text: Binding(
                        get: { rule.contains },
                        set: { value in
                            model.updateSelectedMode { mode in
                                guard let index = mode.websiteRules.firstIndex(where: { $0.id == rule.id }) else { return }
                                mode.websiteRules[index].contains = value
                            }
                        }
                    ))
                    Button {
                        model.updateSelectedMode { $0.websiteRules.removeAll { $0.id == rule.id } }
                    } label: {
                        Label("Remove", systemImage: "minus.circle")
                    }
                }
            }
        }
    }
}

struct EditableSchedulesList: View {
    @EnvironmentObject private var model: AppModel
    let mode: BlockMode

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                model.updateSelectedMode {
                    let duration = $0.quickStartDurationsMinutes.first ?? 50
                    $0.schedules.append(BlockSchedule(weekdays: [2, 3, 4, 5, 6], hour: 9, minute: 0, durationMinutes: duration))
                }
            } label: {
                Label("Add Weekday Schedule", systemImage: "calendar.badge.plus")
            }

            ForEach(mode.schedules) { schedule in
                ScheduleRow(schedule: schedule)
                    .environmentObject(model)
            }
        }
    }
}

struct ScheduleRow: View {
    @EnvironmentObject private var model: AppModel
    let schedule: BlockSchedule

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { schedule.isEnabled },
                set: { value in update { $0.isEnabled = value } }
            ))
            WeekdayToggles(schedule: schedule)
            Stepper("Hour \(schedule.hour)", value: Binding(
                get: { schedule.hour },
                set: { newValue in update { $0.hour = min(23, max(0, newValue)) } }
            ), in: 0...23)
            Stepper("Minute \(schedule.minute)", value: Binding(
                get: { schedule.minute },
                set: { newValue in update { $0.minute = min(59, max(0, newValue)) } }
            ), in: 0...59)
            Stepper("\(schedule.durationMinutes) min", value: Binding(
                get: { schedule.durationMinutes },
                set: { newValue in update { $0.durationMinutes = max(1, newValue) } }
            ), in: 1...600)
            Button {
                model.updateSelectedMode { $0.schedules.removeAll { $0.id == schedule.id } }
            } label: {
                Label("Remove", systemImage: "minus.circle")
            }
        }
    }

    private func update(_ mutate: @escaping (inout BlockSchedule) -> Void) {
        model.updateSelectedMode { mode in
            guard let index = mode.schedules.firstIndex(where: { $0.id == schedule.id }) else { return }
            mutate(&mode.schedules[index])
        }
    }
}

struct WeekdayToggles: View {
    @EnvironmentObject private var model: AppModel
    let schedule: BlockSchedule
    private let weekdays = [(1, "Sun"), (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat")]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(weekdays, id: \.0) { day, label in
                Toggle(label, isOn: Binding(
                    get: { schedule.weekdays.contains(day) },
                    set: { enabled in
                        model.updateSelectedMode { mode in
                            guard let index = mode.schedules.firstIndex(where: { $0.id == schedule.id }) else { return }
                            if enabled {
                                mode.schedules[index].weekdays.insert(day)
                            } else {
                                mode.schedules[index].weekdays.remove(day)
                            }
                        }
                    }
                ))
                .toggleStyle(.button)
            }
        }
    }
}

struct EventList: View {
    let events: [BlockEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(events) { event in
                HStack {
                    Image(systemName: event.succeeded ? "checkmark.circle" : "xmark.octagon")
                    Text(event.target).fontWeight(.semibold)
                    Text(event.message).foregroundStyle(.secondary)
                    Spacer()
                    Text(event.createdAt, style: .time).foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
    }
}
