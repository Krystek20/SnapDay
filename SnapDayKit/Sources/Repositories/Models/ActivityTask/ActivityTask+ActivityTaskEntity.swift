import Foundation
import Models

extension ActivityTask {
  init(_ entity: ActivityTaskEntity) throws {
    guard let identifier = entity.identifier,
          let activityId = entity.activity?.identifier,
          let name = entity.name else {
      throw EntityError.attributeNil()
    }
    self.init(
      id: identifier,
      activityId: activityId,
      name: name,
      icon: try entity.icon.map(Icon.init),
      defaultDuration: entity.isDefaultDuration ? Int(entity.defaultDuration) : nil,
      defaultReminderDate: entity.defaultReminderDate
    )
  }
}
