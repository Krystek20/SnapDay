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
  public var plannedCount: Int {
    activities.count
  }

  public var completedCount: Int {
    activities.filter(\.isDone).count
  }
}