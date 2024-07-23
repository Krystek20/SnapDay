import Foundation
import Models

extension DayActivity {
  public static func create(
    from activity: Activity,
    uuid: () -> UUID,
    calendar: () -> Calendar,
    dayId: UUID,
    dayDate: Date,
    createdByUser: Bool
  ) -> DayActivity {
    let dayActivityId = uuid()
    return DayActivity(
      id: dayActivityId,
      dayId: dayId,
      activity: activity,
      name: activity.name,
      icon: activity.icon,
      dueDate: activity.dueDaysCount.flatMap { date in
        calendar().date(byAdding: .day, value: date, to: dayDate)
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
          icon: $0.icon,
          doneDate: nil,
          duration: $0.defaultDuration ?? .zero,
          overview: nil,
          reminderDate: calendar().reminderDate(from: $0.defaultReminderDate, dayDate: dayDate)
        )
      },
      reminderDate: calendar().reminderDate(from: activity.defaultReminderDate, dayDate: dayDate)
    )
  }

  public static func copy(
    from dayActivity: DayActivity,
    uuid: () -> UUID,
    dayId: UUID,
    dayDate: Date,
    calendar: () -> Calendar
  ) -> DayActivity {
    let dayActivityId = uuid()
    return DayActivity(
      id: dayActivityId,
      dayId: dayId,
      activity: dayActivity.activity,
      name: dayActivity.name,
      icon: dayActivity.icon,
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
          icon: dayActivityTask.icon,
          doneDate: nil,
          duration: dayActivityTask.duration,
          overview: dayActivityTask.overview,
          reminderDate: calendar().reminderDate(from: dayActivityTask.reminderDate, dayDate: dayDate)
        )
      },
      reminderDate: calendar().reminderDate(from: dayActivity.reminderDate, dayDate: dayDate)
    )
  }
}
