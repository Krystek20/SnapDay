import Foundation
import Dependencies
import Models
import Repositories

@globalActor actor DayActor {
  static let shared = DayActor()
}

@DayActor
final class DayUpdater {

  enum DayUpdaterError: Error {
    case canNotCreateRange
    case canNotLoadDay(Date)
  }

  // MARK: - Dependecies

  @Dependency(\.dayRepository) private var dayRepository
  @Dependency(\.dayActivityRepository) private var dayActivityRepository
  @Dependency(\.calendar) private var calendar
  @Dependency(\.uuid) private var uuid

  // MARK: - Properties

  private let activityDatesCreator = ActivityDatesCreator()

  // MARK: - Public

  /// it creates days if not exists and adds activities to them, days are saved to database
  func prepareDays(for activities: [Activity], in dateRange: ClosedRange<Date>) async throws -> [Day] {
    let existingDays = try await dayRepository.loadDays(dateRange)
    let groupedDays = Dictionary(grouping: existingDays, by: \.date)
    let neededDates = dates(in: dateRange)
    let activitiesWithDates = try createDates(for: activities, dateRange: dateRange)
    var days: [Day] = []
    var daysToRemove: [Day] = []
    var daysToSave: [Day] = []
    var dayActivitiesToRemove: [DayActivity] = []
    for neededDate in neededDates {
      if let groupedDay = groupedDays[neededDate] {
        switch groupedDay.count {
        case .zero:
          let newDay = createPlannedDay(
            dayId: uuid(),
            date: neededDate,
            activitiesWithDates: activitiesWithDates
          )
          days.append(newDay)
          daysToSave.append(newDay)
        case 1:
          days.append(groupedDay[0])
        default:
          let deduplicatedDays = deduplicatedDays(groupedDay)
          daysToSave.append(deduplicatedDays.winner)
          daysToRemove.append(contentsOf: deduplicatedDays.daysToRemove)
          dayActivitiesToRemove.append(contentsOf: deduplicatedDays.dayActivitiesToRemove)
        }
      } else {
        let newDay = createPlannedDay(
          dayId: uuid(),
          date: neededDate,
          activitiesWithDates: activitiesWithDates
        )
        days.append(newDay)
        daysToSave.append(newDay)
      }
    }
    try await removeDays(daysToRemove)
    try await saveDays(daysToSave)
    try await removeDayActivities(dayActivitiesToRemove)
    return days
  }

  func applyChanges(_ transactions: Transactions) async throws -> AppliedChanges {
    var dates = Set<Date>()
    for inserted in transactions.insertedObjectIDs where inserted.key == Day.entityName {
      for insertedDay in inserted.value {
        guard let object: Day = try dayRepository.object(objectID: insertedDay) else { continue }
        dates.insert(object.date)
        let days = try await dayRepository.loadDays(object.date...object.date)
        guard days.count > 1 else { continue }
        let deduplicatedDays = deduplicatedDays(days)
        try await removeDays(deduplicatedDays.daysToRemove)
        try await saveDay(deduplicatedDays.winner)
        try await removeDayActivities(deduplicatedDays.dayActivitiesToRemove)
      }
    }

    for updated in transactions.updatedObjectIDs where updated.key == Day.entityName {
      for updatedDay in updated.value {
        guard let object: Day = try dayRepository.object(objectID: updatedDay) else { continue }
        dates.insert(object.date)
        let days = try await dayRepository.loadDays(object.date...object.date)
        guard days.count > 1 else { continue }
        let deduplicatedDays = deduplicatedDays(days)
        try await removeDays(deduplicatedDays.daysToRemove)
        try await saveDay(deduplicatedDays.winner)
        try await removeDayActivities(deduplicatedDays.dayActivitiesToRemove)
      }
    }

    for updated in transactions.updatedObjectIDs where updated.key == DayActivity.entityName {
      for updatedDayActivity in updated.value {
        guard let dayActivity: DayActivity = try dayRepository.object(objectID: updatedDayActivity),
              let day: Day = try await dayRepository.object(identifier: dayActivity.dayId) else { continue }
        dates.insert(day.date)
      }
    }

    for updated in transactions.updatedObjectIDs where updated.key == DayActivityTask.entityName {
      for updatedDayActivityTask in updated.value {
        guard let dayActivityTask: DayActivityTask = try dayRepository.object(objectID: updatedDayActivityTask),
              let dayActivity: DayActivity = try await dayRepository.object(identifier: dayActivityTask.dayActivityId),
              let day: Day = try await dayRepository.object(identifier: dayActivity.dayId) else { continue }
        dates.insert(day.date)
      }
    }

    return AppliedChanges(dates: Array(dates))
  }

