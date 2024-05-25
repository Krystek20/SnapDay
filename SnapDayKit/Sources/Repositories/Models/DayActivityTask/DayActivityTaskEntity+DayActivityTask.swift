import Foundation
import Models
import CoreData

extension DayActivityTaskEntity {
  func setup(by dayActivityTask: DayActivityTask, context: NSManagedObjectContext) throws {
    identifier = dayActivityTask.id
    name = dayActivityTask.name
    icon = try dayActivityTask.icon?.managedObject(context)
    duration = Int32(dayActivityTask.duration)
    doneDate = dayActivityTask.doneDate
    overview = dayActivityTask.overview
    reminderDate = dayActivityTask.reminderDate

    if let task = dayActivityTask.activityTask {
      activityTask = try ActivityTaskEntity.object(
        identifier: task.id.uuidString,
        fetchRequest: ActivityTask.fetchRequest,
        context: context
      )
    }
  }
}
