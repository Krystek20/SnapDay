public enum MonthlySchedule: Equatable, Hashable, Codable {
  case firstDay
  case secondDay
  case midMonth
  case lastDay
  case secondToLastDay
  case monthlySpecificDate([Int])
  case weekdayOrdinal([WeekdayOrdinal])
}

public struct WeekdayOrdinal: Equatable, Hashable, Codable {

  public enum Position: String, Equatable, Hashable, Codable, CaseIterable, Identifiable {
    case first
    case second
    case third
    case fourth
    case secondToLastDay
    case last

    public var id: String { rawValue }
  }

  // MARK: - Properties

  public let position: Position
  public var weekdays: [Int]

  // MARK: - Initialization

  public init(position: Position, weekdays: [Int]) {
    self.position = position
    self.weekdays = weekdays
  }
}
