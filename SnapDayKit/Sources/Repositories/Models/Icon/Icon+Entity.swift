import Models
import CoreData

extension Icon: Entity {
  public typealias ManagedObject = IconEntity

  public static var fetchRequest: NSFetchRequest<IconEntity> {
    ManagedObject.fetchRequest()
  }

  public init?(object: IconEntity?) throws {
    guard let object else { return nil }
    try self.init(object)
  }

  public func managedObject(_ context: NSManagedObjectContext) throws -> IconEntity {
    let iconEntity = try IconEntity.object(
      identifier: id.uuidString,
      fetchRequest: Icon.fetchRequest,
      context: context
    )
    try iconEntity.setup(by: self)
    return iconEntity
  }
}
