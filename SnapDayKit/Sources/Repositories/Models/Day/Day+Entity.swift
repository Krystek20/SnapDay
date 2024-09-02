import Models
import CoreData

extension Day: Entity {
  public typealias ManagedObject = DayEntity

  public static var fetchRequest: NSFetchRequest<DayEntity> {
    ManagedObject.fetchRequest()
  }

  public init?(object: DayEntity?) throws {
    guard let object else { return nil }
    try self.init(object)
  }

  public func managedObject(_ context: NSManagedObjectContext) throws -> DayEntity {
    let dayEntity = try DayEntity.object(
      identifier: id.uuidString,
      fetchRequest: Day.fetchRequest,
      context: context
    )
    dayEntity.setup(by: self)
    dayEntity.activities = Set(
      try activities.map { activity in
        try activity.managedObject(context)
      }
    ) as NSSet
    return dayEntity
  }
}
