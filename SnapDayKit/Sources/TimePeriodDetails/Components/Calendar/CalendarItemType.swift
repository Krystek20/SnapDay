import Foundation
import Models

enum CalendarItemType: Equatable {
  case dayOfWeek(String)
  case day(Day)
  case empty(Int)
}

extension CalendarItemType: Identifiable {
  var id: String {
    switch self {
    case .dayOfWeek(let title):
      title
    case .day(let day):
      day.id.uuidString
    case .empty(let index):
      String(index)
    }
  }

  var day: Day? {
    guard case .day(let day) = self else { return nil }
    return day
  }
}
