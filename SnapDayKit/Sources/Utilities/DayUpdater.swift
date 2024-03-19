import Foundation
import Dependencies
import Models
import Repositories

struct DayUpdater {

  enum DayUpdaterError: Error {
    case canNotCreateRange
    case canNotLoadDay(Date)
  }

  // MARK: - Dependecies

  @Dependency(\.dayRepository) private var dayRepository
  @Dependency(\.calendar) private var calendar
  @Dependency(\.uuid) private var uuid

  // MARK: - Properties

  private let activityDatesCreator = ActivityDatesCreator()

  // MARK: - Public

  /// it creates days if not exists and adds activities to them, days are saved to database
  func prepareDays(for activities: [Activity], in dateRange: ClosedRange<Date>) async throws -> [Day] {
    guard let daysNumber = calendar.daysNumber(in: dateRange) else { return [] }
    let existingDays = try await dayRepository.loadDays(dateRange)
    guard (daysNumber + 1) != existingDays.count else { return existingDays }
    let activitiesWithDates = try createDates(for: activities, dateRange: dateRange)
    let days = try (0...daysNumber).compactMap {
      try getDay(
        for: try calendar.date(byAdding: .day, value: $0, to: dateRange.lowerBound).unwrapped,
        days: existingDays,
        activitiesWithDates: activitiesWithDates
      )
    }
    try await saveDays(days: days)
    return days
  }

  /// it fetches existing days and adds activity to them
  func addActivity(_ activity: Activity, from date: Date) async throws {
    let dateRange = try await dateRangeToUpdate(date: date)
    let dates = try activityDatesCreator.createsDates(for: activity, dateRange: dateRange)
    let days = try await dayRepository.loadDays(dateRange)
    let updatedDays: [Day] = dates.compactMap { date in
      guard var day = days.first(where: { $0.date == date }) else { return nil }
      day.activities.append(createDayActivity(activity: activity))
      return day
    }
    try await saveDays(days: updatedDays)
  }

  /// it fetches existing day and adds activity generated by user to it
  func addActivity(_ activity: Activity, to date: Date, createdByUser: Bool = false) async throws {
    var day = try await loadDay(date)
    day.activities.append(createDayActivity(activity: activity, createdByUser: true))
    try await saveDay(day)
  }

  /// it removes day activity from existing day
  func remove(_ dayActivity: DayActivity, date: Date) async throws {
    var day = try await loadDay(date)
    day.activities.removeAll(where: { $0.id == dayActivity.id })
    try await saveDay(day)
  }

  /// it removes existing day activities from days starting from provided date if this day is not current day and activity in this day is not done
  func updateDaysByUpdatedActivity(_ activity: Activity, from date: Date) async throws {
    let dateRange = try await dateRangeToUpdate(date: date)
    var days = try await dayRepository.loadDays(dateRange)
    removeDayActivities(with: activity, in: &days, startDate: date)
    try updateDays(by: activity, in: dateRange, days: &days)
    try await saveDays(days: days)
  }

  func updateDayActivity(_ dayActivity: DayActivity, to date: Date) async throws {
    guard var day = try await dayRepository.loadDay(date),
          let index = day.activities.firstIndex(where: { $0.id == dayActivity.id }) else { return }
    day.activities[index] = dayActivity
    try await saveDay(day)
  }

  // MARK: - Private

  private func createDates(for activities: [Activity], dateRange: ClosedRange<Date>) throws -> [Activity: [Date]] {
    try activities.reduce(into: [Activity: [Date]]()) { result, activity in
      guard let alignedDateRange = prepareAlignedDateRange(for: activity, dateRange: dateRange) else { return }
      let dates = try activityDatesCreator.createsDates(for: activity, dateRange: alignedDateRange)
      result[activity] = dates
    }
  }

  private func prepareAlignedDateRange(for activity: Activity, dateRange: ClosedRange<Date>) -> ClosedRange<Date>? {
    guard let startDate = activity.startDate else { return dateRange }
    let lowerBound = max(dateRange.lowerBound, startDate)
    guard lowerBound <= dateRange.upperBound else { return nil }
    return lowerBound...dateRange.upperBound
  }

  private func getDay(for date: Date, days: [Day], activitiesWithDates: [Activity: [Date]]) throws -> Day? {
    guard let day = days.first(where: { $0.date == date }) else {
      return createPlannedDay(date: date, activitiesWithDates: activitiesWithDates)
    }
    return day
  }

  private func dateRangeToUpdate(date: Date) async throws -> ClosedRange<Date> {
    let days = try await dayRepository.loadAllDays()
    guard let max = days.max(by: { $0.date < $1.date }) else {
      throw DayUpdaterError.canNotCreateRange
    }
    return date...max.date
  }

  private func loadDay(_ date: Date) async throws -> Day {
    guard let day = try await dayRepository.loadDay(date) else {
      throw DayUpdaterError.canNotLoadDay(date)
    }
    return day
  }

  private func removeDayActivities(with activity: Activity, in days: inout [Day], startDate: Date) {
    days.indices.forEach { index in
      let isToday = days[index].date == startDate
      days[index].activities.removeAll(where: {
        $0.activity.id == activity.id
        && $0.isGeneratedAutomatically
        && (!isToday || !$0.isDone)
      })
    }
  }

  func updateDays(by activity: Activity, in dateRange: ClosedRange<Date>, days: inout [Day]) throws {
    guard let alignedDateRange = prepareAlignedDateRange(for: activity, dateRange: dateRange) else { return }
    let dates = try activityDatesCreator.createsDates(for: activity, dateRange: alignedDateRange)
    days.indices.forEach { index in
      guard dates.contains(days[index].date),
            !days[index].activities.contains(where: { $0.activity.id == activity.id }) else { return }
      days[index].activities.append(createDayActivity(activity: activity))
    }
  }

  private func createPlannedDay(date: Date, activitiesWithDates: [Activity: [Date]]) -> Day {
    Day(
      id: uuid(),
      date: date,
      activities: activitiesWithDates.compactMap { (activity, days) in
        guard days.contains(date) else { return nil }
        return createDayActivity(activity: activity)
      }
    )
  }

  private func createDayActivity(activity: Activity, createdByUser: Bool = false) -> DayActivity {
    DayActivity(
      id: uuid(),
      activity: activity,
      isDone: false,
      duration: activity.defaultDuration ?? .zero,
      overview: nil,
      isGeneratedAutomatically: !createdByUser,
      tags: activity.tags
    )
  }

  private func saveDays(days: [Day]) async throws {
    for day in days {
      try await saveDay(day)
    }
  }

  private func saveDay(_ day: Day) async throws {
    try await dayRepository.saveDay(day)
  }
}
