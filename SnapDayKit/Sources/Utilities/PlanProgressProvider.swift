import Dependencies
import Foundation
import Models
import Repositories

public struct PlanProgressSnapshot: Equatable {
  public let plan: Plan
  public let occurrences: [PlanOccurrence]
  public let dayActivities: [DayActivity]

  public init(
    plan: Plan,
    occurrences: [PlanOccurrence],
    dayActivities: [DayActivity]
  ) {
    self.plan = plan
    self.occurrences = occurrences
    self.dayActivities = dayActivities
  }
}

public struct PlanProgressProvider {
  @Dependency(\.dayActivityRepository) private var dayActivityRepository
  @Dependency(\.planRepository) private var planRepository

  public init() { }

  public func snapshots(for plans: [Plan]) async throws -> [PlanProgressSnapshot] {
    var occurrencesByPlanID: [Plan.ID: [PlanOccurrence]] = [:]

    for plan in plans {
      occurrencesByPlanID[plan.id] = try await planRepository.loadOccurrences(plan.id)
    }

    let dayActivityIDs = Set(
      occurrencesByPlanID.values
        .joined()
        .compactMap(\.dayActivityID)
    )
    let dayActivities: [DayActivity]
    if dayActivityIDs.isEmpty {
      dayActivities = []
    } else {
      dayActivities = try await dayActivityRepository.dayActivities(
        configuration: ActivitiesFetchConfiguration(
          predicates: [NSPredicate(format: "identifier IN %@", Array(dayActivityIDs))]
        )
      )
    }
    let dayActivitiesByID = Dictionary(
      dayActivities.map { ($0.id, $0) },
      uniquingKeysWith: { _, latest in latest }
    )

    return plans.map { plan in
      let occurrences = occurrencesByPlanID[plan.id, default: []]
      var includedDayActivityIDs = Set<DayActivity.ID>()
      return PlanProgressSnapshot(
        plan: plan,
        occurrences: occurrences,
        dayActivities: occurrences.compactMap { occurrence in
          guard let dayActivityID = occurrence.dayActivityID,
                includedDayActivityIDs.insert(dayActivityID).inserted
          else { return nil }
          return dayActivitiesByID[dayActivityID]
        }
      )
    }
  }
}
