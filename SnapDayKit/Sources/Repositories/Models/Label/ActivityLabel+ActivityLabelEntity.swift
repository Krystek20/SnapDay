import Foundation
import Models

extension ActivityLabel {
  init(_ entity: ActivityLabelEntity) throws {
    guard let name = entity.name,
          let color = entity.color else {
      throw EntityError.attributeNil()
    }
    self.init(
      name: name,
      color: RGBColor(color)
    )
  }
}
