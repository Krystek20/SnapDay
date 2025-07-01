import Foundation
import Dependencies
import Models

import struct SwiftUI.Color
import struct UiComponents.ListItem

struct ListItemsBuilder {

  @Dependency(\.utcCalendar) private var calendar
  @Dependency(\.uuid) private var uuid

  let activities: [DayActivity]
  let hideCompleted: Bool
  let icons: [Icon]

  func build() -> [ListItem] {
    var listItems = [ListItem]()

    for dayActivity in activities {
      let ignoreActivity = hideCompleted && dayActivity.isDone
      guard !ignoreActivity else { continue }

      let containsTasks = !dayActivity.dayActivityTasks.isEmpty
      let isLast = dayActivity == activities.last
      let divider: ListItem.DividerType = containsTasks
      ? .indented
      : isLast ? .none : .full

      var iconData: Data?
      if let iconId = dayActivity.iconId,
         let icon = icons.first(where: { $0.id == iconId }) {
        iconData = icon.data
      }

      listItems.append(
        dayActivity.listItem(
          iconData: iconData,
          divider: divider,
          priority: dayActivity.priority(calendar: calendar)
        )
      )

      for task in dayActivity.dayActivityTasks {
        let ignoreTask = hideCompleted && task.isDone
        guard !ignoreActivity && !ignoreTask else { continue }

        let isLastTask = task == dayActivity.dayActivityTasks.last
        listItems.append(
          task.listItem(
            parentId: dayActivity.id,
            divider: isLastTask
            ? isLast ? .none : .full
            : .indented
          )
        )
      }
    }
    return listItems
  }
}
