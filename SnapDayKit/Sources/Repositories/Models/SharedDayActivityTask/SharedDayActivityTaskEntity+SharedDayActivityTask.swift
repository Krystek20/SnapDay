import Foundation
import Models
import CoreData

extension SharedDayActivityTaskEntity {
  func setup(by sharedDayActivityTask: SharedDayActivityTask, context: NSManagedObjectContext) throws {
    identifier = sharedDayActivityTask.id
    name = sharedDayActivityTask.name
    doneDate = sharedDayActivityTask.doneDate
    doneByUserIdentifier = sharedDayActivityTask.doneByUserId

    for sharedByEntity in sharedDayActivityTask.sharedBy {
      let all = sharedBy?.allObjects as? [SharedByEntity] ?? []
      switch sharedByEntity.action {
      case .none:
        continue
      case .update:
        if let toUpdate = all.first(where: { $0.identifier == sharedByEntity.identifier }) {
          toUpdate.setup(by: sharedByEntity)
        } else {
          let managedObject = try sharedByEntity.managedObject(context)
          addToSharedBy(managedObject)
        }
      case .remove:
        if let toRemove = all.first(where: { $0.identifier == sharedByEntity.identifier }) {
          removeFromSharedBy(toRemove)
          context.delete(toRemove)
        }
      }
    }
  }
}