  private func deduplicatedDays(_ days: [Day]) -> (
    winner: Day,
    daysToRemove: [Day],
    dayActivitiesToRemove: [DayActivity]
  ) {
    var days = days
    var activitiesToMerge = days.flatMap { $0.activities }

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

    var winner = days.removeFirst()
    winner.activities = activitiesToMerge

    return (
      winner: winner,
      daysToRemove: days,
      dayActivitiesToRemove: activitiesToRemove
    )
  }

  func dates(in dateRange: ClosedRange<Date>) -> [Date] {
    var current = dateRange.lowerBound
    var dates: [Date] = []
    while current <= dateRange.upperBound {
      dates.append(current)
      current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
    }
    return dates
  }

  /// it fetches existing days and adds activity to them
  func addActivity(_ activity: Activity, from date: Date) async throws {
    let dateRange = try await dateRangeToUpdate(date: date)
    let dates = try activityDatesCreator.createsDates(for: activity, dateRange: dateRange)
    let days = try await dayRepository.loadDays(dateRange)
    let updatedDays: [Day] = dates.compactMap { date in
      guard var day = days.first(where: { $0.date == date }) else { return nil }
      day.activities.append(
        createDayActivity(
          dayId: day.id,
          activity: activity,
          dayDate: day.date
        )
      )
      return day
    }
    try await saveDays(updatedDays)
  }

  /// it fetches existing day and adds activity generated by user to it
  func addActivity(_ activity: Activity, to date: Date, createdByUser: Bool = false) async throws {
    var day = try await loadDay(date)
    day.activities.append(
      createDayActivity(
        dayId: day.id,
        activity: activity,
        createdByUser: true,
        dayDate: day.date
      )
    )
    try await saveDay(day)
  }

  /// it removes day activity from existing day
  func remove(_ dayActivity: DayActivity, date: Date) async throws {
    var day = try await loadDay(date)
    day.activities.removeAll(where: { $0.id == dayActivity.id })
    try await saveDay(day)
    try await removeDayActivity(dayActivity)
  }

  /// it removes existing day activities from days starting from provided date if this day is not current day and activity in this day is not done
  func updateDaysByUpdatedActivity(_ activity: Activity, from date: Date) async throws {
    var (days, dateRange) = try await daysWithRemoved(activity, from: date)
    try updateDays(by: activity, in: dateRange, days: &days)
    try await saveDays(days)
  }

  func updateDaysByRemovedActivity(_ activity: Activity, from date: Date) async throws {
    let (days, _) = try await daysWithRemoved(activity, from: date)
    try await saveDays(days)
  }

  private func daysWithRemoved(_ activity: Activity, from date: Date) async throws -> ([Day], ClosedRange<Date>) {
    let dateRange = try await dateRangeToUpdate(date: date)
    var days = try await dayRepository.loadDays(dateRange)
    try await removeDayActivities(with: activity, in: &days, startDate: date)
    return (days, dateRange)
  }

  func addDayActivity(_ dayActivity: DayActivity, to date: Date) async throws {
    guard var day = try await dayRepository.loadDay(date) else { return }
    day.activities.append(dayActivity)
    try await saveDay(day)
  }

  func updateDayActivity(_ dayActivity: DayActivity, to date: Date) async throws {
    guard var day = try await dayRepository.loadDay(date),
          let index = day.activities.firstIndex(where: { $0.id == dayActivity.id }) else { return }
    let tasksToRemove = day.activities[index].dayActivityTasks.filter {
      !dayActivity.dayActivityTasks.contains($0)
    }
    for task in tasksToRemove {
      try await removeDayActivityTask(task)
    }
    day.activities[index] = dayActivity
    try await saveDay(day)
  }

  func moveDayActivity(_ dayActivity: DayActivity, toDate: Date) async throws {
    var fromDay: Day? = try await dayRepository.object(identifier: dayActivity.dayId)
    fromDay?.activities.removeAll(where: { $0.id == dayActivity.id })
    if let fromDay {
      try await dayRepository.saveDay(fromDay)
    }
    var dayActivity = dayActivity
    dayActivity.isGeneratedAutomatically = false
    dayActivity.reminderDate = calendar.reminderDate(from: dayActivity.reminderDate, dayDate: toDate)

    if var day = try await dayRepository.loadDay(toDate) {
      dayActivity.dayId = day.id
      day.activities.append(dayActivity)
      try await dayRepository.saveDay(day)
    } else {
      let dayId = uuid()
      dayActivity.dayId = dayId
      let day = Day(
        id: dayId,
        date: toDate,
        activities: [dayActivity]
      )
      try await dayRepository.saveDay(day)
    }
  }

