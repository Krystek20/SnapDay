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
  case importantMark
  case imortantUnmark
  case collaborateUnmarked
  case collaborateMarked
  case stopCollaboration

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
    case .importantMark:
      String(localized: "Set as important", bundle: .module)
    case .imortantUnmark:
      String(localized: "Set as regular", bundle: .module)
    case .collaborateUnmarked, .collaborateMarked:
      String(localized: "Collaborate", bundle: .module)
    case .stopCollaboration:
      String(localized: "Stop Collaboration", bundle: .module)
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
    case .importantMark:
      "exclamationmark.circle"
    case .imortantUnmark:
      "exclamationmark.circle.fill"
    case .collaborateMarked:
      "person.2.circle.fill"
    case .collaborateUnmarked:
      "person.2.circle"
    case .stopCollaboration:
      "person.2.slash.fill"
    }
  }
}
