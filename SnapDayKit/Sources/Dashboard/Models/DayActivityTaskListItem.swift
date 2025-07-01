import Foundation
import Models
import Utilities
import struct UiComponents.ListItem

extension DayActivityTask {
  func listItem(
    parentId: UUID,
    divider: ListItem.DividerType = .none
  ) -> ListItem {
    ListItem(
      id: id.uuidString,
      parentId: parentId.uuidString,
      title: name,
      subtitle: SubtitleFormatter.format(
        overview: overview,
        duration: duration
      ),
      fieldType: .text,
      iconType: .empty,
      isStrikethrough: doneDate != nil,
      displayedIcons: [
        reminderDate != nil ? .bell : nil
      ].compactMap { $0 },
      participants: [],
      divider: divider,
      isDraggable: false,
      priority: .normal,
      trailing: .menu(
        [
          doneDate != nil
          ? DayActivityTaskAction.deselect.trailingMenuItem
          : DayActivityTaskAction.select.trailingMenuItem,
          DayActivityTaskAction.edit.trailingMenuItem,
          DayActivityTaskAction.remove.trailingMenuItem
        ]
      ),
      progress: .none
    )
  }
}
