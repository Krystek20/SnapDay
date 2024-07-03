import Foundation
import Dependencies
import Models

public struct DayProvider {

  // MARK: - Dependencies

  @Dependency(\.activityRepository.loadActivities) var loadActivities
  @Dependency(\.dayEditor) var dayEditor

  // MARK: - Initialization

  public init() { }

  // MARK: - Public

  public func day(_ date: Date) async throws -> Day {
    let days = try await dayEditor.prepareDays(try await loadActivities(), date...date)
    guard let day = days.first else {
      struct CanNotCreateDayError: Error { }
      throw CanNotCreateDayError()
    }
    return day
  }

  public func days(_ dateRange: ClosedRange<Date>) async throws -> [Day] {
    try await dayEditor.prepareDays(try await loadActivities(), dateRange)
  }
}

