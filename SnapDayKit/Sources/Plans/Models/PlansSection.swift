import Foundation

enum PlansSection: String, CaseIterable, Equatable, Identifiable {
  case active
  case history

  var id: Self {
    self
  }

  var title: String.LocalizationValue {
    switch self {
    case .active:
      "Active"
    case .history:
      "History"
    }
  }
}
