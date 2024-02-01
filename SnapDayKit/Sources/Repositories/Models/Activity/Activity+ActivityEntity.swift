import Foundation
import Models

extension Activity {
  init?(_ entity: ActivityEntity) throws {
    guard let identifier = entity.identifier,
          let name = entity.name,
          let tags = entity.tags?.allObjects as? [TagEntity] else { return nil }
    var frequency: ActivityFrequency? = nil
    if let frequencyJson = entity.frequencyJson {
      frequency = try JSONDecoder().decode(ActivityFrequency.self, from: frequencyJson)
    }
    self.init(
      id: identifier,
      name: name,
      image: entity.image,
      tags: tags.compactMap(Tag.init),
      frequency: frequency,
      isDefaultDuration: entity.isDefaultDuration,
      defaultDuration: entity.isDefaultDuration ? Int(entity.defaultDuration) : nil,
      isVisible: entity.isVisible
    )
  }
}
