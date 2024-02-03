import Foundation

public struct TimePeriod: Identifiable, Equatable, Hashable {

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
  var plannedCount: Int {
    days.reduce(into: Int.zero) { result, day in
      result += day.plannedCount
    }
  }

  var completedCount: Int {
    days.reduce(into: Int.zero) { result, day in
      result += day.completedCount
    }
  }

  var completedValue: Double {
    guard plannedCount != .zero else { return .zero }
    return min(Double(completedCount) / Double(plannedCount), 1.0)
  }

  var percent: Int {
    Int(completedValue * 100)
  }
}
