#if DEBUG
import ComposableArchitecture
import Models
import SwiftUI

private let applyToDaysPreviewActivities = [
  Activity(id: UUID(), name: "Read Spanish book"),
  Activity(id: UUID(), name: "Spanish lesson"),
  Activity(id: UUID(), name: "Spanish exercise")
]

#Preview("Apply to days - replacement") {
  applyToDaysPreview()
}

#Preview("Apply to days - replacement dark") {
  applyToDaysPreview()
    .preferredColorScheme(.dark)
}

@MainActor
private func applyToDaysPreview() -> some View {
  var state = NewPlanFeature.State(
    step: .weeklySchedule,
    name: "Learn Spanish",
    schedule: [
      ScheduledPlanDay(weekday: .monday, activities: [applyToDaysPreviewActivities[0]]),
      ScheduledPlanDay(weekday: .tuesday, activities: [applyToDaysPreviewActivities[1]]),
      ScheduledPlanDay(weekday: .wednesday),
      ScheduledPlanDay(weekday: .thursday, activities: [applyToDaysPreviewActivities[2]])
    ]
  )
  state.applySourceDay = .monday
  state.applyTargetDays = [.tuesday, .wednesday, .thursday]
  state.replacementTargetDays = [.tuesday, .thursday]

  return ApplyToDaysView(
    store: Store(initialState: state) {
      NewPlanFeature()
    },
    sourceWeekday: .monday
  )
}
#endif
