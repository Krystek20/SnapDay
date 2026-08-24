import Dependencies
import Foundation
import Models

public struct PlanRepository {
  public var loadPlans: @Sendable () async throws -> [Plan]
  public var loadActivePlans: @Sendable (_ date: Date) async throws -> [Plan]
  public var loadHistoricalPlans: @Sendable (_ date: Date) async throws -> [Plan]
  public var plan: @Sendable (_ identifier: Plan.ID) async throws -> Plan?
  public var savePlan: @Sendable (_ plan: Plan) async throws -> Void
  public var archivePlan: @Sendable (_ identifier: Plan.ID, _ from: Date) async throws -> Void
  public var deletePlan: @Sendable (_ identifier: Plan.ID, _ from: Date) async throws -> Void
  public var loadOccurrences: @Sendable (_ planID: Plan.ID) async throws -> [PlanOccurrence]
  public var saveOccurrences: @Sendable (_ occurrences: [PlanOccurrence]) async throws -> Void
  public var synchronizeOccurrences: @Sendable (_ plan: Plan, _ from: Date) async throws -> [PlanOccurrence]
  public var skipDayActivity: @Sendable (_ dayActivity: DayActivity) async throws -> Bool
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
      archivePlan: { identifier, from in
        try await PlanLifecyclePersistence().archivePlan(identifier, from: from)
      },
      deletePlan: { identifier, from in
        try await PlanLifecyclePersistence().deletePlan(identifier, from: from)
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
        try await EntityHandler().transaction { transaction in
          let calendar = Calendar.planRepositoryCalendar
          let lowerBound = max(
            calendar.startOfDay(for: plan.startDate),
            calendar.startOfDay(for: from)
          )
          let existing = try transaction.fetch(
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
          try transaction.delete(obsolete)

          let retained = existing.filter { !obsolete.contains($0) }
          let retainedByID = Dictionary(
            retained.map { ($0.id, $0) },
            uniquingKeysWith: { existing, _ in existing }
          )
          let occurrences = generated.map { retainedByID[$0.id] ?? $0 }
            + retained.filter { $0.date < lowerBound || !generatedIDs.contains($0.id) }
          try transaction.save(occurrences)
          return occurrences
            .deduplicatedByID()
            .sorted { $0.date < $1.date }
        }
      },
      skipDayActivity: { dayActivity in
        try await PlanDayActivityPersistence().skipAndRemove(dayActivity)
      }
    )
  }
}

extension Calendar {
  static var planRepositoryCalendar: Calendar {
    var calendar = Calendar.autoupdatingCurrent
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
  }
}
