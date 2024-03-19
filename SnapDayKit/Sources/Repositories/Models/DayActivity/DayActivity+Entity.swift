import Models
import CoreData

extension DayActivity: Entity {
  public typealias ManagedObject = DayActivityEntity

  public static var fetchRequest: NSFetchRequest<DayActivityEntity> {
    ManagedObject.fetchRequest()
  }
  
  public init?(object: DayActivityEntity?) throws {
    guard let object else { return nil }
    try self.init(object)
  }
  
  public func managedObject(_ context: NSManagedObjectContext) throws -> DayActivityEntity {
    let dayActivityEntity = try DayActivityEntity.object(
      identifier: id.uuidString,
      fetchRequest: DayActivity.fetchRequest,
      context: context
    )
    dayActivityEntity.setup(by: self)
    dayActivityEntity.activity = try ActivityEntity.object(
      identifier: activity.id.uuidString,
      fetchRequest: Activity.fetchRequest,
      context: context
    )
    dayActivityEntity.tags = Set(
      try tags.map { tag in
        try tag.managedObject(context)
      }
    ) as NSSet
    return dayActivityEntity
  }
}
