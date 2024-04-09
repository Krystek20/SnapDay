import Foundation
import Models

extension ActivityTask {
  init(_ entity: ActivityTaskEntity) throws {
    guard let identifier = entity.identifier,
          let name = entity.name else {
      throw EntityError.attributeNil()
    }
    self.init(
      id: identifier,
      name: name,
      icon: try entity.icon.map(Icon.init),
      defaultDuration: entity.isDefaultDuration ? Int(entity.defaultDuration) : nil
    )
  }
}
