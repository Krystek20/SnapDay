import Models
import Dependencies
import Foundation

public extension SharedDayActivity {
  init(
    dayActivity: DayActivity,
    uuid: UUIDGenerator,
    userRecordName: String,
    date: Date
  ) {
    let identifier = uuid()
    self.init(
      id: identifier,
      date: dayActivity.date,
      dateLastUpdated: date,
      name: dayActivity.name,
      nameLastUpdated: date,
      iconId: dayActivity.iconId,
      iconIdLastUpdated: date,
      dueDate: dayActivity.dueDate,
      dueDateLastUpdated: date,
      tasks: dayActivity.dayActivityTasks.map {
        SharedDayActivityTask(
          dayActivityTask: $0,
          sharedDayActivityId: identifier,
          uuid: uuid,
          userRecordName: userRecordName,
          date: date
        )
      },
      sharedBy: [
        SharedBy(
          identifier: identifier.uuidString + userRecordName,
          userId: userRecordName,
          objectId: dayActivity.id.uuidString,
          action: .update
        )
      ],
      important: dayActivity.important,
      importantLastUpdated: date,
      lockTimestamp: nil,
      doneDate: dayActivity.doneDate,
      doneDateLastUpdated: date,
      doneByUserId: dayActivity.doneDate != nil ? userRecordName : nil
    )
  }

  mutating func update(
    by dayActivity: DayActivity,
    userRecordName: String,
    uuid: UUIDGenerator,
    updateDate: Date
  ) {
    if date != dayActivity.date {
      date = dayActivity.date
      dateLastUpdated = updateDate
    }
    if name != dayActivity.name {
      name = dayActivity.name
      nameLastUpdated = updateDate
    }
    if iconId != dayActivity.iconId {
      iconId = dayActivity.iconId
      iconIdLastUpdated = updateDate
    }
    if dueDate != dayActivity.dueDate {
      dueDate = dayActivity.dueDate
      dueDateLastUpdated = updateDate
    }
    if important != dayActivity.important {
      important = dayActivity.important
      importantLastUpdated = updateDate
    }
    if doneDate != dayActivity.doneDate {
      doneDate = dayActivity.doneDate
      doneByUserId = userRecordName
      doneDateLastUpdated = updateDate
    }

    var sharedTasks = dayActivity.dayActivityTasks.reduce(into: [SharedDayActivityTask](), { result, task in
      if var sharedTask = tasks.first(where: { $0.sharedBy.isShared(objectId: task.id.uuidString) }) {
        sharedTask.update(by: task, userRecordName: userRecordName, updateDate: updateDate)
        result.append(sharedTask)
      } else {
        let sharedTask = SharedDayActivityTask(
          dayActivityTask: task,
          sharedDayActivityId: id,
          uuid: uuid,
          userRecordName: userRecordName,
          date: updateDate
        )
        result.append(sharedTask)
      }
    })

    let tasksToRemove: [SharedDayActivityTask] = tasks.compactMap { sharedTask in
      guard !sharedTasks.contains(where: { $0.id == sharedTask.id }) else { return nil }
      var task = sharedTask
      task.removed = true
      return task
    }
    sharedTasks.append(contentsOf: tasksToRemove)

    tasks = sharedTasks
  }
}
