import Foundation
import Models

extension PlanEntity {
  func setup(by plan: Plan) throws {
    identifier = plan.id
    name = plan.name
    startDate = plan.dateRange.lowerBound
    endDate = plan.dateRange.upperBound
    type = plan.type.rawValue
  }
}
