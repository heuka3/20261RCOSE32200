import ApplicationServices
import Foundation

public struct PermissionSnapshot: Equatable, Sendable {
    public var accessibilityTrusted: Bool
    public var automationNote: String

    public init(accessibilityTrusted: Bool, automationNote: String) {
        self.accessibilityTrusted = accessibilityTrusted
        self.automationNote = automationNote
    }
}

public enum PermissionReader {
    public static func snapshot() -> PermissionSnapshot {
        PermissionSnapshot(
            accessibilityTrusted: AXIsProcessTrusted(),
            automationNote: "Safari/Chrome Automation permission is requested by macOS when browser control first runs."
        )
    }
}
