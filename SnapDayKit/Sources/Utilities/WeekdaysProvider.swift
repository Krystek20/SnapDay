import Foundation
import Dependencies
import Models

public struct WeekdaysProvider {

  // MARK: - Initialization

  public init() { }

  // MARK: - Public

  public var weekdays: [Weekday] {
    var calendar = Calendar.autoupdatingCurrent.utcCalendar
    calendar.locale = .preferred
    let weekdays = calendar.shortWeekdaySymbols.enumerated().map { index, name in
      Weekday(name: name, index: index + 1)
    }
    let adjustedFirstWeekday = max(calendar.firstWeekday, 1)
    return Array(weekdays.suffix(from: adjustedFirstWeekday - 1) + weekdays.prefix(adjustedFirstWeekday - 1))
  }
}
