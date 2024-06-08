import Foundation
import Dependencies

public protocol TodayProvidable { }

public extension TodayProvidable {
  var today: Date {
    @Dependency(\.calendar) var calendar
    @Dependency(\.date.now) var now
    return calendar.dayFormat(now)
  }

  var tomorrow: Date {
    get throws {
      @Dependency(\.calendar) var calendar
      @Dependency(\.date.now) var now
      let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)
      return try calendar.dayFormat(tomorrow.unwrapped)
    }
  }
}
