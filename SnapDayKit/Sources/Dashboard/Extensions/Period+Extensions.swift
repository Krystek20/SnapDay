import Models

extension Period {
  var name: String {
    switch self {
    case .day:
      String(localized: "Day", bundle: .module)
    case .week:
      String(localized: "Week", bundle: .module)
    case .month:
      String(localized: "Month", bundle: .module)
    case .quarter:
      String(localized: "Quarter", bundle: .module)
    }
  }
}
