import Foundation
import Models

extension DayActivity {
  public static func create(
    from activity: Activity,
    uuid: () -> UUID,
    calendar: () -> Calendar,
    date: Date,
    createdByUser: Bool
  ) -> DayActivity {
    let dayActivityId = uuid()
    return DayActivity(
      id: dayActivityId,
      date: date,
      activity: activity,
      name: activity.name,
      iconId: activity.iconId,
      dueDate: activity.dueDaysCount.flatMap { dueDaysCount in
        guard dueDaysCount > .zero else { return nil }
        return calendar().utcCalendar.date(byAdding: .day, value: dueDaysCount, to: date)
      },
      doneDate: nil,
      duration: activity.defaultDuration ?? .zero,
      overview: nil,
      isGeneratedAutomatically: !createdByUser,
      tags: activity.tags,
      labels: [],
      dayActivityTasks: activity.tasks.map {
        DayActivityTask(
          id: uuid(),
          dayActivityId: dayActivityId,
          activityTask: $0,
          name: $0.name,
          doneDate: nil,
          duration: $0.defaultDuration ?? .zero,
          overview: nil,
          reminderDate: calendar().reminderDate(from: $0.defaultReminderDate, dayDate: date),
          position: $0.defaultPosition
        )
      },
      reminderDate: calendar().reminderDate(from: activity.defaultReminderDate, dayDate: date),
      important: activity.important
    )
  }

  public static func copy(
    from dayActivity: DayActivity,
    uuid: () -> UUID,
    date: Date,
    calendar: () -> Calendar
  ) -> DayActivity {
    let dayActivityId = uuid()
    return DayActivity(
      id: dayActivityId,
      date: date,
      activity: dayActivity.activity,
      name: dayActivity.name,
      iconId: dayActivity.iconId,
      dueDate: nil,
      doneDate: nil,
      duration: dayActivity.duration,
      isGeneratedAutomatically: false,
      tags: dayActivity.tags,
      labels: dayActivity.labels,
      dayActivityTasks: dayActivity.dayActivityTasks.map { dayActivityTask in
        DayActivityTask(
          id: uuid(),
          dayActivityId: dayActivityId,
          activityTask: dayActivityTask.activityTask,
          name: dayActivityTask.name,
          doneDate: nil,
          duration: dayActivityTask.duration,
          overview: dayActivityTask.overview,
          reminderDate: calendar().reminderDate(from: dayActivityTask.reminderDate, dayDate: date)
        )
      },
      reminderDate: calendar().reminderDate(from: dayActivity.reminderDate, dayDate: date),
      important: dayActivity.important
    )
  }
}
