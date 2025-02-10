import Foundation
import Models
import CoreData

extension DayActivityEntity {
  func setup(by dayActivity: DayActivity, context: NSManagedObjectContext) throws {
    identifier = dayActivity.id
    date = dayActivity.date
    duration = Int32(dayActivity.duration)
    overview = dayActivity.overview
    isGeneratedAutomatically = dayActivity.isGeneratedAutomatically
    dueDate = dayActivity.dueDate
    doneDate = dayActivity.doneDate
    templateIdentifier = dayActivity.activity?.id
    name = dayActivity.name
    iconIdentifier = dayActivity.iconId
    tagsIdentifiers = try JSONEncoder().encode(dayActivity.tags.map(\.id)) as NSObject
    labelsIdentifiers = try JSONEncoder().encode(dayActivity.labels.map(\.id)) as NSObject
    dayActivityTasks = Set(
      try dayActivity.dayActivityTasks.map { task in
        try task.managedObject(context)
      }
    ) as NSSet
    reminderDate = dayActivity.reminderDate
    important = dayActivity.important
    position = Int32(dayActivity.position)
  }
}
