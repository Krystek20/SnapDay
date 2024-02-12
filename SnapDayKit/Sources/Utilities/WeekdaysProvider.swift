import Foundation
import Dependencies
import Models

public struct WeekdaysProvider {

  // MARK: - Dependecies

  private var calendar: Calendar

  // MARK: - Initialization

  public init(calendar: Calendar) {
    self.calendar = calendar
  }

  // MARK: - Public

  public var weekdays: [Weekday] {
    let weekdays = calendar.shortWeekdaySymbols.enumerated().map { index, name in
      Weekday(name: name, index: index + 1)
    }
    let adjustedFirstWeekday = max(calendar.firstWeekday, 1)
    return Array(weekdays.suffix(from: adjustedFirstWeekday - 1) + weekdays.prefix(adjustedFirstWeekday - 1))
  }
}
