import Foundation
import Dependencies
import Models

public struct DayProvider {

  // MARK: - Dependencies

  @Dependency(\.activityRepository.loadActivities) var loadActivities
  @Dependency(\.dayRepository) var dayRepository
  @Dependency(\.dayActivityRepository) var dayActivityRepository
  @Dependency(\.dayEditor.prepareDays) var prepareDays
  @Dependency(\.calendar) var calendar

  // MARK: - Initialization

  public init() { }

  // MARK: - Public

  public func day(for date: Date) async throws -> Day {
    let days = try await prepareDays(try await loadActivities(), date...date)
    guard let day = days.first else {
      struct CanNotCreateDayError: Error { }
      throw CanNotCreateDayError()
    }
    return day
  }

  public func removeBrokenDays() async throws {
    let days = try await dayRepository.loadAllDays()
    for day in days {
      let components = calendar.dateComponents([.hour, .minute], from: day.date)
      guard components.hour == 21, components.minute == 15 else { continue }
      for activity in day.activities {
        try await dayActivityRepository.removeDayActivity(activity)
      }
      try await dayRepository.removeDay(day)
      print("removed: \(day.date)")
    }
  }
}
