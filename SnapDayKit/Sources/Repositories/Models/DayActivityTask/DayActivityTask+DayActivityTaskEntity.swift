import Foundation
import CoreData.NSManagedObjectContext
import Models

extension DayActivityTask {
  init(_ entity: DayActivityTaskEntity, context: NSManagedObjectContext, isShared: (NSManagedObject?) -> Bool) throws {
    guard let identifier = entity.identifier,
          let dayActivityId = entity.dayActivity?.identifier else {
      throw EntityError.attributeNil()
    }

    let activityTask = try? ActivityTask(identifier: entity.templateIdentifier?.uuidString, context: context, isShared: isShared)
    let name = entity.name ?? activityTask?.name ?? ""

    self.init(
      id: identifier,
      dayActivityId: dayActivityId,
      activityTask: activityTask,
      name: name,
      iconId: entity.iconIdentifier,
      doneDate: entity.doneDate,
      duration: Int(entity.duration),
      overview: entity.overview,
      reminderDate: entity.reminderDate,
      position: Int(entity.position),
      isShared: isShared(entity)
    )
  }
}
