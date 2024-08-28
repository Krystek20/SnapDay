import Foundation
import Models

extension DayActivityTask {
  init(_ entity: DayActivityTaskEntity) throws {
    guard let identifier = entity.identifier,
          let dayActivityId = entity.dayActivity?.identifier else {
      throw EntityError.attributeNil()
    }
    let activityTask = try entity.activityTask.map(ActivityTask.init)
    let name = entity.name ?? activityTask?.name ?? ""
    self.init(
      id: identifier,
      dayActivityId: dayActivityId,
      activityTask: activityTask,
      name: name,
      icon: try entity.icon.map(Icon.init),
      doneDate: entity.doneDate,
      duration: Int(entity.duration),
      overview: entity.overview,
      reminderDate: entity.reminderDate,
      position: Int(entity.position)
    )
  }
}
