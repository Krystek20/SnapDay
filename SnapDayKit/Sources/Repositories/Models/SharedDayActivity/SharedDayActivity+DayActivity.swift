import Models
import Dependencies
import Foundation

public extension SharedDayActivity {
  init(
    dayActivity: DayActivity,
    shareableIcon: Icon,
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
      iconId: shareableIcon.id,
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
  ) -> [UpdateProperty] {
    var updatedProperties = [UpdateProperty]()

    if date != dayActivity.date {
      updatedProperties.append(
        .date(old: date, new: dayActivity.date)
      )
      date = dayActivity.date
      dateLastUpdated = updateDate
    }
    if name != dayActivity.name {
      updatedProperties.append(
        .name(old: name, new: dayActivity.name)
      )
      name = dayActivity.name
      nameLastUpdated = updateDate
    }
    if dueDate != dayActivity.dueDate {
      updatedProperties.append(
        .dueDate(old: dueDate, new: dayActivity.dueDate)
      )
      dueDate = dayActivity.dueDate
      dueDateLastUpdated = updateDate
    }
    if important != dayActivity.important {
      updatedProperties.append(
        .important(dayActivity.important)
      )
      important = dayActivity.important
      importantLastUpdated = updateDate
    }
    if doneDate != dayActivity.doneDate {
      updatedProperties.append(
        dayActivity.doneDate == nil
        ? .undone(dayActivity.name)
        : .done(dayActivity.name)
      )
      doneDate = dayActivity.doneDate
      doneByUserId = userRecordName
      doneDateLastUpdated = updateDate
    }

    var sharedTasks = dayActivity.dayActivityTasks.reduce(into: [SharedDayActivityTask](), { result, task in
      if var sharedTask = tasks.first(where: { $0.sharedBy.isShared(objectId: task.id.uuidString) }) {
        let updatedProperty = sharedTask.update(by: task, userRecordName: userRecordName, updateDate: updateDate)
        result.append(sharedTask)
        updatedProperties.append(contentsOf: updatedProperty)
      } else {
        let sharedTask = SharedDayActivityTask(
          dayActivityTask: task,
          sharedDayActivityId: id,
          uuid: uuid,
          userRecordName: userRecordName,
          date: updateDate
        )
        result.append(sharedTask)
        updatedProperties.append(
          .taskAdded(task.name)
        )
      }
    })

    let tasksToRemove: [SharedDayActivityTask] = tasks.compactMap { sharedTask in
      guard !sharedTasks.contains(where: { $0.id == sharedTask.id }) else { return nil }
      var task = sharedTask
      task.removed = true
      updatedProperties.append(
        .taskRemoved(task.name)
      )
      return task
    }
    sharedTasks.append(contentsOf: tasksToRemove)

    tasks = sharedTasks

    return updatedProperties
  }
}
