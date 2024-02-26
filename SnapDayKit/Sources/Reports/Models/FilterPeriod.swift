import UiComponents
import Models
import Foundation

public enum FilterPeriod: Equatable, CaseIterable {
  case day
  case week
  case month
  case quarter
  case custom
}

extension FilterPeriod: Optionable {
  public var name: String {
    switch self {
    case .day:
      String(localized: "Day", bundle: .module)
    case .week:
      String(localized: "Week", bundle: .module)
    case .month:
      String(localized: "Month", bundle: .module)
    case .quarter:
      String(localized: "Quarter", bundle: .module)
    case .custom:
      String(localized: "Custom", bundle: .module)
    }
  }
}
