import Models
import CoreData

extension RGBColor: Entity {
  public typealias ManagedObject = RGBColorEntity

  public static var fetchRequest: NSFetchRequest<RGBColorEntity> {
    ManagedObject.fetchRequest()
  }

  public init?(object: RGBColorEntity?) throws {
    guard let object else { return nil }
    self.init(object)
  }

  public func managedObject(_ context: NSManagedObjectContext) throws -> RGBColorEntity {
    let colorEntity = try RGBColorEntity.object(
      identifier: id,
      fetchRequest: RGBColor.fetchRequest,
      context: context
    )
    colorEntity.setup(by: self)
    return colorEntity
  }
}
