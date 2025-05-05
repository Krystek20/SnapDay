import Models
import CoreData

extension ActivityLabel: Entity {
  public typealias ManagedObject = ActivityLabelEntity

  public static var fetchRequest: NSFetchRequest<ActivityLabelEntity> {
    ManagedObject.fetchRequest()
  }

  public init?(object: ActivityLabelEntity?, context: NSManagedObjectContext) throws {
    guard let object else { return nil }
    try self.init(object, context: context)
  }

  public func managedObject(_ context: NSManagedObjectContext) throws -> ActivityLabelEntity {
    let activityLabelEntity = try ActivityLabelEntity.object(
      identifier: name,
      fetchRequest: ActivityLabel.fetchRequest,
      context: context
    )
    activityLabelEntity.setup(by: self)
    return activityLabelEntity
  }
}
