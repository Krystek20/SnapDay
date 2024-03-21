import Models
import CoreData

extension ActivityLabel: Entity {
  public typealias ManagedObject = ActivityLabelEntity

  public static var fetchRequest: NSFetchRequest<ActivityLabelEntity> {
    ManagedObject.fetchRequest()
  }

  public init?(object: ActivityLabelEntity?) throws {
    guard let object else { return nil }
    self.init(object)
  }

  public func managedObject(_ context: NSManagedObjectContext) throws -> ActivityLabelEntity {
    let activityLabelEntity = try ActivityLabelEntity.object(
      identifier: name,
      fetchRequest: ActivityLabel.fetchRequest,
      context: context
    )
    try activityLabelEntity.setup(by: self, context: context)
    return activityLabelEntity
  }
}
