import Models
import CoreData

extension ActivityTask: Entity {
  public typealias ManagedObject = ActivityTaskEntity

  public static var fetchRequest: NSFetchRequest<ActivityTaskEntity> {
    ActivityTaskEntity.fetchRequest()
  }

  public init?(object: ActivityTaskEntity?) throws {
    guard let object else { return nil }
    try self.init(object)
  }

  public func managedObject(_ context: NSManagedObjectContext) throws -> ActivityTaskEntity {
    let activityTaskEntity = try ActivityTaskEntity.object(
      identifier: id.uuidString,
      fetchRequest: ActivityTask.fetchRequest,
      context: context
    )
    try activityTaskEntity.setup(by: self, context: context)
    return activityTaskEntity
  }
}
