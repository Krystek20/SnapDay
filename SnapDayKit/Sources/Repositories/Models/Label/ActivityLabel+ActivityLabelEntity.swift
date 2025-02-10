import Foundation
import Models
import CoreData.NSManagedObjectContext

extension ActivityLabel {
  init(_ entity: ActivityLabelEntity, context: NSManagedObjectContext, isShared: (NSManagedObject?) -> Bool) throws {
    guard let name = entity.name,
          let color = try RGBColor(identifier: entity.colorIdentifier, context: context, isShared: isShared) else {
      throw EntityError.attributeNil()
    }
    self.init(
      name: name,
      color: color
    )
  }
}
