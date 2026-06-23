import Foundation
import Models
import Utilities
import struct UiComponents.ListItem

extension DayActivity {
  func listItem(
    divider: ListItem.DividerType = .none
  ) -> ListItem {
    let isDone = doneDate != nil
    var participants: [ListItem.Participant] = []
    if let share, !share.availableParticipants.filter(\.isShared).isEmpty {
      participants = share.participants.map {
        ListItem.Participant(id: $0.id, name: $0.name)
      }
    }

    return ListItem(
      id: id.uuidString,
      parentId: nil,
      headerItem: nil,
      title: name,
      subtitle: SubtitleFormatter.format(
        overview: overview,
        duration: totalDuration
      ),
      fieldType: .text,
      iconType: .iconId(iconId),
      isStrikethrough: isDone,
      displayedIcons: [
        important ? .exclamationmark : nil,
        dueDate != nil ? .hourglass : nil,
        reminderDate != nil ? .bell : nil
      ].compactMap { $0 },
      participants: participants,
      divider: divider,
      isDraggable: !isDone,
      priority: .normal,
      trailing: .none,
      progress: .none
    )
  }
}
