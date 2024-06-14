import Foundation

public struct Day: Identifiable, Equatable, Hashable {

  // MARK: - Properties

  public let id: UUID
  public let date: Date
  public var activities: [DayActivity]
  public var isOlderThenToday: Bool?

  // MARK: - Initialization

  public init(
    id: UUID,
    date: Date,
    activities: [DayActivity],
    isOlderThenToday: Bool? = nil
  ) {
    self.id = id
    self.date = date
    self.activities = activities
    self.isOlderThenToday = isOlderThenToday
  }
}

extension Day {
  public var completedActivities: CompletedActivities {
    CompletedActivities(
      doneCount: completedCount,
      totalCount: plannedCount,
      percent: completedValue
    )
  }

  public var plannedCount: Int {
    activities.count
  }

  public var completedCount: Int {
    activities.filter(\.isDone).count
  }

  public var completedValue: Double {
    guard plannedCount != .zero else { return .zero }
    return min(Double(completedCount) / Double(plannedCount), 1.0)
  }
}

extension Day {
  public var sortedDayActivities: [DayActivity] {
    activities.sorted(by: {
      if $0.isDone == $1.isDone { return $0.name < $1.name }
      return !$0.isDone && $1.isDone
    })
  }
}

public extension [Day] {
  var plannedCount: Int {
    reduce(into: Int.zero) { result, day in
      result += day.plannedCount
    }
  }

  var completedCount: Int {
    reduce(into: Int.zero) { result, day in
      result += day.completedCount
    }
  }

  var completedValue: Double {
    guard plannedCount != .zero else { return .zero }
    return Swift.min(Double(completedCount) / Double(plannedCount), 1.0)
  }

  var percent: Int {
    Int(completedValue * 100)
  }
}
