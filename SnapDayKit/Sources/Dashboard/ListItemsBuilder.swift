import Foundation
import Dependencies
import Models

import struct SwiftUI.Color
import struct UiComponents.ListItem
import struct UiComponents.ListTrailingMenuItem
import struct UiComponents.ListTrailingMenuSubitem
import struct UiComponents.ListTrailingRowItem

struct ListItemsBuilder {

  @Dependency(\.utcCalendar) private var calendar
  @Dependency(\.uuid) private var uuid

  let activities: [DayActivity]
  let newField: DayNewField?
  let hideCompleted: Bool
  let hideTasks: Bool

  func build() -> [ListItem] {
    var listItems = [ListItem]()
    if newField == .activityName {
      let identifier = uuid()
      listItems.append(
        .form(
          id: identifier.uuidString,
          focus: identifier.uuidString,
          divider: activities.isEmpty ? .none : .full
        )
      )
    }

    for dayActivity in activities where hideCompleted ? !dayActivity.isDone : true {
      let isNextTask = !dayActivity.dayActivityTasks.isEmpty && !hideTasks
      let isTaskField = newField == .taskName(identifier: dayActivity.id.uuidString)
      let isLast = dayActivity == activities.last
      let divider: ListItem.DividerType = isNextTask || isTaskField
      ? .indented
      : isLast ? .none : .full

      listItems.append(
        dayActivity.listItem(
          divider: divider,
          priority: dayActivity.priority(calendar: calendar)
        )
      )

      if newField == .taskName(identifier: dayActivity.id.uuidString) {
        let identifier = uuid()
        listItems.append(
          .form(
            id: identifier.uuidString,
            focus: identifier.uuidString,
            divider: isNextTask ? .indented : activities.isEmpty ? .none : .full,
            iconType: .empty,
            parentId: dayActivity.id.uuidString
          )
        )
      }

      guard !hideTasks else { continue }
      let sortedTasks = dayActivity.dayActivityTasks
        .sorted(by: { $0.position < $1.position })
        .filter {
          hideCompleted ? !$0.isDone : true
        }

      listItems.append(
        contentsOf: sortedTasks.map { task in
          task.listItem(
            parentId: dayActivity.id,
            divider: task == sortedTasks.last
            ? isLast ? .none : .full
            : .indented
          )
        }
      )
    }

    return listItems
  }
}

public enum DayActivityAction: String {
  case select
  case deselect
  case edit
  case addTask
  case save
  case move
  case copy
  case remove
  case selectImportant
  case deselectImportant
  case selectCollaborator
  case deselectCollaborator
  case stopCollaboration
}

public enum DayActivityTaskAction: String {
  case select
  case deselect
  case edit
  case remove
}

public enum DayActivityInvitationAction: String {
  case accept
  case discard
}

public enum DayActivityCollaborationAction: String {
  case add
  case remove
}

extension DayActivityAction {
  func trailingMenuItem(subitems: [ListTrailingMenuSubitem] = []) -> ListTrailingMenuItem {
    let (title, imageName) = switch self {
    case .select:
      (String(localized: "Select", bundle: .module), "checkmark.circle")
    case .deselect:
      (String(localized: "Deselect", bundle: .module), "x.circle")
    case .edit:
      (String(localized: "Edit", bundle: .module), "pencil.circle")
    case .addTask:
      (String(localized: "Add task", bundle: .module), "plus.circle")
    case .save:
      (String(localized: "Save", bundle: .module), "square.and.arrow.down")
    case .move:
      (String(localized: "Move", bundle: .module), "arrow.left.and.right")
    case .copy:
      (String(localized: "Copy", bundle: .module), "doc.on.doc")
    case .remove:
      (String(localized: "Remove", bundle: .module), "trash")
    case .selectImportant:
      (String(localized: "Set as important", bundle: .module), "exclamationmark.circle")
    case .deselectImportant:
      (String(localized: "Set as regular", bundle: .module), "exclamationmark.circle.fill")
    case .selectCollaborator:
      (String(localized: "Collaborate", bundle: .module), "person.2.circle")
    case .deselectCollaborator:
      (String(localized: "Collaborate", bundle: .module), "person.2.circle.fill")
    case .stopCollaboration:
      (String(localized: "Stop Collaboration", bundle: .module), "person.2.slash.fill")
    }
    return ListTrailingMenuItem(
      actionId: rawValue,
      title: title,
      imageName: imageName,
      subitems: subitems
    )
  }
}

extension DayActivityTaskAction {
  var trailingMenuItem: ListTrailingMenuItem {
    let (title, imageName) = switch self {
    case .select:
      (String(localized: "Select", bundle: .module), "checkmark.circle")
    case .deselect:
      (String(localized: "Deselect", bundle: .module), "x.circle")
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

extension DayActivityInvitationAction {
  var trailingMenuItem: ListTrailingRowItem {
    switch self {
    case .accept:
      .accept(actionId: rawValue)
    case .discard:
      .discard(actionId: rawValue)
    }
  }
}

extension ListTrailingMenuSubitem {
  init(_ participant: DayActivityParticipant) {
    let action: DayActivityCollaborationAction = participant.isShared ? .remove : .add
    let imageName = switch action {
    case .add:
      "person.badge.plus"
    case .remove:
      "person.badge.minus"
    }
    self.init(
      itemId: participant.id,
      actionId: action.rawValue,
      title: participant.name,
      imageName: imageName
    )
  }
}
