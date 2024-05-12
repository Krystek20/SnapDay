import Models

extension DayActivity {
  mutating public func merge(_ dayActivities: [DayActivity]) {
    for dayActivity in dayActivities {
      guard activity.id == dayActivity.id else { return }
      if icon == nil {
        icon = dayActivity.icon
      }
      if doneDate == nil {
        doneDate = dayActivity.doneDate
      }
      if duration == .zero {
        duration = dayActivity.duration
      }
      if overview == nil || overview?.isEmpty == true {
        overview = dayActivity.overview
      }
    }
  }
}
