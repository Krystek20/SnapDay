import Foundation
import Models

enum ActivitiesPresentationType: Equatable {
  case monthsList([TimePeriod])
  case calendar(monthName: String, [CalendarItemType])
  case daysList([Day])
}

extension ActivitiesPresentationType {
  var title: String {
    switch self {
    case .monthsList:
      String(localized: "Months", bundle: .module)
    case .calendar(let monthName, _):
      monthName
    case .daysList:
      String(localized: "Days", bundle: .module)
    }
  }
}

