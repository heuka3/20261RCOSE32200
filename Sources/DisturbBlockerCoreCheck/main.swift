import DisturbBlockerCore
import Foundation

enum CheckFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message):
            return message
        }
    }
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw CheckFailure.failed(message)
    }
}

func runChecks() throws {
    let rules = [WebsiteRule(contains: "YouTube")]
    let match = RuleMatcher.matchingRule(for: "https://m.youtube.com/watch?v=abc", rules: rules)
    try expect(match?.contains == "YouTube", "URL matching should be case-insensitive.")

    let disabledRules = [
        WebsiteRule(contains: "reddit", isEnabled: false),
        WebsiteRule(contains: "   ")
    ]
    try expect(RuleMatcher.matchingRule(for: "https://reddit.com", rules: disabledRules) == nil, "Disabled and empty rules should not match.")

    let now = Date(timeIntervalSince1970: 1_000)
    let session = ActiveSession(
        modeID: UUID(),
        modeName: "Work",
        startedAt: now.addingTimeInterval(-120),
        endsAt: now.addingTimeInterval(-1),
        source: .manual
    )
    try expect(session.remainingSeconds(at: now) == 0, "Remaining seconds should never go negative.")
    try expect(!session.isActive(at: now), "Expired sessions should be inactive.")

    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let date = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2026, month: 5, day: 26, hour: 9, minute: 30).date!
    let weekday = calendar.component(.weekday, from: date)
    let mode = BlockMode(
        name: "Work",
        schedules: [BlockSchedule(weekdays: [weekday], hour: 9, minute: 30, durationMinutes: 50)]
    )
    let triggers = ScheduleMatcher.dueTriggers(modes: [mode], at: date, calendar: calendar)
    try expect(triggers.count == 1, "Schedule should match weekday, hour, and minute.")
    try expect(triggers.first?.mode.name == "Work", "Schedule trigger should carry the matching mode.")

    let suiteName = "DisturbBlockerCoreCheck.\(UUID().uuidString)"
    let suite = UserDefaults(suiteName: suiteName)!
    defer { suite.removePersistentDomain(forName: suiteName) }
    let store = UserDefaultsModeStore(defaults: suite, key: "modes")
    let modes = [BlockMode(name: "Study", websiteRules: [WebsiteRule(contains: "news")])]
    try store.saveModes(modes)
    let loaded = try store.loadModes()
    try expect(loaded == modes, "Mode store should round-trip modes.")
}

do {
    try runChecks()
    print("DisturbBlockerCoreCheck passed.")
} catch {
    fputs("DisturbBlockerCoreCheck failed: \(error)\n", stderr)
    exit(1)
}
