import Foundation
import Models

extension Icon {
  init(_ entity: IconEntity) throws {
    guard let identifier = entity.identifier else {
      throw EntityError.attributeNil()
    }
    self.init(
      id: identifier,
      data: entity.data
    )
  }
}