  func copyDayActivity(_ dayActivity: DayActivity, to dates: [Date]) async throws {
    for date in dates {
      if var day = try await dayRepository.loadDay(date) {
        day.activities.append(
          copy(dayActivity: dayActivity, dayId: day.id, dayDate: date)
        )
        try await dayRepository.saveDay(day)
      } else {
        let dayId = uuid()
        let dayActivity = copy(dayActivity: dayActivity, dayId: dayId, dayDate: date)
        let day = Day(
          id: dayId,
          date: date,
          activities: [dayActivity]
        )
        try await dayRepository.saveDay(day)
      }
    }
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
      return createPlannedDay(
        dayId: uuid(),
        date: date,
        activitiesWithDates: activitiesWithDates
      )
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

  private func removeDayActivities(with activity: Activity, in days: inout [Day], startDate: Date) async throws {
    for index in days.indices {
      let isToday = days[index].date == startDate
      let activitiesToRemove = days[index].activities.filter {
        $0.activity?.id == activity.id
        && $0.isGeneratedAutomatically
        && (!isToday || !$0.isDone)
      }
      try await removeDayActivities(activitiesToRemove)

      days[index].activities.removeAll(where: {
        activitiesToRemove.contains($0)
      })
    }
  }

  func updateDays(by activity: Activity, in dateRange: ClosedRange<Date>, days: inout [Day]) throws {
    guard let alignedDateRange = prepareAlignedDateRange(for: activity, dateRange: dateRange) else { return }
    let dates = try activityDatesCreator.createsDates(for: activity, dateRange: alignedDateRange)
    days.indices.forEach { index in
      guard dates.contains(days[index].date),
            !days[index].activities.contains(where: { $0.activity?.id == activity.id }) else { return }
      days[index].activities.append(
        createDayActivity(
          dayId: days[index].id,
          activity: activity,
          dayDate: days[index].date
        )
      )
    }
  }

  private func createPlannedDay(
    dayId: UUID,
    date: Date,
    activitiesWithDates: [Activity: [Date]]
  ) -> Day {
    Day(
      id: dayId,
      date: date,
      activities: createDayActivities(
        dayId: dayId,
        date: date,
        activitiesWithDates: activitiesWithDates
      )
    )
  }

  private func createDayActivities(
    dayId: UUID,
    date: Date,
    activitiesWithDates: [Activity: [Date]]
  ) -> [DayActivity] {
    activitiesWithDates.compactMap { activity, days in
      guard days.contains(date) else { return nil }
      return createDayActivity(
        dayId: dayId,
        activity: activity,
        dayDate: date
      )
    }
  }

  private func createDayActivity(
    dayId: UUID,
    activity: Activity,
    createdByUser: Bool = false,
    dayDate: Date
  ) -> DayActivity {
    DayActivity.create(
      from: activity,
      uuid: { uuid() },
      calendar: { calendar },
      dayId: dayId,
      dayDate: dayDate,
      createdByUser: createdByUser
    )
  }

  private func copy(dayActivity: DayActivity, dayId: UUID, dayDate: Date) -> DayActivity {
    DayActivity.copy(
      from: dayActivity,
      uuid: { uuid() },
      dayId: dayId,
      dayDate: dayDate,
      calendar: { calendar }
    )
  }

  private func saveDays(_ days: [Day]) async throws {
    for day in days {
      try await saveDay(day)
    }
  }

  private func saveDay(_ day: Day) async throws {
    try await dayRepository.saveDay(day)
  }

  private func removeDays(_ days: [Day]) async throws {
    for day in days {
      try await removeDay(day)
    }
  }

  private func removeDay(_ day: Day) async throws {
    try await dayRepository.removeDay(day)
  }

  private func removeDayActivities(_ dayActivities: [DayActivity]) async throws {
    for dayActivity in dayActivities {
      try await removeDayActivity(dayActivity)
    }
  }

  private func removeDayActivity(_ dayActivity: DayActivity) async throws {
    try await dayActivityRepository.removeDayActivity(dayActivity)
  }

  private func removeDayActivityTask(_ dayActivityTask: DayActivityTask) async throws {
    try await dayActivityRepository.removeDayActivityTask(dayActivityTask)
  }
}
