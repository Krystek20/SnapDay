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
    let tagsIdentifiersData = try JSONEncoder().encode(dayActivity.tags.map(\.id))
    tagsIdentifiers = String(data: tagsIdentifiersData, encoding: .utf8)
    let labelsIdentifiersData = try JSONEncoder().encode(dayActivity.labels.map(\.id))
    labelsIdentifiers = String(data: labelsIdentifiersData, encoding: .utf8)
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
