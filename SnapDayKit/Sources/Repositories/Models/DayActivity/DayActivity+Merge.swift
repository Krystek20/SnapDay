import Models

extension DayActivity {
  mutating public func merge(_ dayActivities: [DayActivity]) {
    for dayActivity in dayActivities {
      guard activity?.id == dayActivity.activity?.id else { return }
      if icon == nil {
        icon = dayActivity.icon
      }
      if dueDate == nil {
        dueDate = dayActivity.dueDate
      }
      if doneDate == nil {
        doneDate = dayActivity.doneDate
      }
      if duration == .zero {
        duration = dayActivity.duration
      }
      if reminderDate == nil {
        reminderDate = dayActivity.reminderDate
      }
      if overview == nil || overview?.isEmpty == true {
        overview = dayActivity.overview
      }
    }
  }
}
