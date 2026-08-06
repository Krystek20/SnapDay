import Foundation
import Models

public struct DashboardPlanSummary: Equatable, Identifiable {
  public let id: Plan.ID
  public let plan: Plan
  let title: String
  let progress: PlanProgress
  let nextSessionDate: Date?
  let referenceDate: Date

  init(
    plan: Plan,
    occurrences: [PlanOccurrence],
    dayActivities: [DayActivity],
    date: Date,
    calendar: Calendar
  ) {
    let progress = plan.progress(from: occurrences, dayActivities: dayActivities)
    let completedDayActivityIDs = Set(dayActivities.lazy.filter(\.isDone).map(\.id))
    let startOfDate = calendar.startOfDay(for: date)

    self.id = plan.id
    self.plan = plan
    self.title = plan.name
    self.progress = progress
    self.referenceDate = startOfDate
    self.nextSessionDate = occurrences.lazy
      .filter { occurrence in
        occurrence.date >= startOfDate
          && !(occurrence.dayActivityID.map(completedDayActivityIDs.contains) ?? false)
      }
      .map(\.date)
      .min()
  }
}
