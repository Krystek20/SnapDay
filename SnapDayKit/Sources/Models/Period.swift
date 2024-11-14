import Foundation

public enum Period: String, Equatable, Hashable, CaseIterable {
  case day
  case week
  case month
  case quarter
  case year
}

extension Period: Identifiable {
  public var id: String { self.rawValue }
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
    case .year:
        .year
    }
  }

  public var unit: Period {
    switch self {
    case .day, .week:
      .day
    case .month:
      .week
    case .quarter, .year:
      .month
    }
  }
}
