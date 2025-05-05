import Models
import CoreData.NSManagedObjectContext

extension ShareEntity {
  func setup(by share: Share, context: NSManagedObjectContext) throws {
    identifier = share.owner
    dayActivities = Set(
      try share.sharedDayActivities.map { sharedDayActivity in
        try sharedDayActivity.managedObject(context)
      }
    ) as NSSet
  }
}
