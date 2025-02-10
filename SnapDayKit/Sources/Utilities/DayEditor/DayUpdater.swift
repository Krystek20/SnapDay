import Foundation
import Dependencies
import Models
import Repositories
import CoreData.NSManagedObjectID

@globalActor actor DayActor {
  static let shared = DayActor()
}

@DayActor
final class DayUpdater: TodayProvidable {

  // MARK: - Dependecies

  @Dependency(\.dayActivityRepository) private var dayActivityRepository
  @Dependency(\.utcCalendar) private var utcCalendar
  @Dependency(\.calendar) private var calendar
  @Dependency(\.uuid) private var uuid

  // MARK: - Properties

  private let activityDatesCreator = ActivityDatesCreator()
  private let iCloudStore =  NSUbiquitousKeyValueStore.default
  private let dateActivitiesGeneratedKey = "dateActivitiesGeneratedKey"

  private var generatedDates: [String] {
    guard let generatedDates = iCloudStore.object(forKey: dateActivitiesGeneratedKey) as? [String] else {
      return []
    }
    return generatedDates
  }

  // MARK: - Public

  func prepareDays(for activities: [Activity], in dateRange: ClosedRange<Date>) async throws -> [Day] {
    var days: [Day] = []
    for date in dates(in: dateRange) {
      var dayActivities = try await dayActivityRepository.activities(
        ActivitiesFetchConfiguration(range: date...date)
      )
      if date >= today, !isDayActivitiesGenerated(date: date) {
        let activitiesWithDates = try createActivitiesWithDates(for: activities, dateRange: dateRange)
        dayActivities += try await createDayActivities(date: date, activitiesWithDates: activitiesWithDates)
        setDateActivitiesGenerated(date: date)
      }
      dayActivities = try await removeDeduplicatedDayActivitiesByDate(dayActivities)
      let day = Day(id: uuid(), date: date, activities: dayActivities)
      days.append(day)
    }
    return days
  }

  func updateDaysByUpdatedActivity(_ activity: Activity, from date: Date) async throws {
    let dateRange = try await daysWithRemoved(activity, from: date)
    try await updateDays(by: activity, in: dateRange)
  }

  func updateDaysByRemovedActivity(_ activity: Activity, from date: Date) async throws {
    try await daysWithRemoved(activity, from: date)
  }

  func saveDayActivity(_ dayActivity: DayActivity) async throws {
    try await dayActivityRepository.saveDayActivity(dayActivity)
  }

  func saveDayActivities(_ dayActivities: [DayActivity]) async throws {
    for dayActivity in dayActivities {
      try await saveDayActivity(dayActivity)
    }
  }

  func removeDayActivity(_ dayActivity: DayActivity) async throws {
    try await dayActivityRepository.removeDayActivity(dayActivity)
  }

  func moveDayActivity(_ dayActivity: DayActivity, toDate: Date) async throws {
    var dayActivity = dayActivity
    dayActivity.date = toDate
    dayActivity.isGeneratedAutomatically = false
    dayActivity.reminderDate = calendar.reminderDate(from: dayActivity.reminderDate, dayDate: toDate)
    try await saveDayActivity(dayActivity)
  }

  func copyDayActivity(_ dayActivity: DayActivity, to dates: [Date]) async throws {
    for date in dates {
      let activity = copy(dayActivity: dayActivity, date: date)
      try await saveDayActivity(activity)
    }
  }

  // MARK: - Private

  private func isDayActivitiesGenerated(date: Date) -> Bool {
    generatedDates.contains(date.formatted(.iso8601))
  }

  private func setDateActivitiesGenerated(date: Date) {
    var generatedDates = generatedDates
    generatedDates.append(date.formatted(.iso8601))
    iCloudStore.set(generatedDates, forKey: dateActivitiesGeneratedKey)
    iCloudStore.synchronize()
  }

  private func dates(in dateRange: ClosedRange<Date>) -> [Date] {
    var current = dateRange.lowerBound
    var dates: [Date] = []
    while current <= dateRange.upperBound {
      dates.append(current)
      current = utcCalendar.date(byAdding: .day, value: 1, to: current) ?? current
    }
    return dates
  }

