import SwiftUI

@main
struct DisturbBlockerApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(model)
        } label: {
            Label(model.activeSession == nil ? "Disturb Blocker" : model.remainingText, systemImage: model.activeSession == nil ? "moon" : "timer")
        }
        .menuBarExtraStyle(.menu)

        Window("Disturb Blocker Settings", id: "settings") {
            SettingsView()
                .environmentObject(model)
                .frame(minWidth: 900, minHeight: 620)
        }
    }
}
