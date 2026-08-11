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
  public var synchronizeOccurrences: @Sendable (_ plan: Plan, _ from: Date) async throws -> [PlanOccurrence]
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
        let calendar = Calendar.planRepositoryCalendar
        let startOfDay = calendar.startOfDay(for: date)
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        return try await EntityHandler().fetch(
          Plan.self,
          predicates: {
            NSPredicate(format: "isArchived == NO")
            NSPredicate(
              format: "startDate < %@ AND endDate >= %@",
              startOfNextDay as NSDate,
              startOfDay as NSDate
            )
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
              Calendar.planRepositoryCalendar.startOfDay(for: date) as NSDate
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
      },
      synchronizeOccurrences: { plan, from in
        let entityHandler = EntityHandler()
        let calendar = Calendar.planRepositoryCalendar
        let lowerBound = max(
          calendar.startOfDay(for: plan.startDate),
          calendar.startOfDay(for: from)
        )
        let existing = try await entityHandler.fetch(
          PlanOccurrence.self,
          predicates: { NSPredicate(format: "planIdentifier == %@", plan.id as CVarArg) },
          sorts: { NSSortDescriptor(key: "date", ascending: true) }
        )
        .deduplicatedByID()
        let generated = plan.scheduledOccurrences(from: lowerBound, calendar: calendar)
        let generatedIDs = Set(generated.map(\.id))
        let obsolete = existing.filter {
          $0.date >= lowerBound && !generatedIDs.contains($0.id)
        }
        if !obsolete.isEmpty {
          try await entityHandler.delete(obsolete)
        }

        let retained = existing.filter { !obsolete.contains($0) }
        let retainedByID = Dictionary(
          retained.map { ($0.id, $0) },
          uniquingKeysWith: { existing, _ in existing }
        )
        let occurrences = generated.map { retainedByID[$0.id] ?? $0 }
          + retained.filter { $0.date < lowerBound || !generatedIDs.contains($0.id) }
        if !occurrences.isEmpty {
          try await entityHandler.save(occurrences)
        }
        return occurrences
          .deduplicatedByID()
          .sorted { $0.date < $1.date }
      }
    )
  }
}

private extension Calendar {
  static var planRepositoryCalendar: Calendar {
    var calendar = Calendar.autoupdatingCurrent
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
  }
}
