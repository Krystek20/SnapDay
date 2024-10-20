import Foundation
import Dependencies
import Models
import Repositories

public struct DayProvider: TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.activityRepository.loadActivities) private var loadActivities
  @Dependency(\.dayActivityRepository) private var dayActivityRepository
  @Dependency(\.dayEditor) private var dayEditor
  @Dependency(\.calendar) private var calendar
  @Dependency(\.dayRepository) private var dayRepository

  // MARK: - Initialization

  public init() { }

  // MARK: - Public

  public func day(_ date: Date) async throws -> Day {
    try await moveDayActivitiesIfDueTime(date: date)
    let days = try await dayEditor.prepareDays(try await loadActivities(), date...date)
    guard var day = days.first else {
      struct CanNotCreateDayError: Error { }
      throw CanNotCreateDayError()
    }
    day.activities = day.activities.sorted(calendar: calendar)
    try await dayRepository.saveDay(day)

    return day
  }

  public func days(_ dateRange: ClosedRange<Date>) async throws -> [Day] {
    try await dayEditor.prepareDays(try await loadActivities(), dateRange)
  }

  // MARK: - Private

  private func moveDayActivitiesIfDueTime(date: Date) async throws {
    guard date == today else { return }
    let predicates = [
      NSPredicate(format: "day.date < %@", date as NSDate),
      NSPredicate(format: "dueDate >= %@", date as NSDate)
    ]
    let activities = try await dayActivityRepository.activities(
      ActivitiesFetchConfiguration(done: false, predicates: predicates)
    )
    for activity in activities {
      try await dayEditor.moveDayActivity(activity, date)
    }
  }
}
