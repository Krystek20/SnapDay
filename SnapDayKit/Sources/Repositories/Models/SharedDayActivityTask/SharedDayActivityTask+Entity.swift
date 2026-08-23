import Models
import CoreData

extension SharedDayActivityTask: Entity {
  public typealias ManagedObject = SharedDayActivityTaskEntity

  public static var fetchRequest: NSFetchRequest<SharedDayActivityTaskEntity> {
    ManagedObject.fetchRequest()
  }

  public init?(object: SharedDayActivityTaskEntity?, context: NSManagedObjectContext) throws {
    guard let object else { return nil }
    try self.init(object, context: context)
  }

  public func managedObject(_ context: NSManagedObjectContext) throws -> SharedDayActivityTaskEntity {
    let sharedDayActivityTaskEntity = try SharedDayActivityTaskEntity.object(
      identifier: id as CVarArg,
      fetchRequest: SharedDayActivityTask.fetchRequest,
      context: context
    )
    try sharedDayActivityTaskEntity.setup(by: self, context: context)
    return sharedDayActivityTaskEntity
  }
}
