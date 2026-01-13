import Models
import Utilities
import struct UiComponents.ListItem
import struct UiComponents.ListTrailingMenuItem

extension ListItem {

  init(dayActivity: DayActivity) {
    let isDone = dayActivity.doneDate != nil
    var participants: [ListItem.Participant] = []
    if let share = dayActivity.share, !share.participants.filter(\.isShared).isEmpty {
      participants = share.participants.map {
        ListItem.Participant(id: $0.id, name: $0.name)
      }
    }

    var progress = ListItem.Progress.none
    if !dayActivity.dayActivityTasks.isEmpty {
      let doneTasks = dayActivity.dayActivityTasks.filter(\.isDone).count
      let totalTasks = dayActivity.dayActivityTasks.count
      progress = .line(value: Double(doneTasks), total: Double(totalTasks))
    }

    self.init(
      id: dayActivity.id.uuidString,
      parentId: nil,
      title: dayActivity.name,
      subtitle: SubtitleFormatter.format(
        overview: dayActivity.overview,
        duration: dayActivity.totalDuration
      ),
      fieldType: .text,
      iconType: .iconId(dayActivity.iconId),
      isStrikethrough: isDone,
      displayedIcons: [
        dayActivity.important ? .exclamationmark : nil,
        dayActivity.dueDate != nil ? .hourglass : nil,
        dayActivity.reminderDate != nil ? .bell : nil
      ].compactMap { $0 },
      participants: participants,
      divider: .none,
      isDraggable: false,
      priority: .normal,
      trailing: .none,
      progress: progress
    )
  }

  init(dayActivityTask: DayActivityTask) {
    self.init(
      id: dayActivityTask.id.uuidString,
      parentId: dayActivityTask.dayActivityId.uuidString,
      title: dayActivityTask.name,
      subtitle: SubtitleFormatter.format(
        overview: dayActivityTask.overview,
        duration: dayActivityTask.duration
      ),
      fieldType: .text,
      iconType: .empty,
      isStrikethrough:  dayActivityTask.doneDate != nil,
      displayedIcons: [
        dayActivityTask.reminderDate != nil ? .bell : nil
      ].compactMap { $0 },
      participants: [],
      divider: .none,
      isDraggable: false,
      priority: .normal,
      trailing: .none,
      progress: .none
    )
  }

  init(activity: Activity) {
    let tasksDuration = activity.tasks.reduce(into: Int.zero, { $0 += ($1.defaultDuration ?? .zero) })
    let totalDuration = (activity.defaultDuration ?? .zero) + tasksDuration
    let showHourglass = activity.dueDaysCount != nil && activity.dueDaysCount ?? .zero > .zero

    self.init(
      id: activity.id.uuidString,
      parentId: nil,
      title: activity.name,
      subtitle: SubtitleFormatter.format(
        overview: nil,
        duration: totalDuration
      ),
      fieldType: .text,
      iconType: .iconId(activity.iconId),
      isStrikethrough: false,
      displayedIcons: [
        activity.important ? .exclamationmark : nil,
        showHourglass ? .hourglass : nil,
        activity.defaultReminderDate != nil ? .bell : nil,
        activity.isFrequentEnabled ? .repeat : nil
      ].compactMap { $0 },
      participants: [],
      divider: .none,
      isDraggable: false,
      priority: .normal,
      trailing: .none,
      progress: .none
    )
  }

  init(activityTask: ActivityTask) {
    self.init(
      id: activityTask.id.uuidString,
      parentId: activityTask.activityId.uuidString,
      title: activityTask.name,
      subtitle: SubtitleFormatter.format(
        overview: nil,
        duration: activityTask.defaultDuration ?? .zero
      ),
      fieldType: .text,
      iconType: .empty,
      isStrikethrough:  false,
      displayedIcons: [
        activityTask.defaultReminderDate != nil ? .bell : nil
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
