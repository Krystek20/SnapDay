import Foundation
import Models
import Dependencies

public extension DayActivityTask {
  init(
    dayActivityId: UUID,
    uuid: UUIDGenerator,
    sharedDayActivityTask: SharedDayActivityTask
  ) {
    self.init(
      id: uuid(),
      dayActivityId: dayActivityId,
      activityTask: nil,
      name: sharedDayActivityTask.name,
      doneDate: sharedDayActivityTask.doneDate,
      duration: .zero,
      overview: nil,
      reminderDate: nil,
      invitationId: sharedDayActivityTask.id.uuidString
    )
  }
}
