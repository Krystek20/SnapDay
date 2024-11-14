import Foundation

public struct PeriodSummaryData: Equatable {
  let periods: [PeriodSummary]
  let isScrollable: Bool
  let maxInRow: Int

  var totalAvailableTimeAvarage: Int {
    periods.map(\.totalAvailableTime).reduce(Int.zero, +) / periods.count
  }

  var optimalTime: Int {
    guard periods.count > .zero else { return .zero }
    return periods.map(\.optimalTime).reduce(Int.zero, +) / periods.count
  }

  var totalPlannedTime: Int {
    periods.map(\.totalPlannedDuration).reduce(Int.zero, +)
  }

  var totalAvailableTime: Int {
    periods.map(\.totalAvailableTime).reduce(Int.zero, +)
  }

  var totalCompletedTime: Int {
    periods.map(\.totalCompletedDuration).reduce(Int.zero, +)
  }

  var totalPlannedTimePercent: Double {
    guard totalAvailableTime > .zero else { return .zero }
    return Double(totalPlannedTime) / Double(totalAvailableTime)
  }

  var totalCompletedTimePercent: Double {
    guard totalPlannedTime > .zero else { return .zero }
    return Double(totalCompletedTime) / Double(totalPlannedTime)
  }
}

public struct PeriodSummary: Identifiable, Equatable {

  // MARK: - Properties

  public let id: UUID
  let label: String
  let completedValue: Double
  let percent: Int
  let totalPlannedDuration: Int
  let totalCompletedDuration: Int
  let totalAvailableTime: Int
  let optimalTime: Int

  // MARK: - Initialization

  public init(
    id: UUID,
    label: String,
    completedValue: Double,
    percent: Int,
    totalPlannedDuration: Int,
    totalCompletedDuration: Int,
    totalAvailableTime: Int,
    optimalTime: Int
  ) {
    self.id = id
    self.label = label
    self.completedValue = completedValue
    self.percent = percent
    self.totalPlannedDuration = totalPlannedDuration
    self.totalCompletedDuration = totalCompletedDuration
    self.totalAvailableTime = totalAvailableTime
    self.optimalTime = optimalTime
  }
}
