import Models

extension PlanOccurrence {
  init(_ entity: PlanOccurrenceEntity) throws {
    guard let planIdentifier = entity.planIdentifier,
          let activityIdentifier = entity.activityIdentifier,
          let date = entity.date else {
      throw EntityError.attributeNil()
    }

    self.init(
      planID: planIdentifier,
      activityID: activityIdentifier,
      date: date,
      dayActivityID: entity.dayActivityIdentifier
    )
  }
}
