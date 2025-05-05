import Foundation
import Models
import CoreData.NSManagedObjectContext

extension Share {
  init(_ entity: ShareEntity, context: NSManagedObjectContext) throws {
    guard let owner = entity.identifier else {
      throw EntityError.attributeNil()
    }

    let sharedEntities = entity.dayActivities?.allObjects as? [SharedDayActivityEntity] ?? []
    let sharedDayActivities = try sharedEntities.map { try SharedDayActivity($0, context: context) }

    self.init(
      owner: owner,
      sharedDayActivities: sharedDayActivities
    )
  }
}
