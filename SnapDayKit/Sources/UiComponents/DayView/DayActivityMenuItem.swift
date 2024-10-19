import Models

enum DayActivityMenuItem {
  case deselect
  case select
  case edit
  case addTask
  case save
  case move
  case copy
  case remove
  case markImportant
  case unmarkImortant

  var title: String {
    switch self {
    case .deselect:
      String(localized: "Deselect", bundle: .module)
    case .select:
      String(localized: "Select", bundle: .module)
    case .edit:
      String(localized: "Edit", bundle: .module)
    case .addTask:
      String(localized: "Add task", bundle: .module)
    case .save:
      String(localized: "Save", bundle: .module)
    case .move:
      String(localized: "Move", bundle: .module)
    case .copy:
      String(localized: "Copy", bundle: .module)
    case .remove:
      String(localized: "Remove", bundle: .module)
    case .markImportant:
      String(localized: "Set as important", bundle: .module)
    case .unmarkImortant:
      String(localized: "Set as regular", bundle: .module)
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
    case .addTask:
      "plus.circle"
    case .save:
      "square.and.arrow.down"
    case .move:
      "arrow.left.and.right"
    case .copy:
      "doc.on.doc"
    case .remove:
      "trash"
    case .markImportant:
      "exclamationmark.circle"
    case .unmarkImortant:
      "exclamationmark.circle.fill"
    }
  }

  var dayActivityAction: DayActivityActionType.DayActivityAction {
    switch self {
    case .deselect, .select:
        .tapped
    case .edit:
        .edit
    case .addTask:
        .addActivityTask
    case .save:
        .save
    case .move:
        .move
    case .copy:
        .copy
    case .remove:
        .remove
    case .markImportant:
        .markImportant
    case .unmarkImortant:
        .unmarkImportant
    }
  }
}
