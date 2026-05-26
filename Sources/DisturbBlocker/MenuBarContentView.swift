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

            HStack {
                TextField("Minutes", text: $model.customDurationText)
                    .frame(width: 72)
                Button("Start") {
                    model.startSelectedMode(minutes: model.customDurationMinutes())
                }
            }

            ForEach(model.selectedMode?.quickStartDurationsMinutes ?? [], id: \.self) { minutes in
                Button("Start \(minutes) min") {
                    model.startSelectedMode(minutes: minutes)
                }
            }

            Button("Start Default (\(model.selectedMode?.defaultDurationMinutes ?? 50) min)") {
                model.startSelectedMode()
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
