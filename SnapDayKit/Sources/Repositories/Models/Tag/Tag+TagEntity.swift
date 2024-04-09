import Foundation
import Models

extension Tag {
  init(_ entity: TagEntity) throws {
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
