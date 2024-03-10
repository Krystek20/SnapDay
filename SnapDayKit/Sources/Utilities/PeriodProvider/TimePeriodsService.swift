import Foundation
import Dependencies
import Models

struct TimePeriodsService {

  enum TimePeriodsServiceError: Error {
    case canNotPrepareDateRange
  }

  // MARK: - Dependecies

  @Dependency(\.uuid) private var uuid
  @Dependency(\.calendar) private var calendar
  @Dependency(\.activityRepository.loadActivities) var loadActivities
  @Dependency(\.dayEditor.prepareDays) var prepareDays

  // MARK: - Properties

  private let periodDateRangeCreator = PeriodDateRangeCreator()

  // MARK: - Public

  func timePeriod(from period: Period, date: Date, shift: Int) async throws -> TimePeriod {
    guard let dateRange = dateRange(for: period, date: date, shift: shift) else {
      throw TimePeriodsServiceError.canNotPrepareDateRange
    }
    let days = try await prepareDays(try await loadActivities(), dateRange)
    return TimePeriod(
      id: uuid(),
      days: days,
      name: period.rawValue,
      type: period,
      dateRange: dateRange
    )
  }

  // MARK: - Private

  private func dateRange(for type: Period, date: Date, shift: Int = .zero) -> ClosedRange<Date>? {
    switch type {
    case .day:
      let date = calendar.date(byAdding: .day, value: shift, to: date) ?? date
      return periodDateRangeCreator.dayRange(for: date)
    case .week:
      let date = calendar.date(byAdding: .day, value: shift * 7, to: date) ?? date
      return periodDateRangeCreator.weekRange(for: date)
    case .month:
      let date = calendar.date(byAdding: .month, value: shift, to: date) ?? date
      return periodDateRangeCreator.mounthRange(for: date)
    case .quarter:
      let date = calendar.date(byAdding: .month, value: shift * 3, to: date) ?? date
      return periodDateRangeCreator.quarterlyRange(for: date)
    }
  }
}
