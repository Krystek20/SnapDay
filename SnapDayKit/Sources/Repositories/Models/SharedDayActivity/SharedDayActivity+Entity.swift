import Models
import CoreData

extension SharedDayActivity: Entity {
  public typealias ManagedObject = SharedDayActivityEntity

  public static var fetchRequest: NSFetchRequest<SharedDayActivityEntity> {
    ManagedObject.fetchRequest()
  }

  public init?(object: SharedDayActivityEntity?, context: NSManagedObjectContext) throws {
    guard let object else { return nil }
    try self.init(object, context: context)
  }

  public func managedObject(_ context: NSManagedObjectContext) throws -> SharedDayActivityEntity {
    let sharedDayActivityEntity = try SharedDayActivityEntity.object(
      identifier: id.uuidString,
      fetchRequest: SharedDayActivity.fetchRequest,
      context: context
    )
    try sharedDayActivityEntity.setup(by: self, context: context)
    return sharedDayActivityEntity
  }
}
