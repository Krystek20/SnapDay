import Foundation

public enum Period: String, Equatable, Hashable, CaseIterable {
  case day
  case week
  case month
  case quarter
}

public extension Period {
  var calendarComponent: Calendar.Component {
    switch self {
    case .day:
        .day
    case .week:
        .weekOfYear
    case .month:
        .month
    case .quarter:
        .quarter
    }
  }
}
