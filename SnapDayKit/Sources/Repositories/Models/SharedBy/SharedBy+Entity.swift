import Models
import CoreData

extension SharedBy: Entity {
  public typealias ManagedObject = SharedByEntity

  public static var fetchRequest: NSFetchRequest<SharedByEntity> {
    ManagedObject.fetchRequest()
  }

  public init?(object: SharedByEntity?, context: NSManagedObjectContext) throws {
    guard let object else { return nil }
    try self.init(object)
  }

  public func managedObject(_ context: NSManagedObjectContext) throws -> SharedByEntity {
    let entity = try SharedByEntity.object(
      identifier: userId,
      fetchRequest: SharedBy.fetchRequest,
      context: context
    )
    entity.setup(by: self)
    return entity
  }
}
