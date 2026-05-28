import DisturbBlockerCore
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let session = model.activeSession {
                Text("\(session.modeName) active")
                Text(model.remainingText)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.semibold)
                Button("Stop Session") {
                    model.stopSession()
                }
                Divider()
            }

            if model.activeSession == nil {
                Picker("Mode", selection: Binding(
                    get: { model.selectedModeID },
                    set: { model.selectedModeID = $0 }
                )) {
                    ForEach(model.modes) { mode in
                        Text(mode.name).tag(Optional(mode.id))
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Custom duration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Text("For")
                            .foregroundStyle(.secondary)
                            .frame(width: 44, alignment: .leading)
                        TextField("Minutes", text: Binding(
                            get: { model.customDurationText },
                            set: { model.setCustomDurationText($0) }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 84)
                        Text("min")
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .leading)
                        Button("Start") {
                            guard let minutes = model.customDurationMinutes() else { return }
                            model.startSelectedMode(minutes: minutes)
                        }
                        .keyboardShortcut(.return, modifiers: [])
                        .disabled(model.customDurationMinutes() == nil || model.selectedMode == nil)
                    }

                    HStack(spacing: 8) {
                        Text("Until")
                            .foregroundStyle(.secondary)
                            .frame(width: 44, alignment: .leading)
                        DatePicker("", selection: Binding(
                            get: { model.customEndTime },
                            set: { model.setCustomEndTime($0) }
                        ), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .frame(minWidth: 132, alignment: .leading)
                    }
                    Text(model.customDurationSummaryText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("Quick starts")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(model.selectedMode?.quickStartDurationsMinutes ?? [], id: \.self) { minutes in
                    Button("Start \(minutes) min") {
                        model.startSelectedMode(minutes: minutes)
                    }
                }
                Divider()
            }

            Button("Settings...") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "settings")
            }

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .padding(14)
        .frame(width: 330)
    }
}
