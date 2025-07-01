import Foundation
import Dependencies
import Models
import Repositories
import CoreData.NSManagedObjectID
import CloudKit

extension DependencyValues {
  public var dayUpdater: DayUpdater {
    get { self[DayUpdater.self] }
    set { self[DayUpdater.self] = newValue }
  }
}

extension DayUpdater: DependencyKey {
  public static var liveValue: DayUpdater {
    DayUpdater()
  }
}

public actor DayUpdater: TodayProvidable {

  // MARK: - Dependecies

  @Dependency(\.dayActivityRepository) private var dayActivityRepository
  @Dependency(\.utcCalendar) private var utcCalendar
  @Dependency(\.calendar) private var calendar
  @Dependency(\.uuid) private var uuid
  @Dependency(\.cloudService) private var cloudService
  @Dependency(\.activityRepository.loadActivities) private var loadActivities
  @Dependency(\.date.now) private var now
  @Dependency(\.iconProvider) private var iconProvider

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

  private let sharedDayActivityUpdater = SharedDayActivityUpdater()

  // MARK: - Public

  public func day(_ date: Date) async throws -> Day {
    try await moveDayActivitiesIfDueTime(date: date)
    let days = try await days(for: date...date)
    guard var day = days.first else {
      struct CanNotCreateDayError: Error { }
      throw CanNotCreateDayError()
    }
    day.activities = day.activities.sorted(calendar: utcCalendar)
    try await saveDayActivities(day.activities)
    return day
  }

  public func days(for dateRange: ClosedRange<Date>) async throws -> [Day] {
    let activities = try await loadActivities()
    let invited = try await cloudService.invited()

    var days: [Day] = []
    for date in dates(in: dateRange) {
      var dayActivities = try await dayActivityRepository.dayActivities(
        configuration: ActivitiesFetchConfiguration(range: date...date)
      )
      if date >= today, !isDayActivitiesGenerated(date: date) {
        let activitiesWithDates = try createActivitiesWithDates(for: activities, dateRange: dateRange)
        dayActivities += try await createDayActivities(date: date, activitiesWithDates: activitiesWithDates)
        setDateActivitiesGenerated(date: date)
      }
      dayActivities = try await removeDeduplicatedDayActivitiesByDate(dayActivities)

      try await updateDayActivitiesWithShared(&dayActivities, participants: invited)
      try await updateDayActivitiesWithInvitations(&dayActivities, date: date)

      let day = Day(id: uuid(), date: date, activities: dayActivities)
      days.append(day)
    }
    return days
  }

  public func updateDaysByUpdatedActivity(_ activity: Activity, from date: Date) async throws {
    let dateRange = try await daysWithRemoved(activity, from: date)
    try await updateDays(by: activity, in: dateRange)
  }

  public func updateDaysByRemovedActivity(_ activity: Activity, from date: Date) async throws {
    try await daysWithRemoved(activity, from: date)
  }

  public func dayActivity(identifier: String) async throws -> DayActivity? {
    try await dayActivityRepository.activity(identifier: identifier)
  }

  public func dayActivities(
    configuration: ActivitiesFetchConfiguration = ActivitiesFetchConfiguration()
  ) async throws -> [DayActivity] {
    try await dayActivityRepository.dayActivities(configuration: configuration)
  }

  public func dayActivityTask(identifier: String) async throws -> DayActivityTask? {
    try await dayActivityRepository.activityTask(identifier: identifier)
  }

  public func saveDayActivity(_ dayActivity: DayActivity, syncSharable: Bool) async throws {
    try await dayActivityRepository.saveDayActivity(dayActivity)
    guard syncSharable else { return }
    try await sharedDayActivityUpdater.updateSharedDayActivity(dayActivity: dayActivity)
  }

  public func saveDayActivities(_ dayActivities: [DayActivity]) async throws {
    for dayActivity in dayActivities where dayActivity.isTemporary {
      try await saveDayActivity(dayActivity, syncSharable: false)
    }
  }

  public func saveDayActivityTask(_ dayActivityTask: DayActivityTask, syncSharable: Bool) async throws {
    try await dayActivityRepository.saveDayActivityTask(dayActivityTask)
    guard syncSharable else { return }
    try await sharedDayActivityUpdater.updateSharedDayActivityTask(dayActivityTask: dayActivityTask)
  }

  public func removeDayActivity(_ dayActivity: DayActivity) async throws {
    try await dayActivityRepository.removeDayActivity(dayActivity)
  }

  public func removeDayActivityTask(_ dayActivityTask: DayActivityTask) async throws {
    try await dayActivityRepository.removeDayActivityTask(dayActivityTask)
  }

  public func moveDayActivity(_ dayActivity: DayActivity, toDate: Date) async throws {
    var dayActivity = dayActivity
    dayActivity.date = toDate
    dayActivity.isGeneratedAutomatically = false
    dayActivity.reminderDate = calendar.reminderDate(from: dayActivity.reminderDate, dayDate: toDate)
    try await saveDayActivity(dayActivity, syncSharable: true)
  }

  public func copyDayActivity(_ dayActivity: DayActivity, to dates: [Date]) async throws {
    for date in dates {
      let activity = copy(dayActivity: dayActivity, date: date)
      try await saveDayActivity(activity, syncSharable: false)
    }
  }

  public func addParticipant(_ participantId: String, to dayActivity: DayActivity) async throws {
    guard let recordName = try await cloudService.invited().first(where: { $0.id == participantId })?.recordName else { return }
    try await sharedDayActivityUpdater.addParticipant(recordName, to: dayActivity)
  }

  public func removeParticipant(_ participantId: String, to dayActivity: DayActivity) async throws {
    guard let recordName = try await cloudService.invited().first(where: { $0.id == participantId })?.recordName else { return }
    try await sharedDayActivityUpdater.removeParticipant(recordName, to: dayActivity)
  }

  public func stopCollaboration(in dayActivity: DayActivity) async throws {
    try await sharedDayActivityUpdater.stopCollaboration(in: dayActivity)
  }

  public func syncShared() async throws {
    guard let userRecordName = await cloudService.userRecordName else { return }
    for update in try await sharedDayActivityUpdater.updates {
      try await updateDayActivity(update: update, userRecordName: userRecordName)
    }
  }

  private func updateDayActivity(update: SharedDayActivityUpdater.Update, userRecordName: String) async throws {
    guard var dayActivity = try await dayActivityRepository.activity(identifier: update.sharedBy.objectId) else { return }
    if let iconId = dayActivity.iconId {
      await iconProvider.updateIcon(with: iconId, byIconId: update.sharedDayActivity.iconId)
    } else {
      let newIcon = await iconProvider.createIcon(from: update.sharedDayActivity.iconId)
      dayActivity.iconId = newIcon.id
    }
    let tasksToRemove = try await dayActivity.update(by: update.sharedDayActivity, userRecordName: userRecordName, uuid: uuid)
    for task in tasksToRemove {
      try await dayActivityRepository.removeDayActivityTask(task)
    }
    try await dayActivityRepository.saveDayActivity(dayActivity)
  }

  public func acceptInvitation(for dayActivity: DayActivity) async throws {
    try await sharedDayActivityUpdater.acceptInvitation(for: dayActivity)
    var dayActivity = dayActivity
    if let iconId = dayActivity.iconId {
      let newIcon = await iconProvider.createIcon(from: iconId)
      dayActivity.iconId = newIcon.id
    }
    try await dayActivityRepository.saveDayActivity(dayActivity)
  }

  public func discardInvitation(for dayActivity: DayActivity) async throws {
    try await sharedDayActivityUpdater.discardInvitation(for: dayActivity)
  }

  // MARK: - Private

  private func moveDayActivitiesIfDueTime(date: Date) async throws {
    guard date == today else { return }
    let predicates = [
      NSPredicate(format: "date < %@", date as NSDate),
      NSPredicate(format: "dueDate >= %@", date as NSDate)
    ]
    let activities = try await dayActivities(
      configuration: ActivitiesFetchConfiguration(done: false, predicates: predicates)
    )
    for activity in activities {
      try await moveDayActivity(activity, toDate: date)
    }
  }

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
    let dayActivities = try await dayActivityRepository.dayActivities(
      configuration: ActivitiesFetchConfiguration(range: dateRange)
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
      let dayActivities = try await dayActivityRepository.dayActivities(configuration: configuration)
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
    try await saveDayActivity(dayActivity, syncSharable: false)
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

  private func updateDayActivitiesWithShared(
    _ dayActivities: inout [DayActivity],
    participants: [Participant]
  ) async throws {
    for (index, dayActivity) in dayActivities.enumerated() {
      guard let sharedDayActivity = try await dayActivityRepository.sharedDayActivity(objectId: dayActivity.id.uuidString),
            let share = try await cloudService.allShares().first(where: { $0.sharedDayActivities.contains { $0.id == sharedDayActivity.id } }) else {
        dayActivities[index].share = .notSharedYet(availableParticipants: makeAvailableParticipants(participants: participants, for: nil))
        continue
      }

      dayActivities[index].share = DayActivityShare(
        invitationId: nil,
        isOwner: share.isCurrentUserOwner == true,
        participants: makeDayActivityParticipant(from: sharedDayActivity, share: share),
        availableParticipants: makeAvailableParticipants(participants: participants, for: sharedDayActivity)
      )
    }
  }

  private func updateDayActivitiesWithInvitations(
    _ dayActivities: inout [DayActivity],
    date: Date
  ) async throws {
    guard let userRecordName = await cloudService.userRecordName else { return }
    let invitationSharedDayActivities = try await dayActivityRepository.sharedDayActivities(
      configuration: ActivitiesFetchConfiguration(
        range: date...date,
        predicates: [
          NSPredicate(format: "SUBQUERY(sharedBy, $s, $s.userIdentifier == %@ AND $s.objectIdentifier == '').@count > 0", userRecordName)
        ]
      ),
    )
    print("[INVITATIONS] - \(invitationSharedDayActivities)")

    for sharedDayActivity in invitationSharedDayActivities {
      guard let share = try await cloudService.allShares().first(where: { $0.sharedDayActivities.contains { $0.id == sharedDayActivity.id } }) else {
        continue
      }
      var dayActivity = DayActivity(uuid: uuid, sharedDayActivity: sharedDayActivity)
      dayActivity.share = DayActivityShare(
        invitationId: sharedDayActivity.id.uuidString,
        isOwner: false,
        participants: makeDayActivityParticipant(from: sharedDayActivity, share: share),
        availableParticipants: []
      )
      dayActivities.append(dayActivity)
    }
  }

  private func makeDayActivityParticipant(
    from sharedDayActivity: SharedDayActivity,
    share: Share
  ) -> [DayActivityParticipant] {
    sharedDayActivity.sharedBy.compactMap { sharedBy in
      guard let participant = share.participants.first(where: { $0.recordName == sharedBy.userId }),
            !participant.isCurrentUser else {
        return nil
      }

      return DayActivityParticipant(
        id: participant.id,
        userRecordName: sharedBy.userId,
        name: participant.name + " " + participant.email,
        isOwner: participant.isOwner,
        isShared: true
      )
    }
  }

  private func makeAvailableParticipants(participants: [Participant], for sharedDayActivity: SharedDayActivity?) -> [DayActivityParticipant] {
    participants.compactMap { participant in
      guard let userRecordName = participant.recordName, !participant.isCurrentUser else { return nil }
      return DayActivityParticipant(
        id: participant.id,
        userRecordName: userRecordName,
        name: participant.name + " " + participant.email,
        isOwner: participant.isOwner,
        isShared: sharedDayActivity?.sharedBy.isShared(by: userRecordName) ?? false
      )
    }
  }
}
