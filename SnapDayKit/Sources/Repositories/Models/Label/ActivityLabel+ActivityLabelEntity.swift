import Foundation
import Models

extension ActivityLabel {
  init?(_ entity: ActivityLabelEntity) {
    guard let name = entity.name,
          let color = entity.color else { return nil }
    self.init(
      name: name,
      color: RGBColor(color)
    )
  }
}
