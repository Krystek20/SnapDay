import Models
import CoreData

extension Tag: Entity {
  public typealias ManagedObject = TagEntity

  public static var fetchRequest: NSFetchRequest<TagEntity> {
    ManagedObject.fetchRequest()
  }

  public init?(object: TagEntity?, context: NSManagedObjectContext, isShared: (NSManagedObject?) -> Bool) throws {
    guard let object else { return nil }
    try self.init(object, context: context, isShared: isShared)
  }

  public func managedObject(_ context: NSManagedObjectContext) throws -> TagEntity {
    let tagEntity = try TagEntity.object(
      identifier: name,
      fetchRequest: Tag.fetchRequest,
      context: context
    )
    tagEntity.setup(by: self)
    tagEntity.colorIdentifier = rgbColor.id
    return tagEntity
  }
}
