import Foundation

public struct BlockMode: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var blockedApps: [BlockedApp]
    public var websiteRules: [WebsiteRule]
    public var defaultDurationMinutes: Int
    public var quickStartDurationsMinutes: [Int]
    public var schedules: [BlockSchedule]

    public init(
        id: UUID = UUID(),
        name: String,
        blockedApps: [BlockedApp] = [],
        websiteRules: [WebsiteRule] = [],
        defaultDurationMinutes: Int = 50,
        quickStartDurationsMinutes: [Int] = Self.defaultQuickStartDurationsMinutes,
        schedules: [BlockSchedule] = []
    ) {
        self.id = id
        self.name = name
        self.blockedApps = blockedApps
        self.websiteRules = websiteRules
        self.defaultDurationMinutes = defaultDurationMinutes
        self.quickStartDurationsMinutes = Self.normalizedQuickStartDurations(quickStartDurationsMinutes)
        self.schedules = schedules
    }

    public static let defaultQuickStartDurationsMinutes = [25, 50, 90]

    public static func normalizedQuickStartDurations(_ durations: [Int]) -> [Int] {
        let normalized = sanitizedQuickStartDurations(durations)
        return normalized.isEmpty ? defaultQuickStartDurationsMinutes : normalized
    }

    public static func sanitizedQuickStartDurations(_ durations: [Int]) -> [Int] {
        durations
            .map { min(600, max(1, $0)) }
            .uniqued()
            .sorted()
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case blockedApps
        case websiteRules
        case defaultDurationMinutes
        case quickStartDurationsMinutes
        case schedules
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        blockedApps = try container.decodeIfPresent([BlockedApp].self, forKey: .blockedApps) ?? []
        websiteRules = try container.decodeIfPresent([WebsiteRule].self, forKey: .websiteRules) ?? []
        defaultDurationMinutes = try container.decodeIfPresent(Int.self, forKey: .defaultDurationMinutes) ?? 50
        quickStartDurationsMinutes = Self.normalizedQuickStartDurations(
            try container.decodeIfPresent([Int].self, forKey: .quickStartDurationsMinutes) ?? Self.defaultQuickStartDurationsMinutes
        )
        schedules = try container.decodeIfPresent([BlockSchedule].self, forKey: .schedules) ?? []
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

public struct BlockedApp: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var displayName: String
    public var bundleIdentifier: String
    public var path: String

    public init(id: UUID = UUID(), displayName: String, bundleIdentifier: String, path: String) {
        self.id = id
        self.displayName = displayName
        self.bundleIdentifier = bundleIdentifier
        self.path = path
    }
}

public struct WebsiteRule: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var contains: String
    public var isEnabled: Bool

    public init(id: UUID = UUID(), contains: String, isEnabled: Bool = true) {
        self.id = id
        self.contains = contains
        self.isEnabled = isEnabled
    }
}

public struct BlockSchedule: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var weekdays: Set<Int>
    public var hour: Int
    public var minute: Int
    public var durationMinutes: Int
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        weekdays: Set<Int>,
        hour: Int,
        minute: Int,
        durationMinutes: Int,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.weekdays = weekdays
        self.hour = hour
        self.minute = minute
        self.durationMinutes = durationMinutes
        self.isEnabled = isEnabled
    }
}

public struct ActiveSession: Identifiable, Codable, Equatable, Sendable {
    public enum Source: String, Codable, Sendable {
        case manual
        case schedule
    }

    public var id: UUID
    public var modeID: UUID
    public var modeName: String
    public var startedAt: Date
    public var endsAt: Date
    public var source: Source

    public init(
        id: UUID = UUID(),
        modeID: UUID,
        modeName: String,
        startedAt: Date,
        endsAt: Date,
        source: Source
    ) {
        self.id = id
        self.modeID = modeID
        self.modeName = modeName
        self.startedAt = startedAt
        self.endsAt = endsAt
        self.source = source
    }

    public func remainingSeconds(at date: Date = Date()) -> Int {
        max(0, Int(endsAt.timeIntervalSince(date).rounded(.down)))
    }

    public func isActive(at date: Date = Date()) -> Bool {
        date < endsAt
    }
}

public struct BlockEvent: Identifiable, Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case app
        case website
        case permission
        case scheduler
        case debug
    }

    public var id: UUID
    public var createdAt: Date
    public var kind: Kind
    public var target: String
    public var message: String
    public var succeeded: Bool

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        kind: Kind,
        target: String,
        message: String,
        succeeded: Bool
    ) {
        self.id = id
        self.createdAt = createdAt
        self.kind = kind
        self.target = target
        self.message = message
        self.succeeded = succeeded
    }
}
