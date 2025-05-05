import Foundation
import Models
import CoreData

extension ActivityTaskEntity {
  func setup(by activityTask: ActivityTask) throws {
    identifier = activityTask.id
    name = activityTask.name
    isDefaultDuration = activityTask.defaultDuration != nil
    defaultDuration = Int32(activityTask.defaultDuration ?? .zero)
    defaultReminderDate = activityTask.defaultReminderDate
    defaultPosition = Int32(activityTask.defaultPosition)
  }
}
