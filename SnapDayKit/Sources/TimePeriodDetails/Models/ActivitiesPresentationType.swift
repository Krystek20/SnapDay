import Foundation
import Models

enum ActivitiesPresentationType: Equatable {
  case months([TimePeriod])
  case month(monthName: String, [CalendarItemType])
  case days([Day])
}

extension ActivitiesPresentationType {
  var title: String {
    switch self {
    case .months:
      String(localized: "Months", bundle: .module)
    case .month(let monthName, _):
      monthName
    case .days:
      String(localized: "Days", bundle: .module)
    }
  }
}

