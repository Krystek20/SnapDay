import Models
import CoreData

extension Share: Entity {
  public typealias ManagedObject = ShareEntity

  public static var fetchRequest: NSFetchRequest<ShareEntity> {
    ManagedObject.fetchRequest()
  }

  public init?(object: ShareEntity?, context: NSManagedObjectContext) throws {
    guard let object else { return nil }
    try self.init(object, context: context)
  }

  public func managedObject(_ context: NSManagedObjectContext) throws -> ShareEntity {
    let shareEntity = try ShareEntity.object(
      identifier: owner,
      fetchRequest: Share.fetchRequest,
      context: context
    )
    try shareEntity.setup(by: self, context: context)
    return shareEntity
  }
}
