import Foundation
import Models

extension SharedBy {
  init(_ entity: SharedByEntity) throws {
    guard let identifier = entity.identifier,
          let userId = entity.userIdentifier,
          let objectId = entity.objectIdentifier else {
      throw EntityError.attributeNil()
    }
    self.init(
      identifier: identifier,
      userId: userId,
      objectId: objectId
    )
  }
}
