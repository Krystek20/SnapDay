import Foundation
import Models
import CoreData

extension DayActivityTaskEntity {
  func setup(by dayActivityTask: DayActivityTask, context: NSManagedObjectContext) throws {
    identifier = dayActivityTask.id
    name = dayActivityTask.name
    duration = Int32(dayActivityTask.duration)
    doneDate = dayActivityTask.doneDate
    overview = dayActivityTask.overview
    reminderDate = dayActivityTask.reminderDate
    position = Int32(dayActivityTask.position)
    templateIdentifier = dayActivityTask.activityTask?.id
  }
}
