import Foundation
import Models

struct PlanListItem: Equatable, Identifiable {
  let plan: Plan
  let activities: [Activity]
  let occurrences: [PlanOccurrence]
  let dayActivities: [DayActivity]

  var id: Plan.ID { plan.id }

  var progress: PlanProgress {
    plan.progress(from: occurrences, dayActivities: dayActivities)
  }
}
