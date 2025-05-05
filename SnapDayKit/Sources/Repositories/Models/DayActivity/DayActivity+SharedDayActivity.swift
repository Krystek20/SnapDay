import Foundation
import Models
import Dependencies

public extension DayActivity {
  init(
    uuid: UUIDGenerator,
    sharedDayActivity: SharedDayActivity
  ) {
    let dayActivityId = uuid()

    let tasks = sharedDayActivity.tasks.map { sharedDayActivityTask in
      DayActivityTask(
        dayActivityId: dayActivityId,
        uuid: uuid,
        sharedDayActivityTask: sharedDayActivityTask
      )
    }

    self.init(
      id: dayActivityId,
      date: sharedDayActivity.date,
      activity: nil,
      name: sharedDayActivity.name,
      iconId: sharedDayActivity.iconId,
      dueDate: sharedDayActivity.dueDate,
      doneDate: sharedDayActivity.doneDate,
      duration: .zero,
      overview: nil,
      isGeneratedAutomatically: false,
      tags: [],
      labels: [],
      dayActivityTasks: tasks,
      reminderDate: nil,
      important: sharedDayActivity.important
    )
  }

  mutating func update(
    by sharedDayActivity: SharedDayActivity,
    userRecordName: String,
    uuid: UUIDGenerator
  ) async throws -> [DayActivityTask] {
    date = sharedDayActivity.date
    name = sharedDayActivity.name
    iconId = sharedDayActivity.iconId
    dueDate = sharedDayActivity.dueDate
    important = sharedDayActivity.important
    doneDate = sharedDayActivity.doneDate

    var tasks = [DayActivityTask]()
    for sharedTask in sharedDayActivity.tasks {
      if let taskId = sharedTask.sharedBy.first(where: { $0.userId == userRecordName })?.objectId,
         var dayActivityTask = dayActivityTasks.first(where: { $0.id.uuidString == taskId }) {
        dayActivityTask.doneDate = sharedTask.doneDate
        dayActivityTask.name = sharedTask.name
        tasks.append(dayActivityTask)
      } else {
        tasks.append(
          DayActivityTask(
            dayActivityId: id,
            uuid: uuid,
            sharedDayActivityTask: sharedTask
          )
        )
      }
    }

    let tasksToRemove = dayActivityTasks.filter { dayActivityTask in
      !tasks.contains(where: { $0.id == dayActivityTask.id })
    }

    dayActivityTasks = tasks
    return tasksToRemove
  }
}
