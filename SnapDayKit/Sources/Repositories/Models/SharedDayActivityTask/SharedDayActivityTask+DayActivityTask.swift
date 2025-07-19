import Models
import Dependencies
import Foundation

extension SharedDayActivityTask {
  init(
    dayActivityTask: DayActivityTask,
    sharedDayActivityId: UUID,
    uuid: UUIDGenerator,
    userRecordName: String,
    date: Date
  ) {
    let identifier = uuid()
    self.init(
      id: identifier,
      sharedDayActivityId: sharedDayActivityId,
      name: dayActivityTask.name,
      nameLastUpdated: date,
      doneDate: dayActivityTask.doneDate,
      doneDateLastUpdated: date,
      doneByUserId: dayActivityTask.doneDate != nil ? userRecordName : nil,
      sharedBy: [
        SharedBy(
          identifier: identifier.uuidString + userRecordName,
          userId: userRecordName,
          objectId: dayActivityTask.id.uuidString,
          action: .update
        )
      ]
    )
  }

  public mutating func update(
    by dayActivityTask: DayActivityTask,
    userRecordName: String,
    updateDate: Date
  ) -> [UpdateProperty] {
    var updatedProperties = [UpdateProperty]()

    if name != dayActivityTask.name {
      updatedProperties.append(
        .taskNameChanged(old: name, new: dayActivityTask.name)
      )
      name = dayActivityTask.name
      nameLastUpdated = updateDate
    }
    if doneDate != dayActivityTask.doneDate {
      updatedProperties.append(
        dayActivityTask.doneDate == nil
        ? .undone(dayActivityTask.name)
        : .done(dayActivityTask.name)
      )
      doneDate = dayActivityTask.doneDate
      doneByUserId = userRecordName
      doneDateLastUpdated = updateDate
    }

    return updatedProperties
  }
}
