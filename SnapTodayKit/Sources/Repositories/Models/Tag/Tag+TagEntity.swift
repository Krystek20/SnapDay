import Foundation
import Models

extension Tag {
  init?(_ entity: TagEntity) {
    guard let name = entity.name,
          let color = entity.color else { return nil }
    self.init(
      name: name,
      color: RGBColor(color)
    )
  }
}
