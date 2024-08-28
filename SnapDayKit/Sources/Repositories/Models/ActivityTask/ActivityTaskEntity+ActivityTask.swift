import Foundation
import Models
import CoreData

extension ActivityTaskEntity {
  func setup(by activityTask: ActivityTask, context: NSManagedObjectContext) throws {
    identifier = activityTask.id
    name = activityTask.name
    icon = try activityTask.icon?.managedObject(context)
    isDefaultDuration = activityTask.defaultDuration != nil
    defaultDuration = Int32(activityTask.defaultDuration ?? .zero)
    defaultReminderDate = activityTask.defaultReminderDate
    defaultPosition = Int32(activityTask.defaultPosition)
  }
}
