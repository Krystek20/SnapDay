import Models
import CoreData

extension DayActivity: Entity {
  public typealias ManagedObject = DayActivityEntity

  public static var fetchRequest: NSFetchRequest<DayActivityEntity> {
    ManagedObject.fetchRequest()
  }

  public init?(object: DayActivityEntity?, context: NSManagedObjectContext) throws {
    guard let object else { return nil }
    try self.init(object, context: context)
  }

  public func managedObject(_ context: NSManagedObjectContext) throws -> DayActivityEntity {
    let dayActivityEntity = try DayActivityEntity.object(
      identifier: id as CVarArg,
      fetchRequest: DayActivity.fetchRequest,
      context: context
    )
    try dayActivityEntity.setup(by: self, context: context)
    return dayActivityEntity
  }
}
