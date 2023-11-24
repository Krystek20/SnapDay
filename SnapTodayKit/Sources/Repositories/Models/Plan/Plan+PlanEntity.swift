import Foundation
import Models

extension Plan {
  init?(_ entity: PlanEntity) throws {
    guard let identifier = entity.identifier,
          let days = entity.days?.allObjects as? [DayEntity],
          let name = entity.name,
          let startDate = entity.startDate,
          let endDate = entity.endDate,
          let type = entity.type,
          let planType = PlanType(rawValue: type) else { return nil }
    self.init(
      id: identifier,
      days: try days.compactMap(Day.init),
      name: name,
      type: planType,
      dateRange: startDate...endDate
    )
  }
}
