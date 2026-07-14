import Models
import CoreData

extension Activity: Entity {
  public typealias ManagedObject = ActivityEntity

  public static var fetchRequest: NSFetchRequest<ActivityEntity> {
    ActivityEntity.fetchRequest()
  }

  public init?(object: ActivityEntity?, context: NSManagedObjectContext) throws {
    guard let object else { return nil }
    try self.init(object, context: context)
  }

  public func managedObject(_ context: NSManagedObjectContext) throws -> ActivityEntity {
    let activityEntity = try ActivityEntity.object(
      identifier: id as CVarArg,
      fetchRequest: Activity.fetchRequest,
      context: context
    )
    try activityEntity.setup(by: self, context: context)
    return activityEntity
  }
}
