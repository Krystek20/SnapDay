import Foundation
import Models

struct PlanLifecyclePersistence {
  func archivePlan(_ identifier: Plan.ID, from date: Date) async throws {
    try await mutatePlan(identifier, from: date, mutation: .archive)
  }

  func deletePlan(_ identifier: Plan.ID, from date: Date) async throws {
    try await mutatePlan(identifier, from: date, mutation: .delete)
  }

  private func mutatePlan(
    _ identifier: Plan.ID,
    from date: Date,
    mutation: Mutation
  ) async throws {
    try await EntityHandler().transaction { transaction in
      guard var plan = try transaction.fetch(Plan.self, identifier: identifier as CVarArg) else {
        return
      }
      let dayActivities = try upcomingGeneratedDayActivities(
        for: identifier,
        from: date,
        transaction: transaction
      )
      try transaction.delete(dayActivities)

      switch mutation {
      case .archive:
        plan.isArchived = true
        try transaction.save(plan)
      case .delete:
        try transaction.delete(plan)
      }
    }
  }

  private func upcomingGeneratedDayActivities(
    for planID: Plan.ID,
    from date: Date,
    transaction: EntityTransaction
  ) throws -> [DayActivity] {
    let startOfDay = Calendar.planRepositoryCalendar.startOfDay(for: date)
    let occurrences = try transaction.fetch(
      PlanOccurrence.self,
      predicates: {
        NSPredicate(format: "planIdentifier == %@", planID as CVarArg)
        NSPredicate(format: "date >= %@", startOfDay as NSDate)
        NSPredicate(format: "dayActivityIdentifier != nil")
      }
    )
    let linkedDayActivityIDs = Set(occurrences.compactMap(\.dayActivityID))
    guard !linkedDayActivityIDs.isEmpty else { return [] }

    let occurrencesFromOtherActivePlans = try transaction.fetch(
      PlanOccurrence.self,
      predicates: {
        NSPredicate(format: "planIdentifier != %@", planID as CVarArg)
        NSPredicate(format: "dayActivityIdentifier IN %@", Array(linkedDayActivityIDs))
        NSPredicate(format: "plan.isArchived == NO")
      }
    )
    let dayActivityIDsUsedByOtherActivePlans = Set(
      occurrencesFromOtherActivePlans.compactMap(\.dayActivityID)
    )
    let removableDayActivityIDs = linkedDayActivityIDs
      .subtracting(dayActivityIDsUsedByOtherActivePlans)
    guard !removableDayActivityIDs.isEmpty else { return [] }

    return try transaction.fetch(
      DayActivity.self,
      predicates: {
        NSPredicate(format: "identifier IN %@", Array(removableDayActivityIDs))
        NSPredicate(format: "date >= %@", startOfDay as NSDate)
        NSPredicate(format: "doneDate == nil")
        NSPredicate(format: "isGeneratedAutomatically == YES")
      }
    )
  }

  private enum Mutation {
    case archive
    case delete
  }
}
