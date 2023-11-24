import Foundation
import Dependencies
import Models

struct PlanComposer {

  // MARK: - Dependecies

  @Dependency(\.planRepository) var planRepository
  @Dependency(\.activityRepository.loadActivities) var loadActivities
  @Dependency(\.uuid) private var uuid

  // MARK: - Properties

  private let requiredPlans: [PlanType] = [.quarterly, .monthly, .weekly, .daily]
  private let planDateRangeCreator = PlanDateRangeCreator()
  private let dayUpdater = DayUpdater()

  // MARK: - Public

  func composePlans(date: Date) async throws {
    let plansToCreate = try await prepareNeededPlans(for: date)
    guard !plansToCreate.isEmpty else { return }
    let activities = try await loadActivities()
    for type in plansToCreate {
      try await createAndSavePlan(for: type, activities: activities, date: date)
    }
  }

  private func prepareNeededPlans(for date: Date) async throws -> [PlanType] {
    let currentPlanTypes = try await planRepository.loadPlans(date, nil).map(\.type)
    return requiredPlans.filter { !currentPlanTypes.contains($0) }
  }

  private func createAndSavePlan(for type: PlanType, activities: [Activity], date: Date) async throws {
    guard let plan = try await createPlan(for: type, activities: activities, date: date) else { return }
    try await planRepository.savePlan(plan)
  }

  private func createPlan(for type: PlanType, activities: [Activity], date: Date) async throws -> Plan? {
    guard let dateRange = dateRange(for: type, date: date) else { return nil }
    let days = try await dayUpdater.prepareDays(for: activities, in: dateRange)
    return Plan(
      id: uuid(),
      days: days,
      name: type.rawValue,
      type: type,
      dateRange: dateRange
    )
  }

  private func dateRange(for type: PlanType, date: Date) -> ClosedRange<Date>? {
    switch type {
    case .daily:
      planDateRangeCreator.today(for: date)
    case .weekly:
      planDateRangeCreator.weekRange(for: date)
    case .monthly:
      planDateRangeCreator.mounthRange(for: date)
    case .quarterly:
      planDateRangeCreator.quarterlyRange(for: date)
    case .custom:
      nil
    }
  }
}
