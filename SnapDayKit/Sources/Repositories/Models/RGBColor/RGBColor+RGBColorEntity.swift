import Foundation
import Models

extension RGBColor {
  init(_ entity: RGBColorEntity) {
    self.init(
      red: entity.red,
      green: entity.green,
      blue: entity.blue,
      alpha: entity.alpha
    )
  }
}
