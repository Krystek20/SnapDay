import Foundation
import Models
import CoreData

extension SharedDayActivityEntity {
  func setup(by sharedDayActivity: SharedDayActivity, context: NSManagedObjectContext) throws {
    identifier = sharedDayActivity.id
    date = sharedDayActivity.date
    dateLastUpdated = sharedDayActivity.dateLastUpdated
    name = sharedDayActivity.name
    nameLastUpdated = sharedDayActivity.nameLastUpdated
    dueDate = sharedDayActivity.dueDate
    dueDateLastUpdated = sharedDayActivity.dueDateLastUpdated
    iconIdentifier = sharedDayActivity.iconId
    important = sharedDayActivity.important
    importantLastUpdated = sharedDayActivity.importantLastUpdated
    lockTimestamp = sharedDayActivity.lockTimestamp
    doneDate = sharedDayActivity.doneDate
    doneDateLastUpdated = sharedDayActivity.doneDateLastUpdated
    doneByUserIdentifier = sharedDayActivity.doneByUserId

    var updatedTasks: [SharedDayActivityTaskEntity] = []
    for task in sharedDayActivity.tasks {
      let taskEntity = try task.managedObject(context)
      if task.removed {
        context.delete(taskEntity)
      } else {
        updatedTasks.append(taskEntity)
      }
    }

    tasks = Set(updatedTasks) as NSSet

    for sharedByEntity in sharedDayActivity.sharedBy {
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
