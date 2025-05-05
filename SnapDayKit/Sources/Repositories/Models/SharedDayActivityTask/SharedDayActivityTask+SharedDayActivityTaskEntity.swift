import Foundation
import CoreData.NSManagedObjectContext
import Models

extension SharedDayActivityTask {
  init(_ entity: SharedDayActivityTaskEntity, context: NSManagedObjectContext) throws {
    guard let identifier = entity.identifier,
          let name = entity.name,
          let sharedDayActivityId = entity.dayActivity?.identifier else {
      let message = """
        let objectID = \(String(describing: entity.objectID)),
        let identifier = \(String(describing: entity.identifier))
        let name = \(String(describing: entity.name))
        let sharedDayActivityId = \(String(describing: entity.dayActivity?.identifier))
      """
      throw EntityError.attributeNil(message: message)
    }

    let sharedByEntities = entity.sharedBy?.allObjects as? [SharedByEntity] ?? []
    let sharedBy = try sharedByEntities.compactMap { try SharedBy(object: $0, context: context) }

    self.init(
      id: identifier,
      sharedDayActivityId: sharedDayActivityId,
      name: name,
      nameLastUpdated: entity.nameLastUpdated,
      doneDate: entity.doneDate,
      doneDateLastUpdated: entity.doneDateLastUpdated,
      doneByUserId: entity.doneByUserIdentifier,
      sharedBy: sharedBy
    )
  }
}
