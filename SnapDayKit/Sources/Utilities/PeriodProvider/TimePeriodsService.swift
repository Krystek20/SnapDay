import Foundation
import Dependencies
import Models

struct TimePeriodsService {

  // MARK: - Dependecies

  @Dependency(\.dayRepository) var dayRepository
  @Dependency(\.uuid) private var uuid
  @Dependency(\.calendar) private var calendar

  // MARK: - Properties

  private let periodDateRangeCreator = PeriodDateRangeCreator()

  // MARK: - Public

  func timePerdiods(date: Date) async throws -> [TimePeriod] {
    var timePeriods = [TimePeriod]()
    for period in Period.allCases {
      guard let dateRange = dateRange(for: period, date: date) else { continue }
      let days = try await dayRepository.loadDays(dateRange)
      let timePeriod = TimePeriod(
        id: uuid(),
        days: days,
        name: period.rawValue,
        type: period,
        dateRange: dateRange
      )
      timePeriods.append(timePeriod)
    }
    return timePeriods
  }

  // MARK: - Private

  private func dateRange(for type: Period, date: Date) -> ClosedRange<Date>? {
    switch type {
    case .day:
      periodDateRangeCreator.today(for: date)
    case .week:
      periodDateRangeCreator.weekRange(for: date)
    case .month:
      periodDateRangeCreator.mounthRange(for: date)
    case .quarter:
      periodDateRangeCreator.quarterlyRange(for: date)
    }
  }
}
