import Foundation

public protocol ModeStoring: AnyObject {
    func loadModes() throws -> [BlockMode]
    func saveModes(_ modes: [BlockMode]) throws
}

public final class UserDefaultsModeStore: ModeStoring {
    private let defaults: UserDefaults
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults = .standard, key: String = "disturbBlocker.blockModes") {
        self.defaults = defaults
        self.key = key
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func loadModes() throws -> [BlockMode] {
        guard let data = defaults.data(forKey: key) else {
            return Self.defaultModes
        }
        return try decoder.decode([BlockMode].self, from: data)
    }

    public func saveModes(_ modes: [BlockMode]) throws {
        let data = try encoder.encode(modes)
        defaults.set(data, forKey: key)
    }

    public static var defaultModes: [BlockMode] {
        []
    }
}
