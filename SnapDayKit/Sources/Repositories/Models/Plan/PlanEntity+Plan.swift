import CoreData
import Models

extension PlanEntity {
  func setup(by plan: Plan, context: NSManagedObjectContext) throws {
    identifier = plan.id
    name = plan.name
    startDate = plan.startDate
    endDate = plan.endDate
    duration = plan.duration.rawValue
    isArchived = plan.isArchived

    let existingEntries = (scheduleEntries?.allObjects as? [PlanScheduleEntryEntity] ?? [])
    let existingEntriesByID = Dictionary(
      existingEntries.compactMap { entity in
        entity.identifier.map { ($0, entity) }
      },
      uniquingKeysWith: { first, _ in first }
    )
    let currentIDs = Set(plan.schedule.map(\.id))

    existingEntries
      .filter { entity in
        guard let identifier = entity.identifier else { return true }
        return !currentIDs.contains(identifier)
      }
      .forEach(context.delete)

    scheduleEntries = NSSet(
      array: plan.schedule.map { entry in
        let entity = existingEntriesByID[entry.id] ?? PlanScheduleEntryEntity(context: context)
        entity.identifier = entry.id
        entity.weekday = Int16(entry.weekday.rawValue)
        entity.activityIdentifier = entry.activityID
        entity.position = Int32(entry.position)
        entity.plan = self
        return entity
      }
    )
  }
}
