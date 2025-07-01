import Foundation
import Dependencies
import Models
import Utilities

import struct UiComponents.ListItem
import struct UiComponents.ListTrailingMenuItem

struct ListItemsBuilder {

  @Dependency(\.uuid) private var uuid

  let activities: [Activity]
  let newField: DayNewField?
  let searchText: String

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

    let filteredActivities = searchText.isEmpty
    ? activities
    : activities.filter { $0.name.contains(searchText) }

    for activity in filteredActivities {
      let isLast = activity == filteredActivities.last
      listItems.append(
        activity.listItem(
          divider: isLast ? .none : .full
        )
      )
    }
    return listItems
  }
}

extension Activity {
  func listItem(
    divider: ListItem.DividerType = .none,
    priority: Priority = .normal
  ) -> ListItem {
    let tasksDuration = tasks.reduce(into: Int.zero, { $0 += ($1.defaultDuration ?? .zero) })
    let totalDuration = (defaultDuration ?? .zero) + tasksDuration
    let showHourglass = dueDaysCount != nil && dueDaysCount ?? .zero > .zero

    return ListItem(
      id: id.uuidString,
      parentId: nil,
      title: name,
      subtitle: SubtitleFormatter.format(
        overview: nil,
        duration: totalDuration
      ),
      fieldType: .text,
      iconType: .iconId(iconId),
      isStrikethrough: false,
      displayedIcons: [
        important ? .exclamationmark : nil,
        showHourglass ? .hourglass : nil,
        defaultReminderDate != nil ? .bell : nil,
        isFrequentEnabled ? .repeat : nil
      ].compactMap { $0 },
      participants: [],
      divider: divider,
      isDraggable: false,
      priority: priority,
      trailing: .menu(
        [
          ActivityAction.addToDay.trailingMenuItem,
          ActivityAction.edit.trailingMenuItem,
          isFrequentEnabled
          ? ActivityAction.disable.trailingMenuItem
          : ActivityAction.enable.trailingMenuItem,
          ActivityAction.remove.trailingMenuItem
        ]
      ),
      progress: .none
    )
  }
}

enum ActivityAction: String {
  case addToDay
  case edit
  case enable
  case disable
  case remove
}

fileprivate extension ActivityAction {
  var trailingMenuItem: ListTrailingMenuItem {
    let (title, imageName) = switch self {
    case .addToDay:
      (String(localized: "Add to day", bundle: .module), "plus.circle")
    case .edit:
      (String(localized: "Edit", bundle: .module), "pencil.circle")
    case .enable:
      (String(localized: "Enable Repeat", bundle: .module), "repeat.circle")
    case .disable:
      (String(localized: "Disable Repeat", bundle: .module), "repeat.circle.fill")
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
