import Models

enum DayActivityTaskMenuItem {
  case deselect
  case select
  case edit
  case remove

  var title: String {
    switch self {
    case .deselect:
      String(localized: "Deselect", bundle: .module)
    case .select:
      String(localized: "Select", bundle: .module)
    case .edit:
      String(localized: "Edit", bundle: .module)
    case .remove:
      String(localized: "Remove", bundle: .module)
    }
  }

  var imageName: String {
    switch self {
    case .deselect:
      "x.circle"
    case .select:
      "checkmark.circle"
    case .edit:
      "pencil.circle"
    case .remove:
      "trash"
    }
  }

  var dayActivityTaskAction: DayActivityActionType.DayActivityTaskAction {
    switch self {
    case .deselect, .select:
        .tapped
    case .edit:
        .edit
    case .remove:
        .remove
    }
  }
}
