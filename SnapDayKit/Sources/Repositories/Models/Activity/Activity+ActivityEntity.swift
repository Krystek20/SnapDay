import Foundation
import Models

extension Activity {
  init(_ entity: ActivityEntity) throws {
    guard let identifier = entity.identifier,
          let name = entity.name,
          let tags = entity.tags?.allObjects as? [TagEntity],
          let labels = entity.labels?.allObjects as? [ActivityLabelEntity],
          let tasks = entity.activityTasks?.allObjects as? [ActivityTaskEntity] else {
      throw EntityError.attributeNil()
    }
    var frequency: ActivityFrequency?
    if let frequencyJson = entity.frequencyJson {
      frequency = try JSONDecoder().decode(ActivityFrequency.self, from: frequencyJson)
    }
    self.init(
      id: identifier,
      name: name,
      icon: try entity.icon.map(Icon.init),
      tags: try tags.map(Tag.init),
      frequency: frequency ?? .daily,
      isFrequentEnabled: entity.isFrequentEnabled,
      defaultDuration: entity.isDefaultDuration ? Int(entity.defaultDuration) : nil,
      dueDaysCount: Int(entity.dueDaysCount),
      startDate: entity.startDate,
      labels: try labels.map(ActivityLabel.init),
      tasks: try tasks.map(ActivityTask.init),
      defaultReminderDate: entity.defaultReminderDate
    )
  }
}
