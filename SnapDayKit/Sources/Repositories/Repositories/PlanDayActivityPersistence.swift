import Foundation
import Models

struct PlanDayActivityPersistence {
  func skipAndRemove(_ dayActivity: DayActivity) async throws -> Bool {
    try await EntityHandler().transaction { transaction in
      var occurrences = try transaction.fetch(
        PlanOccurrence.self,
        predicates: {
          NSPredicate(format: "dayActivityIdentifier == %@", dayActivity.id as CVarArg)
          NSPredicate(format: "plan.isArchived == NO")
        }
      )
      guard !occurrences.isEmpty else { return false }

      for index in occurrences.indices {
        occurrences[index].dayActivityID = nil
        occurrences[index].isSkipped = true
      }
      try transaction.save(occurrences)
      try transaction.delete(dayActivity.dayActivityTasks)
      try transaction.delete(dayActivity)
      return true
    }
  }
}
