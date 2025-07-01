import Foundation
import Models
import Utilities
import struct UiComponents.ListItem

extension DayActivityTask {
  func listItem(
    parentId: UUID
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
      divider: .none,
      isDraggable: false,
      priority: .normal,
      trailing: .none,
      progress: .none
    )
  }
}
