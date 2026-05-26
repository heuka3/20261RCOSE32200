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
                HStack {
                    TextField("Minutes", text: $model.customDurationText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 92)
                    Text("min")
                        .foregroundStyle(.secondary)
                    Button("Start") {
                        model.startSelectedMode(minutes: model.customDurationMinutes())
                    }
                    .keyboardShortcut(.return, modifiers: [])
                }
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

            Button("Settings...") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "settings")
            }

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .padding(14)
        .frame(width: 260)
    }
}