  private func createActivitiesWithDates(for activities: [Activity], dateRange: ClosedRange<Date>) throws -> [Activity: [Date]] {
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

  private func dateRangeToUpdate(date: Date) async throws -> ClosedRange<Date> {
    let maxDate = generatedDates
      .compactMap(ISO8601DateFormatter().date)
      .sorted(by: { $0 > $1 })
      .first ?? date
    return date...maxDate
  }

  @discardableResult
  private func daysWithRemoved(_ activity: Activity, from date: Date) async throws -> ClosedRange<Date> {
    let dateRange = try await dateRangeToUpdate(date: date)
    let dayActivities = try await dayActivityRepository.activities(
      ActivitiesFetchConfiguration(range: dateRange)
    )
    try await removeDayActivities(with: activity, dayActivities: dayActivities, date: date)
    return dateRange
  }

  private func removeDayActivities(with activity: Activity, dayActivities: [DayActivity], date: Date) async throws {
    for dayActivity in dayActivities {
      guard let dayActivityDate = dayActivity.date else { continue }
      let isTodayOrLess = dayActivityDate <= date
      guard dayActivity.activity?.id == activity.id &&
            dayActivity.isGeneratedAutomatically &&
            (!isTodayOrLess || !dayActivity.isDone) else { continue }
      try await removeDayActivity(dayActivity)
    }
  }

  @discardableResult
  private func removeDeduplicatedDayActivitiesByDate(_ dayActivities: [DayActivity]) async throws -> [DayActivity] {
    var activitiesToMerge = dayActivities

    let groupedGeneratedActivities = activitiesToMerge
      .reduce(into: [String: [DayActivity]](), { result, dayActivity in
        guard dayActivity.isGeneratedAutomatically else { return }
        result[dayActivity.name, default: []].append(dayActivity)
      })
    let activitiesToRemove = groupedGeneratedActivities.values.reduce(into: [DayActivity](), { result, dayActivities in
      guard dayActivities.count > 1 else { return }
      var mutableDayActivities = dayActivities
      guard var winner = mutableDayActivities.first(where: { $0.isDone }) ?? mutableDayActivities.first else { return }
      mutableDayActivities.removeAll(where: { $0.id == winner.id })
      winner.merge(Array(mutableDayActivities))
      result.append(contentsOf: mutableDayActivities)
      guard let index = activitiesToMerge.firstIndex(where: { $0.id == winner.id }) else { return }
      activitiesToMerge[index] = winner
    })
    activitiesToMerge.removeAll(where: { dayActivity in
      activitiesToRemove.contains(where: { $0.id == dayActivity.id })
    })

    try await saveDayActivities(activitiesToMerge)
    try await removeDayActivities(activitiesToRemove)
    return activitiesToMerge
  }

  private func updateDays(by activity: Activity, in dateRange: ClosedRange<Date>) async throws {
    guard let alignedDateRange = prepareAlignedDateRange(for: activity, dateRange: dateRange) else { return }
    let activityDates = try activityDatesCreator.createsDates(for: activity, dateRange: alignedDateRange)
    for date in dates(in: dateRange) {
      guard activityDates.contains(date) else { continue }
      let predicates = [
        NSPredicate(format: "templateIdentifier == %@", activity.id as CVarArg),
        NSPredicate(format: "date == %@", date as CVarArg)
      ]
      let configuration = ActivitiesFetchConfiguration(predicates: predicates)
      let dayActivities = try await dayActivityRepository.activities(configuration)
      guard dayActivities.isEmpty else { continue }
      try await createAndSaveDayActivity(activity: activity, date: date)
    }
  }

  private func createDayActivities(date: Date, activitiesWithDates: [Activity: [Date]]) async throws -> [DayActivity] {
    var dayActivities: [DayActivity] = []
    for (activity, daysDate) in activitiesWithDates {
      guard daysDate.contains(date) else { continue }
      let dayActivity = try await createAndSaveDayActivity(activity: activity, date: date)
      dayActivities.append(dayActivity)
    }
    return dayActivities
  }

  @discardableResult
  private func createAndSaveDayActivity(
    activity: Activity,
    createdByUser: Bool = false,
    date: Date
  ) async throws -> DayActivity {
    let dayActivity = DayActivity.create(
      from: activity,
      uuid: { uuid() },
      calendar: { calendar },
      date: date,
      createdByUser: createdByUser
    )
    try await saveDayActivity(dayActivity)
    return dayActivity
  }

  private func copy(dayActivity: DayActivity, date: Date) -> DayActivity {
    DayActivity.copy(
      from: dayActivity,
      uuid: { uuid() },
      date: date,
      calendar: { calendar }
    )
  }

  private func removeDayActivities(_ dayActivities: [DayActivity]) async throws {
    for dayActivity in dayActivities {
      try await removeDayActivity(dayActivity)
    }
  }

  private func removeDayActivityTask(_ dayActivityTask: DayActivityTask) async throws {
    try await dayActivityRepository.removeDayActivityTask(dayActivityTask)
  }
}
