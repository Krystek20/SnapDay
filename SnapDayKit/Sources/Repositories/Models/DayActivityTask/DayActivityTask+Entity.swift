import Models
import CoreData

extension DayActivityTask: Entity {
  public typealias ManagedObject = DayActivityTaskEntity

  public static var fetchRequest: NSFetchRequest<DayActivityTaskEntity> {
    ManagedObject.fetchRequest()
  }

  public init?(object: DayActivityTaskEntity?, context: NSManagedObjectContext, isShared: (NSManagedObject?) -> Bool) throws {
    guard let object else { return nil }
    try self.init(object, context: context, isShared: isShared)
  }

  public func managedObject(_ context: NSManagedObjectContext) throws -> DayActivityTaskEntity {
    let dayActivityTaskEntity = try DayActivityTaskEntity.object(
      identifier: id.uuidString,
      fetchRequest: DayActivityTask.fetchRequest,
      context: context
    )
    try dayActivityTaskEntity.setup(by: self, context: context)
    return dayActivityTaskEntity
  }
}
