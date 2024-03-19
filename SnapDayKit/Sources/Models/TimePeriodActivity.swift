import Foundation

public struct TimePeriodActivity: Identifiable, Equatable {
  public var id: UUID { activity.id }
  public let activity: Activity
  public let tags: [Tag]
  public let totalCount: Int
  public let doneCount: Int
  public let duration: Int

  public init(
    activity: Activity,
    tags: [Tag],
    totalCount: Int,
    doneCount: Int,
    duration: Int
  ) {
    self.activity = activity
    self.tags = tags
    self.totalCount = totalCount
    self.doneCount = doneCount
    self.duration = duration
  }
}

extension TimePeriodActivity {
  public func increasedCount(_ isDone: Bool, duration: Int) -> TimePeriodActivity {
    TimePeriodActivity(
      activity: activity,
      tags: tags,
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
  public var completedValue: Double {
    guard totalCount != .zero else { return .zero }
    return min(Double(doneCount) / Double(totalCount), 1.0)
  }

  public var percent: Int {
    Int(completedValue * 100)
  }
}
