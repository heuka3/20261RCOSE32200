import AppKit
import Combine
import DisturbBlockerCore
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var modes: [BlockMode] = []
    @Published var selectedModeID: UUID?
    @Published var activeSession: ActiveSession?
    @Published var events: [BlockEvent] = []
    @Published var customDurationText = ""
    @Published var customEndTime = Date().addingTimeInterval(25 * 60)
    @Published var customEndHourText = ""
    @Published var customEndMinuteText = ""
    @Published var permissions = PermissionReader.snapshot()
    @Published var isDryRun = false
    @Published private var now = Date()

    private let store: any ModeStoring
    private var blockingCoordinator = BlockingCoordinator()
    private var enforcementTimer: Timer?
    private var scheduleTimer: Timer?
    private var uiTimer: Timer?
    private var triggeredSchedules = Set<ScheduleTrigger>()
    private var customDurationInputMode: CustomDurationInputMode = .minutes

    init(store: any ModeStoring = UserDefaultsModeStore()) {
        self.store = store
        load()
        syncEndTimeTextFromDate()
        startTimers()
    }

    var selectedMode: BlockMode? {
        get {
            modes.first { $0.id == selectedModeID } ?? modes.first
        }
        set {
            selectedModeID = newValue?.id
        }
    }

    var activeMode: BlockMode? {
        guard let activeSession else { return nil }
        return modes.first { $0.id == activeSession.modeID }
    }

    var remainingText: String {
        guard let activeSession else { return "Inactive" }
        let seconds = activeSession.remainingSeconds(at: now)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    var customEndTimeText: String {
        Self.timeFormatter.string(from: customEndTime)
    }

    var customDurationSummaryText: String {
        guard let minutes = customDurationMinutes() else { return "Enter minutes or pick an end time" }
        return "\(minutes) min until \(customEndTimeText)"
    }

    func load() {
        do {
            modes = try store.loadModes()
            selectedModeID = modes.first?.id
        } catch {
            modes = []
            log(.init(kind: .debug, target: "Store", message: "Failed to load modes: \(error.localizedDescription)", succeeded: false))
        }
    }

    func save() {
        do {
            try store.saveModes(modes)
        } catch {
            log(.init(kind: .debug, target: "Store", message: "Failed to save modes: \(error.localizedDescription)", succeeded: false))
        }
    }

    func startSelectedMode(minutes: Int? = nil, source: ActiveSession.Source = .manual) {
        guard let mode = selectedMode else { return }
        start(mode: mode, minutes: minutes ?? mode.defaultDurationMinutes, source: source)
    }

    func customDurationMinutes() -> Int? {
        guard let minutes = Int(customDurationText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }
        return max(1, minutes)
    }

    func setCustomDurationText(_ text: String) {
        customDurationInputMode = .minutes
        customDurationText = text
        guard let minutes = customDurationMinutes() else { return }
        customEndTime = now.addingTimeInterval(TimeInterval(minutes * 60))
        syncEndTimeTextFromDate()
    }

    func setCustomEndTime(_ date: Date) {
        customDurationInputMode = .endTime
        let resolvedEndTime = resolvedFutureTime(matchingTimeOfDay: date)
        customEndTime = resolvedEndTime
        syncEndTimeTextFromDate()
        syncDurationTextFromEndTime()
    }

    func setCustomEndHourText(_ text: String) {
        customDurationInputMode = .endTime
        customEndHourText = text
        updateCustomEndTimeFromText()
    }

    func setCustomEndMinuteText(_ text: String) {
        customDurationInputMode = .endTime
        customEndMinuteText = text
        updateCustomEndTimeFromText()
    }

    func start(mode: BlockMode, minutes: Int, source: ActiveSession.Source) {
        let now = Date()
        activeSession = ActiveSession(
            modeID: mode.id,
            modeName: mode.name,
            startedAt: now,
            endsAt: now.addingTimeInterval(TimeInterval(max(1, minutes) * 60)),
            source: source
        )
        selectedModeID = mode.id
        log(.init(kind: source == .schedule ? .scheduler : .debug, target: mode.name, message: "Started for \(minutes) minutes.", succeeded: true))
        enforceNow()
    }

    func stopSession() {
        guard let activeSession else { return }
        log(.init(kind: .debug, target: activeSession.modeName, message: "Stopped session.", succeeded: true))
        self.activeSession = nil
    }

    func addMode() {
        let mode = BlockMode(name: "New Mode", defaultDurationMinutes: 50)
        modes.append(mode)
        selectedModeID = mode.id
        save()
    }

    func deleteSelectedMode() {
        guard let selectedModeID else { return }
        modes.removeAll { $0.id == selectedModeID }
        self.selectedModeID = modes.first?.id
        if activeSession?.modeID == selectedModeID {
            activeSession = nil
        }
        save()
    }

    func updateSelectedMode(_ update: (inout BlockMode) -> Void) {
        guard let id = selectedModeID, let index = modes.firstIndex(where: { $0.id == id }) else { return }
        update(&modes[index])
        save()
    }

    func addRunningApp(_ app: BlockedApp) {
        updateSelectedMode { mode in
            guard !mode.blockedApps.contains(where: { $0.bundleIdentifier == app.bundleIdentifier }) else { return }
            mode.blockedApps.append(app)
        }
    }

    func refreshPermissions() {
        permissions = PermissionReader.snapshot()
    }

    func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    func log(_ event: BlockEvent) {
        events.insert(event, at: 0)
        if events.count > 80 {
            events.removeLast(events.count - 80)
        }
    }

    private func startTimers() {
        uiTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateClock() }
        }
        enforcementTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        scheduleTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkSchedules() }
        }
    }

    private func updateClock() {
        now = Date()
        if customDurationInputMode == .endTime {
            syncDurationTextFromEndTime()
        }
    }

    private func syncDurationTextFromEndTime() {
        let seconds = max(60, customEndTime.timeIntervalSince(now))
        let minutes = Int(ceil(seconds / 60))
        customDurationText = "\(minutes)"
    }

    private func syncEndTimeTextFromDate() {
        let calendar = Calendar.current
        customEndHourText = String(format: "%02d", calendar.component(.hour, from: customEndTime))
        customEndMinuteText = String(format: "%02d", calendar.component(.minute, from: customEndTime))
    }

    private func updateCustomEndTimeFromText() {
        guard let hour = Int(customEndHourText.trimmingCharacters(in: .whitespacesAndNewlines)),
              let minute = Int(customEndMinuteText.trimmingCharacters(in: .whitespacesAndNewlines))
        else {
            return
        }

        customEndTime = resolvedFutureTime(hour: min(23, max(0, hour)), minute: min(59, max(0, minute)))
        syncDurationTextFromEndTime()
    }

    private func resolvedFutureTime(matchingTimeOfDay date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return resolvedFutureTime(hour: components.hour ?? 0, minute: components.minute ?? 0)
    }

    private func resolvedFutureTime(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        var resolved = calendar.nextDate(
            after: now.addingTimeInterval(-1),
            matching: components,
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        ) ?? now.addingTimeInterval(60)

        if resolved <= now {
            resolved = calendar.date(byAdding: .day, value: 1, to: resolved) ?? resolved.addingTimeInterval(24 * 60 * 60)
        }

        return resolved
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private enum CustomDurationInputMode {
        case minutes
        case endTime
    }

    private func tick() {
        updateClock()
        refreshPermissions()
        guard let activeSession else { return }
        if !activeSession.isActive() {
            self.activeSession = nil
            log(.init(kind: .debug, target: activeSession.modeName, message: "Session ended.", succeeded: true))
            return
        }
        enforceNow()
    }

    private func enforceNow() {
        guard let activeMode else { return }
        let appEngine = AppBlockingEngine(isDryRun: isDryRun)
        let browserEngine = BrowserBlockingEngine(isDryRun: isDryRun)
        blockingCoordinator = BlockingCoordinator(appEngine: appEngine, browserEngine: browserEngine)
        blockingCoordinator.enforce(mode: activeMode).forEach(log)
    }

    private func checkSchedules() {
        guard activeSession == nil else { return }
        let due = ScheduleMatcher.dueTriggers(modes: modes, at: Date())
        for item in due where !triggeredSchedules.contains(item.trigger) {
            triggeredSchedules.insert(item.trigger)
            start(mode: item.mode, minutes: item.schedule.durationMinutes, source: .schedule)
            break
        }
    }
}
