import Foundation
import Models
import Utilities
import struct UiComponents.ListItem
import struct UiComponents.ListTrailingMenuItem
import struct UiComponents.ListTrailingMenuSubitem

extension DayActivity {
  func listItem(
    divider: ListItem.DividerType = .none,
    priority: Priority = .normal
  ) -> ListItem {
    let isDone = doneDate != nil
    var participants: [ListItem.Participant] = []
    if let share, !share.participants.filter(\.isShared).isEmpty {
      participants = share.participants.map {
        ListItem.Participant(id: $0.id, name: $0.name)
      }
    }

    var progress = ListItem.Progress.none
    if !dayActivityTasks.isEmpty {
      let doneTasks = dayActivityTasks.filter(\.isDone).count
      let totalTasks = dayActivityTasks.count
      progress = .line(value: Double(doneTasks), total: Double(totalTasks))
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
      priority: priority,
      trailing: trailing,
      progress: progress
    )
  }

  private var trailing: ListItem.Trailing {
    if share?.invitationId != nil {
      return .row(
        [
          DayActivityInvitationAction.accept.trailingMenuItem,
          DayActivityInvitationAction.discard.trailingMenuItem
        ]
      )
    } else {
      var menuActions: [ListTrailingMenuItem] = [
        isDone
        ? DayActivityAction.deselect.trailingMenuItem()
        : DayActivityAction.select.trailingMenuItem(),
        DayActivityAction.edit.trailingMenuItem(),
        DayActivityAction.addTask.trailingMenuItem(),
        important
        ? DayActivityAction.deselectImportant.trailingMenuItem()
        : DayActivityAction.selectImportant.trailingMenuItem()
      ]

      if isSavable {
        menuActions.append(DayActivityAction.save.trailingMenuItem())
      }
      menuActions.append(DayActivityAction.move.trailingMenuItem())
      menuActions.append(DayActivityAction.copy.trailingMenuItem())

      if let share {
        if share.isOwner {
          let subitems = share.availableParticipants.map(ListTrailingMenuSubitem.init)
          if !subitems.isEmpty {
            !share.availableParticipants.filter(\.isShared).isEmpty
            ? menuActions.append(DayActivityAction.deselectCollaborator.trailingMenuItem(subitems: subitems))
            : menuActions.append(DayActivityAction.selectCollaborator.trailingMenuItem(subitems: subitems))
          }
        } else {
          menuActions.append(DayActivityAction.stopCollaboration.trailingMenuItem())
        }
      }
      menuActions.append(DayActivityAction.remove.trailingMenuItem())

      return .menu(menuActions)
    }
  }
}
