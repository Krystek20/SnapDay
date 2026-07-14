import Dependencies
import Foundation
import Models

public struct PlanRepository {
  public var loadPlans: @Sendable () async throws -> [Plan]
  public var loadActivePlans: @Sendable (_ date: Date) async throws -> [Plan]
  public var loadHistoricalPlans: @Sendable (_ date: Date) async throws -> [Plan]
  public var plan: @Sendable (_ identifier: Plan.ID) async throws -> Plan?
  public var savePlan: @Sendable (_ plan: Plan) async throws -> Void
  public var archivePlan: @Sendable (_ identifier: Plan.ID) async throws -> Void
  public var loadOccurrences: @Sendable (_ planID: Plan.ID) async throws -> [PlanOccurrence]
  public var saveOccurrences: @Sendable (_ occurrences: [PlanOccurrence]) async throws -> Void
}

extension DependencyValues {
  public var planRepository: PlanRepository {
    get { self[PlanRepository.self] }
    set { self[PlanRepository.self] = newValue }
  }
}

extension PlanRepository: DependencyKey {
  public static var liveValue: PlanRepository {
    PlanRepository(
      loadPlans: {
        try await EntityHandler().fetch(
          Plan.self,
          sorts: { NSSortDescriptor(key: "startDate", ascending: false) }
        )
      },
      loadActivePlans: { date in
        try await EntityHandler().fetch(
          Plan.self,
          predicates: {
            NSPredicate(format: "isArchived == NO")
            NSPredicate(format: "endDate >= %@", Calendar.autoupdatingCurrent.startOfDay(for: date) as NSDate)
          },
          sorts: { NSSortDescriptor(key: "startDate", ascending: true) }
        )
      },
      loadHistoricalPlans: { date in
        try await EntityHandler().fetch(
          Plan.self,
          predicates: {
            NSPredicate(
              format: "isArchived == YES OR endDate < %@",
              Calendar.autoupdatingCurrent.startOfDay(for: date) as NSDate
            )
          },
          sorts: { NSSortDescriptor(key: "endDate", ascending: false) }
        )
      },
      plan: { identifier in
        try await EntityHandler().fetch(Plan.self, identifier: identifier as CVarArg)
      },
      savePlan: { plan in
        try await EntityHandler().save(plan)
      },
      archivePlan: { identifier in
        guard var plan = try await EntityHandler().fetch(Plan.self, identifier: identifier as CVarArg) else { return }
        plan.isArchived = true
        try await EntityHandler().save(plan)
      },
      loadOccurrences: { planID in
        try await EntityHandler().fetch(
          PlanOccurrence.self,
          predicates: { NSPredicate(format: "planIdentifier == %@", planID as CVarArg) },
          sorts: { NSSortDescriptor(key: "date", ascending: true) }
        )
      },
      saveOccurrences: { occurrences in
        try await EntityHandler().save(occurrences)
      }
    )
  }
}
