import Foundation
import Models

public extension Activity {
  init(
    uuid: () -> UUID,
    startDate: Date,
    dayActivity: DayActivity
  ) {
    let id = uuid()
    self.init(
      id: id,
      name: dayActivity.name,
      icon: dayActivity.icon,
      tags: dayActivity.tags,
      defaultDuration: dayActivity.duration,
      startDate: startDate,
      labels: dayActivity.labels,
      tasks: dayActivity.dayActivityTasks.compactMap { dayActivityTask in
        ActivityTask(
          uuid: uuid,
          activityId: id,
          dayActivity: dayActivityTask
        )
      },
      defaultReminderDate: dayActivity.reminderDate
    )
  }
}

public extension ActivityTask {
  init(
    uuid: () -> UUID,
    activityId: UUID,
    dayActivity: DayActivityTask
  ) {
    self.init(
      id: uuid(),
      activityId: activityId,
      name: dayActivity.name,
      icon: dayActivity.icon,
      defaultDuration: dayActivity.duration,
      defaultReminderDate: dayActivity.reminderDate
    )
  }
}
