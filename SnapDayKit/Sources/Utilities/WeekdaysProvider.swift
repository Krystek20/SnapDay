import Foundation
import Dependencies
import Models

public struct WeekdaysProvider {

  // MARK: - Dependecies

  @Dependency(\.utcCalendar) private var calendar

  // MARK: - Initialization

  public init() { }

  // MARK: - Public

  public var weekdays: [Weekday] {
    let weekdays = calendar.shortWeekdaySymbols.enumerated().map { index, name in
      Weekday(name: name, index: index + 1)
    }
    let adjustedFirstWeekday = max(calendar.firstWeekday, 1)
    return Array(weekdays.suffix(from: adjustedFirstWeekday - 1) + weekdays.prefix(adjustedFirstWeekday - 1))
  }
}
