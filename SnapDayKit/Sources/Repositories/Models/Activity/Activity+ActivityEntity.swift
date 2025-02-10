import Foundation
import CoreData.NSManagedObjectContext
import Models

extension Activity {
  init(_ entity: ActivityEntity, context: NSManagedObjectContext, isShared: (NSManagedObject?) -> Bool) throws {
    guard let identifier = entity.identifier,
          let name = entity.name,
          let tasks = entity.activityTasks?.allObjects as? [ActivityTaskEntity] else {
      throw EntityError.attributeNil()
    }
    var frequency: ActivityFrequency?
    if let frequencyJson = entity.frequencyJson {
      frequency = try JSONDecoder().decode(ActivityFrequency.self, from: frequencyJson)
    }

    let tags: [Tag] = try entity.mapArray(for: "tagsIdentifiers", context: context, isShared: isShared)
    let labels: [ActivityLabel] = try entity.mapArray(for: "labelsIdentifiers", context: context, isShared: isShared)

    self.init(
      id: identifier,
      name: name,
      iconId: entity.iconIdentifier,
      tags: tags,
      frequency: frequency ?? .daily,
      isFrequentEnabled: entity.isFrequentEnabled,
      defaultDuration: entity.isDefaultDuration ? Int(entity.defaultDuration) : nil,
      dueDaysCount: Int(entity.dueDaysCount),
      startDate: entity.startDate,
      labels: labels,
      tasks: try tasks.map(ActivityTask.init),
      defaultReminderDate: entity.defaultReminderDate,
      important: entity.important
    )
  }
}
