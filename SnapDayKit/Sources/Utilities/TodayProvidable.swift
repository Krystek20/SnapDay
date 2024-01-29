import Foundation
import Dependencies

public protocol TodayProvidable { }

public extension TodayProvidable {
  var today: Date {
    @Dependency(\.calendar) var calendar
    @Dependency(\.date.now) var now
    return calendar.dayFormat(now)
  }
}
