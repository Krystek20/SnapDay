import Foundation
import Models
import CoreData

extension ActivityEntity {
  func setup(by activity: Activity, context: NSManagedObjectContext) throws {
    identifier = activity.id
    name = activity.name
    icon = try activity.icon?.managedObject(context)
    frequencyJson = try JSONEncoder().encode(activity.frequency)
    isFrequentEnabled = activity.isFrequentEnabled
    isDefaultDuration = activity.defaultDuration != nil
    defaultDuration = Int32(activity.defaultDuration ?? .zero)
    dueDaysCount = Int32(activity.dueDaysCount ?? .zero)
    startDate = activity.startDate
    tags = Set(
      try activity.tags.map { tag in
        try tag.managedObject(context)
      }
    ) as NSSet
    labels = Set(
      try activity.labels.map { label in
        try label.managedObject(context)
      }
    ) as NSSet
    activityTasks = Set(
      try activity.tasks.map { task in
        try task.managedObject(context)
      }
    ) as NSSet
    defaultReminderDate = activity.defaultReminderDate
    important = activity.important
  }
}
