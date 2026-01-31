import Foundation
import Dependencies
import Models
import Utilities

import struct UiComponents.ListItem
import struct UiComponents.ListTrailingMenuItem

struct ListItemsBuilder {

  @Dependency(\.uuid) private var uuid

  let tasks: [DayActivityForm]
  let newField: DayNewField?

  func build() -> [ListItem] {
    var listItems = [ListItem]()
    if case .taskName = newField {
      let identifier = uuid()
      listItems.append(
        .form(
          id: identifier.uuidString,
          focus: identifier.uuidString,
          divider: .full,
          iconType: .empty
        )
      )
    }
    listItems.append(contentsOf: tasks.map(ListItem.init))
    return listItems
  }
}

enum DayActivityFormAction: String {
  case select
  case deselect
  case edit
  case remove
}

fileprivate extension ListItem {
  init(form: DayActivityForm) {
    self.init(
      id: form.id.uuidString,
      parentId: nil,
      headerItem: nil,
      title: form.name,
      subtitle: SubtitleFormatter.format(
        overview: form.overview,
        duration: form.duration
      ),
      fieldType: .text,
      iconType: .empty,
      isStrikethrough: form.completed,
      displayedIcons: [
        form.reminderDate != nil ? .bell : nil
      ].compactMap { $0 },
      participants: [],
      divider: .full,
      isDraggable: false,
      priority: .normal,
      trailing: .menu([
        form.completed
        ? DayActivityFormAction.deselect.trailingMenuItem
        : DayActivityFormAction.select.trailingMenuItem,
        DayActivityFormAction.edit.trailingMenuItem,
        DayActivityFormAction.remove.trailingMenuItem
      ]),
      progress: .none
    )
  }
}

extension DayActivityFormAction {
  var trailingMenuItem: ListTrailingMenuItem {
    let (title, imageName) = switch self {
    case .select:
      (String(localized: "Select", bundle: .module), "x.circle")
    case .deselect:
      (String(localized: "Deselect", bundle: .module), "checkmark.circle")
    case .edit:
      (String(localized: "Edit", bundle: .module), "pencil.circle")
    case .remove:
      (String(localized: "Remove", bundle: .module), "trash")
    }
    return ListTrailingMenuItem(
      actionId: rawValue,
      title: title,
      imageName: imageName
    )
  }
}
