import AppKit
import Foundation

public final class AppBlockingEngine {
    public var isDryRun: Bool

    public init(isDryRun: Bool = false) {
        self.isDryRun = isDryRun
    }

    public func enforce(mode: BlockMode) -> [BlockEvent] {
        guard !mode.blockedApps.isEmpty else { return [] }

        let blockedByBundleID = Dictionary(uniqueKeysWithValues: mode.blockedApps.map {
            ($0.bundleIdentifier, $0)
        })

        return NSWorkspace.shared.runningApplications.compactMap { runningApp in
            guard let bundleIdentifier = runningApp.bundleIdentifier,
                  let blocked = blockedByBundleID[bundleIdentifier]
            else {
                return nil
            }

            if isDryRun {
                return BlockEvent(
                    kind: .app,
                    target: blocked.displayName,
                    message: "Dry run: would terminate \(blocked.displayName).",
                    succeeded: true
                )
            }

            let succeeded = runningApp.terminate()
            return BlockEvent(
                kind: .app,
                target: blocked.displayName,
                message: succeeded ? "Terminated \(blocked.displayName)." : "Failed to terminate \(blocked.displayName).",
                succeeded: succeeded
            )
        }
    }

    public static func runningSelectableApps() -> [BlockedApp] {
        NSWorkspace.shared.runningApplications.compactMap { app in
            guard let bundleIdentifier = app.bundleIdentifier,
                  let url = app.bundleURL
            else {
                return nil
            }

            return BlockedApp(
                displayName: app.localizedName ?? url.deletingPathExtension().lastPathComponent,
                bundleIdentifier: bundleIdentifier,
                path: url.path
            )
        }
        .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
}
