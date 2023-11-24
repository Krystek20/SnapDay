import Foundation

public struct Day: Identifiable, Equatable, Hashable {

  // MARK: - Properties

  public let id: UUID
  public let date: Date
  public var activities: [DayActivity]

  // MARK: - Initialization

  public init(
    id: UUID,
    date: Date,
    activities: [DayActivity]
  ) {
    self.id = id
    self.date = date
    self.activities = activities
  }
}
