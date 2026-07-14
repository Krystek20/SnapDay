import CoreData
import Models

extension PlanOccurrenceEntity {
  func setup(by occurrence: PlanOccurrence, context: NSManagedObjectContext) throws {
    let request = Plan.fetchRequest
    request.predicate = NSCompoundPredicate(
      andPredicateWithSubpredicates: [
        NSPredicate(format: "identifier == %@", occurrence.planID as CVarArg),
        .deduplicatedDateNilPredicate
      ]
    )
    request.fetchLimit = 1

    guard let plan = try context.fetch(request).first else {
      throw EntityError.attributeNil(message: "Plan must be saved before its occurrences")
    }

    identifier = occurrence.persistenceIdentifier
    planIdentifier = occurrence.planID
    activityIdentifier = occurrence.activityID
    date = occurrence.date
    dayActivityIdentifier = occurrence.dayActivityID
    self.plan = plan
  }
}
