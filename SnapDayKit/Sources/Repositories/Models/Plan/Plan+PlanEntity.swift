import CoreData
import Models

extension Plan {
  init(_ entity: PlanEntity, context: NSManagedObjectContext) throws {
    guard let identifier = entity.identifier,
          let name = entity.name,
          let startDate = entity.startDate,
          let endDate = entity.endDate,
          let durationValue = entity.duration,
          let duration = PlanDuration(rawValue: durationValue) else {
      throw EntityError.attributeNil()
    }

    let scheduleEntities = entity.scheduleEntries?.allObjects as? [PlanScheduleEntryEntity] ?? []
    let schedule = try scheduleEntities
      .map(PlanScheduleEntry.init)
      .sorted {
        ($0.weekday.rawValue, $0.position) < ($1.weekday.rawValue, $1.position)
      }

    self.init(
      id: identifier,
      name: name,
      startDate: startDate,
      endDate: endDate,
      duration: duration,
      isArchived: entity.isArchived,
      schedule: schedule
    )
  }
}

private extension PlanScheduleEntry {
  init(_ entity: PlanScheduleEntryEntity) throws {
    guard let identifier = entity.identifier,
          let activityIdentifier = entity.activityIdentifier,
          let weekday = PlanWeekday(rawValue: Int(entity.weekday)) else {
      throw EntityError.attributeNil()
    }

    self.init(
      id: identifier,
      weekday: weekday,
      activityID: activityIdentifier,
      position: Int(entity.position)
    )
  }
}
