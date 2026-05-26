import Foundation

public struct ScheduleTrigger: Hashable, Sendable {
    public var modeID: UUID
    public var scheduleID: UUID
    public var dayKey: String
    public var hour: Int
    public var minute: Int

    public init(modeID: UUID, scheduleID: UUID, dayKey: String, hour: Int, minute: Int) {
        self.modeID = modeID
        self.scheduleID = scheduleID
        self.dayKey = dayKey
        self.hour = hour
        self.minute = minute
    }
}

public enum ScheduleMatcher {
    public static func dueTriggers(
        modes: [BlockMode],
        at date: Date,
        calendar: Calendar = .current
    ) -> [(mode: BlockMode, schedule: BlockSchedule, trigger: ScheduleTrigger)] {
        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let dayKey = dayFormatter(calendar: calendar).string(from: date)

        return modes.flatMap { mode in
            mode.schedules.compactMap { schedule in
                guard schedule.isEnabled,
                      schedule.weekdays.contains(weekday),
                      schedule.hour == hour,
                      schedule.minute == minute
                else {
                    return nil
                }

                let trigger = ScheduleTrigger(
                    modeID: mode.id,
                    scheduleID: schedule.id,
                    dayKey: dayKey,
                    hour: hour,
                    minute: minute
                )
                return (mode, schedule, trigger)
            }
        }
    }

    private static func dayFormatter(calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}
