import Foundation

public enum Period: String, Equatable, Hashable, CaseIterable {
  case day
  case week
  case month
  case quarter
}

extension Period: Identifiable {
  public var id: Self { self }
}

extension Period {
  public var calendarComponent: Calendar.Component {
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
