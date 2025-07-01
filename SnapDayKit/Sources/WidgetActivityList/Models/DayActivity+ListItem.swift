import Foundation
import Models
import Utilities
import struct UiComponents.ListItem
import enum UiComponents.ImageType

extension DayActivity {
  func listItem(
    iconData: Data?,
    divider: ListItem.DividerType = .none,
    priority: Priority = .normal
  ) -> ListItem {
    let isDone = doneDate != nil
    var participants: [ListItem.Participant] = []
    if let share, !share.availableParticipants.filter(\.isShared).isEmpty {
      participants = share.participants.map {
        ListItem.Participant(id: $0.id, name: $0.name)
      }
    }

    var iconType: ImageType = .placeholder
    if let iconData {
      iconType = .data(iconData)
    }

    return ListItem(
      id: id.uuidString,
      parentId: nil,
      title: name,
      subtitle: SubtitleFormatter.format(
        overview: overview,
        duration: totalDuration
      ),
      fieldType: .text,
      iconType: iconType,
      isStrikethrough: isDone,
      displayedIcons: [
        important ? .exclamationmark : nil,
        dueDate != nil ? .hourglass : nil,
        reminderDate != nil ? .bell : nil
      ].compactMap { $0 },
      participants: participants,
      divider: divider,
      isDraggable: !isDone,
      priority: priority,
      trailing: .none,
      progress: .none
    )
  }
}
