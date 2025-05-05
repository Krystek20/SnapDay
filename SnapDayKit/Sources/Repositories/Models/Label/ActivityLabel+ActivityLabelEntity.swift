import Foundation
import Models
import CoreData.NSManagedObjectContext

extension ActivityLabel {
  init(_ entity: ActivityLabelEntity, context: NSManagedObjectContext) throws {
    guard let name = entity.name,
          let color = try RGBColor(identifier: entity.colorIdentifier, context: context) else {
      throw EntityError.attributeNil()
    }
    self.init(
      name: name,
      color: color
    )
  }
}
