#if DEBUG
import ComposableArchitecture
import Foundation
import Models
import SwiftUI

private let newPlanPreviewDate = Calendar(identifier: .gregorian).date(
  from: DateComponents(year: 2026, month: 6, day: 15, hour: 12)
) ?? Date(timeIntervalSinceReferenceDate: 803_390_400)

private let newPlanPreviewActivities = [
  Activity(id: UUID(), name: "Read Spanish book"),
  Activity(id: UUID(), name: "Spanish lesson"),
  Activity(id: UUID(), name: "Spanish exercise")
]

private var newPlanPreviewSchedule: [ScheduledPlanDay] {
  [
    ScheduledPlanDay(weekday: .monday, activities: [newPlanPreviewActivities[0]]),
    ScheduledPlanDay(weekday: .tuesday),
    ScheduledPlanDay(weekday: .wednesday, activities: [newPlanPreviewActivities[1]]),
    ScheduledPlanDay(weekday: .thursday),
    ScheduledPlanDay(weekday: .friday, activities: [newPlanPreviewActivities[2], newPlanPreviewActivities[0]]),
    ScheduledPlanDay(weekday: .saturday),
    ScheduledPlanDay(weekday: .sunday, activities: [newPlanPreviewActivities[1], newPlanPreviewActivities[2]])
  ]
}

#Preview("New Plan") {
  newPlanPreview(state: NewPlanFeature.State(
    name: "Learn Spanish",
    startDate: newPlanPreviewDate
  ))
}

#Preview("Weekly Schedule") {
  newPlanPreview(state: NewPlanFeature.State(
    step: .weeklySchedule,
    name: "Learn Spanish",
    startDate: newPlanPreviewDate,
    schedule: newPlanPreviewSchedule
  ))
}

#Preview("Review Plan") {
  newPlanPreview(state: NewPlanFeature.State(
    step: .review,
    name: "Learn Spanish",
    startDate: newPlanPreviewDate,
    schedule: newPlanPreviewSchedule
  ))
}

#Preview("Weekly Schedule - dark") {
  newPlanPreview(state: NewPlanFeature.State(
    step: .weeklySchedule,
    name: "Learn Spanish",
    startDate: newPlanPreviewDate,
    schedule: newPlanPreviewSchedule
  ))
  .preferredColorScheme(.dark)
}

@MainActor
private func newPlanPreview(state: NewPlanFeature.State) -> some View {
  NavigationStack {
    NewPlanView(
      store: Store(initialState: state) {
        NewPlanFeature()
      }
    )
  }
}
#endif
