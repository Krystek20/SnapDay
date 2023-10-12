import protocol UiComponents.Optionable

public enum DashboardOption: CaseIterable {
  case toDo
  case inProgress
  case completed
}

extension DashboardOption: Optionable {
  public var name: String {
    switch self {
    case .toDo:
      return String(localized: "To Do", bundle: .module)
    case .inProgress:
      return String(localized: "In Progress", bundle: .module)
    case .completed:
      return String(localized: "Completed", bundle: .module)
    }
  }
}
