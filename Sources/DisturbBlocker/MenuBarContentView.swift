import DisturbBlockerCore
import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let session = model.activeSession {
                Text("\(session.modeName) active")
                Text(model.remainingText)
                    .font(.headline)
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

            Button("Start 25 min") { model.startSelectedMode(minutes: 25) }
            Button("Start 50 min") { model.startSelectedMode(minutes: 50) }
            Button("Start 90 min") { model.startSelectedMode(minutes: 90) }

            HStack {
                TextField("Minutes", text: $model.customDurationText)
                    .frame(width: 72)
                Button("Start") {
                    model.startSelectedMode(minutes: Int(model.customDurationText) ?? model.selectedMode?.defaultDurationMinutes ?? 50)
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
        .padding(.vertical, 4)
    }
}
