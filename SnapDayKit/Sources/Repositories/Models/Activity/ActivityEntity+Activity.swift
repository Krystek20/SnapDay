import Foundation
import Models
import CoreData

extension ActivityEntity {
  func setup(by activity: Activity, context: NSManagedObjectContext) throws {
    identifier = activity.id
    name = activity.name
    icon = try activity.icon?.managedObject(context)
    if let frequency = activity.frequency {
      frequencyJson = try JSONEncoder().encode(frequency)
    } else {
      frequencyJson = nil
    }
    isDefaultDuration = activity.defaultDuration != nil
    defaultDuration = Int32(activity.defaultDuration ?? .zero)
    isVisible = activity.isVisible
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
  }
}
