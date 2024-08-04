import Foundation
import Dependencies

public protocol TodayProvidable { }

public extension TodayProvidable {

  var today: Date {
    Calendar.today
  }

  var tomorrow: Date {
    get throws {
      @Dependency(\.date.now) var now
      return try nextDay(now)
    }
  }

  private func nextDay(_ date: Date) throws -> Date {
    @Dependency(\.calendar) var calendar
    let nextDay = calendar.date(byAdding: .day, value: 1, to: date)
    return try calendar.dayFormat(nextDay.unwrapped)
  }
}
