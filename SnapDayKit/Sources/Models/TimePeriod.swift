import Foundation

public struct TimePeriod: Identifiable, Equatable, Hashable {

  struct DaysEmptyError: Error { }

  // MARK: - Properties

  public let id: UUID
  public let days: [Day]
  public let name: String
  public let type: Period
  public let dateRange: ClosedRange<Date>

  // MARK: - Initialization

  public init(
    id: UUID,
    days: [Day],
    name: String,
    type: Period,
    dateRange: ClosedRange<Date>
  ) {
    self.id = id
    self.days = days
    self.name = name
    self.type = type
    self.dateRange = dateRange
  }
}

public extension TimePeriod {
  var firstDay: Day {
    get throws {
      guard let first = days.first else { throw DaysEmptyError() }
      return first
    }
  }
}

public extension TimePeriod {
  var completedValue: Double {
    guard days.plannedCount != .zero else { return .zero }
    return min(Double(days.completedCount) / Double(days.plannedCount), 1.0)
  }

  var percent: Int {
    Int(completedValue * 100)
  }
}
