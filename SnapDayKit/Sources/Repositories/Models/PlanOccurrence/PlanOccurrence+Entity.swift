import CoreData
import Models

extension PlanOccurrence: Entity {
  public typealias ManagedObject = PlanOccurrenceEntity

  public static var fetchRequest: NSFetchRequest<PlanOccurrenceEntity> {
    PlanOccurrenceEntity.fetchRequest()
  }

  public init?(object: PlanOccurrenceEntity?, context: NSManagedObjectContext) throws {
    guard let object else { return nil }
    try self.init(object)
  }

  public func managedObject(_ context: NSManagedObjectContext) throws -> PlanOccurrenceEntity {
    let entity = try PlanOccurrenceEntity.object(
      identifier: persistenceIdentifier,
      fetchRequest: Self.fetchRequest,
      context: context
    )
    try entity.setup(by: self, context: context)
    return entity
  }

  var persistenceIdentifier: String {
    [
      planID.uuidString,
      activityID.uuidString,
      String(date.timeIntervalSinceReferenceDate)
    ].joined(separator: "|")
  }
}
