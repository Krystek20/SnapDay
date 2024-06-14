import Foundation
import Dependencies
import Models

public struct DayProvider {

  // MARK: - Dependencies

  @Dependency(\.activityRepository.loadActivities) var loadActivities
  @Dependency(\.dayEditor.prepareDays) var prepareDays

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
}
