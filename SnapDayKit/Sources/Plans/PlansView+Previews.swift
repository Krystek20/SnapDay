#if DEBUG
import ComposableArchitecture
import Foundation
import Models
import SwiftUI

#Preview("Plans - active") {
  NavigationStack {
    PlansView(
      store: Store(
        initialState: PlansFeature.State(
          selectedSection: .active,
          activePlans: PlanListItem.activePreviewItems
        ),
        reducer: {
          PlansFeature()
        }
      )
    )
  }
}

#Preview("Plans - empty") {
  NavigationStack {
    PlansView(
      store: Store(
        initialState: PlansFeature.State(selectedSection: .active, activePlans: []),
        reducer: {
          PlansFeature()
        }
      )
    )
  }
}

#Preview("Plans - history") {
  NavigationStack {
    PlansView(
      store: Store(
        initialState: PlansFeature.State(
          selectedSection: .history,
          finishedPlans: [PlanListItem.preview(seed: 5, name: "June Strength", completed: 8, total: 10)],
          archivedPlans: [PlanListItem.preview(seed: 6, name: "Evening Yoga", completed: 5, total: 10, isArchived: true)]
        ),
        reducer: {
          PlansFeature()
        }
      )
    )
  }
}

private extension PlanListItem {
  static var activePreviewItems: [Self] {
    [
      preview(seed: 1, name: "Learn Spanish", completed: 4, total: 10),
      preview(seed: 2, name: "Morning Mobility", completed: 3, total: 12)
    ]
  }

  static func preview(
    seed: UInt8,
    name: String,
    completed: Int,
    total: Int,
    isArchived: Bool = false
  ) -> Self {
    let calendar = Calendar.autoupdatingCurrent
    let today = calendar.startOfDay(for: .now)
    let startDate = calendar.date(byAdding: .day, value: -max(total, 1), to: today) ?? today
    let endDate = calendar.date(byAdding: .day, value: 30, to: today) ?? today
    let activity = Activity(id: identifier(seed: seed, value: 1), name: "Daily practice")
    let plan = Plan(
      id: identifier(seed: seed, value: 0),
      name: name,
      startDate: startDate,
      endDate: endDate,
      duration: .custom,
      isArchived: isArchived,
      schedule: [
        PlanScheduleEntry(
          id: identifier(seed: seed, value: 2),
          weekday: .monday,
          activityID: activity.id,
          position: 0
        )
      ]
    )
    let occurrences = (0..<total).map { index in
      PlanOccurrence(
        planID: plan.id,
        activityID: activity.id,
        date: calendar.date(byAdding: .day, value: index, to: startDate) ?? startDate,
        dayActivityID: identifier(seed: seed, value: UInt8(index + 20))
      )
    }
    let dayActivities = occurrences.prefix(completed).compactMap { occurrence -> DayActivity? in
      guard let dayActivityID = occurrence.dayActivityID else { return nil }
      return DayActivity(
        id: dayActivityID,
        date: occurrence.date,
        doneDate: occurrence.date,
        isGeneratedAutomatically: true
      )
    }
    return Self(
      plan: plan,
      activities: [activity],
      occurrences: occurrences,
      dayActivities: dayActivities
    )
  }

  static func identifier(seed: UInt8, value: UInt8) -> UUID {
    UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, seed, value))
  }
}
#endif
