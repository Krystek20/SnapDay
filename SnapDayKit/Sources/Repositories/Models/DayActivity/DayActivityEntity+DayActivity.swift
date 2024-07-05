import Foundation
import Models
import CoreData

extension DayActivityEntity {
  func setup(by dayActivity: DayActivity, context: NSManagedObjectContext) throws {
    identifier = dayActivity.id
    duration = Int32(dayActivity.duration)
    overview = dayActivity.overview
    isGeneratedAutomatically = dayActivity.isGeneratedAutomatically
    dueDate = dayActivity.dueDate
    doneDate = dayActivity.doneDate
    if let activityId = dayActivity.activity?.id.uuidString {
      activity = try ActivityEntity.object(
        identifier: activityId,
        fetchRequest: Activity.fetchRequest,
        context: context
      )
    }
    name = dayActivity.name
    icon = try dayActivity.icon?.managedObject(context)
    tags = Set(
      try dayActivity.tags.map { tag in
        try tag.managedObject(context)
      }
    ) as NSSet
    labels = Set(
      try dayActivity.labels.map { label in
        try label.managedObject(context)
      }
    ) as NSSet
    dayActivityTasks = Set(
      try dayActivity.dayActivityTasks.map { task in
        try task.managedObject(context)
      }
    ) as NSSet
    reminderDate = dayActivity.reminderDate
  }
}
