import SwiftUI
import Models
import Utilities
import struct UiComponents.ListItem
import struct UiComponents.ListTrailingMenuItem
import struct UiComponents.ListTrailingRowItem
import struct UiComponents.ListViewHeaderItem

enum ListItemHeaderAction: String {
  case acceptAll
}

enum ListItemRowAction: String {
  case accept
  case discard
}

struct ListItemConfiguration {
  let identifier: String
  let decisionType: DecisionType
  let showDivider: Bool
  let showAcceptAll: Bool
  let showTrailingView: Bool
}

extension ListItem {
  init(configuration: ListItemConfiguration) {
    switch configuration.decisionType {
    case .createDayActivity(let dayActivity):
      self.init(dayActivity: dayActivity, configuration: configuration)
    case .updateDayActivity(let dayActivity):
      self.init(dayActivity: dayActivity, configuration: configuration)
    case .deleteDayActivity(let dayActivity):
      self.init(dayActivity: dayActivity, configuration: configuration)
    case .createDayActivityTask(_, let dayActivityTask):
      self.init(dayActivityTask: dayActivityTask, configuration: configuration)
    case .updateDayActivityTask(let dayActivityTask):
      self.init(dayActivityTask: dayActivityTask, configuration: configuration)
    case .deleteDayActivityTask(let dayActivityTask):
      self.init(dayActivityTask: dayActivityTask, configuration: configuration)
    case .createActivity(let activity):
      self.init(activity: activity, configuration: configuration)
    case .updateActivity(let activity):
      self.init(activity: activity, configuration: configuration)
    case .deleteActivity(let activity):
      self.init(activity: activity, configuration: configuration)
    case .createActivityTask(_, let activityTask):
      self.init(activityTask: activityTask, configuration: configuration)
    case .updateActivityTask(_, let activityTask):
      self.init(activityTask: activityTask, configuration: configuration)
    case .deleteActivityTask(_, let activityTask):
      self.init(activityTask: activityTask, configuration: configuration)
    }
  }

  private init(dayActivity: DayActivity, configuration: ListItemConfiguration) {
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
      id: configuration.identifier,
      parentId: nil,
      headerItem: .header(configuration: configuration),
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
      divider: configuration.showDivider ? .aligned : .none,
      isDraggable: false,
      priority: .normal,
      trailing: configuration.showTrailingView ? .row(.decisionItems) : .none,
      progress: progress
    )
  }

  private init(dayActivityTask: DayActivityTask, configuration: ListItemConfiguration) {
    self.init(
      id: configuration.identifier,
      parentId: nil,
      headerItem: .header(configuration: configuration),
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
      divider: configuration.showDivider ? .aligned : .none,
      isDraggable: false,
      priority: .normal,
      trailing: configuration.showTrailingView ? .row(.decisionItems) : .none,
      progress: .none
    )
  }

  private init(activity: Activity, configuration: ListItemConfiguration) {
    let tasksDuration = activity.tasks.reduce(into: Int.zero, { $0 += ($1.defaultDuration ?? .zero) })
    let totalDuration = (activity.defaultDuration ?? .zero) + tasksDuration
    let showHourglass = activity.dueDaysCount != nil && activity.dueDaysCount ?? .zero > .zero

    self.init(
      id: configuration.identifier,
      parentId: nil,
      headerItem: .header(configuration: configuration),
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
      divider: configuration.showDivider ? .aligned : .none,
      isDraggable: false,
      priority: .normal,
      trailing: configuration.showTrailingView ? .row(.decisionItems) : .none,
      progress: .none
    )
  }

  private init(activityTask: ActivityTask, configuration: ListItemConfiguration) {
    self.init(
      id: configuration.identifier,
      parentId: nil,
      headerItem: .header(configuration: configuration),
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
      divider: configuration.showDivider ? .aligned : .none,
      isDraggable: false,
      priority: .normal,
      trailing: configuration.showTrailingView ? .row(.decisionItems) : .none,
      progress: .none
    )
  }
}

private extension [ListTrailingRowItem] {
  static let decisionItems = [
    ListTrailingRowItem.discard(actionId: ListItemRowAction.discard.rawValue),
    ListTrailingRowItem.accept(actionId: ListItemRowAction.accept.rawValue),
  ]
}

private extension ListViewHeaderItem {
  static func header(configuration: ListItemConfiguration) -> ListViewHeaderItem {
    let trailingAction = ListViewHeaderItem.ListViewHeaderAction(
      identifier: ListItemHeaderAction.acceptAll.rawValue,
      title: "Accept all"
    )
    return ListViewHeaderItem(
      title: configuration.decisionType.title,
      trailingAction: configuration.showAcceptAll ? trailingAction : nil
    )
  }
}
