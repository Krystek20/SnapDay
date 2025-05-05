import Foundation
import Models
import CoreData

extension ActivityEntity {
  func setup(by activity: Activity, context: NSManagedObjectContext) throws {
    identifier = activity.id
    name = activity.name
    iconIdentifier = activity.iconId
    frequencyJson = try JSONEncoder().encode(activity.frequency)
    isFrequentEnabled = activity.isFrequentEnabled
    isDefaultDuration = activity.defaultDuration != nil
    defaultDuration = Int32(activity.defaultDuration ?? .zero)
    dueDaysCount = Int32(activity.dueDaysCount ?? .zero)
    startDate = activity.startDate
    let tagsIdentifiersData = try JSONEncoder().encode(activity.tags.map(\.id))
    tagsIdentifiers = String(data: tagsIdentifiersData, encoding: .utf8)
    let labelsIdentifiersData = try JSONEncoder().encode(activity.labels.map(\.id))
    labelsIdentifiers = String(data: labelsIdentifiersData, encoding: .utf8)
    activityTasks = Set(
      try activity.tasks.map { task in
        try task.managedObject(context)
      }
    ) as NSSet
    defaultReminderDate = activity.defaultReminderDate
    important = activity.important
  }
}
