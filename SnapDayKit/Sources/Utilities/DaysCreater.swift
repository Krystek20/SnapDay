import Foundation
import Dependencies
import Models

struct DaysCreater {

  // MARK: - Dependecies

  @Dependency(\.activityRepository.loadActivities) var loadActivities
  @Dependency(\.dayRepository) var dayRepository
  @Dependency(\.uuid) private var uuid
  @Dependency(\.calendar) private var calendar

  // MARK: - Properties

  private let dayUpdater = DayUpdater()

  // MARK: - Public

  func create(from date: Date) async throws {
    let year = calendar.component(.year, from: date)
    let components = DateComponents(year: year + 1, month: 1, day: 1)
    guard let firstDayNextYear = calendar.date(from: components),
          let lastDayOfCurrentYear = calendar.date(byAdding: .day, value: -1, to: firstDayNextYear) else { return }
    let dateRange = date...lastDayOfCurrentYear
    let existingDays = try await dayRepository.loadDays(dateRange)
    guard existingDays.isEmpty else { return }
    let activities = try await loadActivities()
    let days = try await dayUpdater.prepareDays(for: activities, in: dateRange)
    try await dayRepository.saveDays(days)
  }
}
