import Models
import CoreData

extension Plan: Entity {
  public typealias ManagedObject = PlanEntity

  public static var fetchRequest: NSFetchRequest<PlanEntity> {
    ManagedObject.fetchRequest()
  }

  public init?(object: PlanEntity?) throws {
    guard let object else { return nil }
    try self.init(object)
  }

  public func managedObject(_ context: NSManagedObjectContext) throws -> PlanEntity {
    let planEntity = try ManagedObject.object(
      identifier: id.uuidString,
      fetchRequest: Plan.fetchRequest,
      context: context
    )
    planEntity.days = Set(
      try days.map { day in
        try day.managedObject(context)
      }
    ) as NSSet
    try planEntity.setup(by: self)
    return planEntity
  }
}
