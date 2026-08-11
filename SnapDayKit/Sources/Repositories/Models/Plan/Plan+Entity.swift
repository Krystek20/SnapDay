import CoreData
import Models

extension Plan: Entity {
  public typealias ManagedObject = PlanEntity

  public static var fetchRequest: NSFetchRequest<PlanEntity> {
    PlanEntity.fetchRequest()
  }

  public init?(object: PlanEntity?, context: NSManagedObjectContext) throws {
    guard let object else { return nil }
    try self.init(object, context: context)
  }

  public func managedObject(_ context: NSManagedObjectContext) throws -> PlanEntity {
    let entity = try PlanEntity.object(
      identifier: id as CVarArg,
      fetchRequest: Self.fetchRequest,
      context: context
    )
    try entity.setup(by: self, context: context)
    return entity
  }
}
