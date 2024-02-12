import Foundation
import Models

struct TimePeriodActivity: Identifiable, Equatable {
  var id: UUID { activity.id }
  let activity: Activity
  let totalCount: Int
  let doneCount: Int
  let duration: Int
}

extension TimePeriodActivity {
  func increasedCount(_ isDone: Bool, duration: Int) -> TimePeriodActivity {
    TimePeriodActivity(
      activity: activity,
      totalCount: totalCount + 1,
      doneCount: isDone
      ? doneCount + 1
      : doneCount,
      duration: isDone 
      ? self.duration + duration
      : self.duration
    )
  }
}

extension TimePeriodActivity {
  var completedValue: Double {
    guard totalCount != .zero else { return .zero }
    return min(Double(doneCount) / Double(totalCount), 1.0)
  }

  var percent: Int {
    Int(completedValue * 100)
  }
}
