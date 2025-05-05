import Foundation
import CoreData.NSManagedObjectContext
import Models

extension Activity {
  init(_ entity: ActivityEntity, context: NSManagedObjectContext) throws {
    guard let identifier = entity.identifier,
          let name = entity.name,
          let tasks = entity.activityTasks?.allObjects as? [ActivityTaskEntity] else {
      throw EntityError.attributeNil()
    }
    var frequency: ActivityFrequency?
    if let frequencyJson = entity.frequencyJson {
      frequency = try JSONDecoder().decode(ActivityFrequency.self, from: frequencyJson)
    }

    let tags: [Tag] = try entity.mapIdentifierArray(for: "tagsIdentifiers", context: context)
    let labels: [ActivityLabel] = try entity.mapIdentifierArray(for: "labelsIdentifiers", context: context)

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
