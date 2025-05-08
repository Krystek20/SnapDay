import Foundation
import CoreData.NSManagedObjectContext
import Models

extension SharedDayActivity {
  init(_ entity: SharedDayActivityEntity, context: NSManagedObjectContext) throws {
    guard let identifier = entity.identifier,
          let name = entity.name,
          let iconIdentifier = entity.iconIdentifier,
          let tasks = entity.tasks?.allObjects as? [SharedDayActivityTaskEntity] else {
      let message = """
        let objectID = \(String(describing: entity.objectID)),
        let name = \(String(describing: entity.name)),
        let identifier = \(String(describing: entity.identifier))
        let iconIdentifier = \(String(describing: entity.iconIdentifier))
      """
      throw EntityError.attributeNil(message: message)
    }

    let sharedByEntities = entity.sharedBy?.allObjects as? [SharedByEntity] ?? []
    let sharedBy = try sharedByEntities.compactMap { try SharedBy(object: $0, context: context) }

    self.init(
      id: identifier,
      date: entity.date,
      dateLastUpdated: entity.dateLastUpdated,
      name: name,
      nameLastUpdated: entity.nameLastUpdated,
      iconId: iconIdentifier,
      dueDate: entity.dueDate,
      dueDateLastUpdated: entity.dueDateLastUpdated,
      tasks: try tasks.map {
        try SharedDayActivityTask($0, context: context)
      }.sorted(by: { $0.name < $1.name }),
      sharedBy: sharedBy,
      important: entity.important,
      importantLastUpdated: entity.importantLastUpdated,
      lockTimestamp: entity.lockTimestamp,
      doneDate: entity.doneDate,
      doneDateLastUpdated: entity.doneDateLastUpdated,
      doneByUserId: entity.doneByUserIdentifier
    )
  }
}
