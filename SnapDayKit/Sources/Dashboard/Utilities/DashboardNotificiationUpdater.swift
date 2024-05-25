import Foundation
import Models
import Utilities
import Dependencies
import Combine

final class DashboardNotificiationUpdater {

  // MARK: - Properties

  var userActionStream: AsyncPublisher<AnyPublisher<Void, Never>> {
    userNotificationCenterProvider.userActionStream
  }
  @Dependency(\.userNotificationCenterProvider) private var userNotificationCenterProvider
  @Dependency(\.date) private var date
  @Dependency(\.calendar) private var calendar

  // MARK: - Initialization

  init() { }

  // MARK: - Public

  func onAppear() async throws {
    try await userNotificationCenterProvider.schedule(
      userNotification: EveningSummary(
        calendar: calendar,
        date: date.now
      )
    )
  }

  func onMerged(_ appliedChanges: AppliedChanges) async throws {
    for notification in appliedChanges.notifications.eraseToAny {
      try await userNotificationCenterProvider.schedule(userNotification: notification)
    }
  }

  func onActivityCreated(_ dayActivity: DayActivity) async throws {
    try await scheduledNotification(dayActivity)
  }

  func onActivityTaskCreated(_ dayActivityTask: DayActivityTask) async throws {
    try await scheduledNotification(dayActivityTask)
  }

  func onActivityUpdated(_ dayActivity: DayActivity, dayActivityBeforeUpdate: DayActivity?) async throws {
    await removeScheduledNotification(dayActivityBeforeUpdate)
    try await scheduledNotification(dayActivity)
  }

  func onActivityTaskUpdated(_ dayActivityTask: DayActivityTask, dayActivityTaskBeforeUpdate: DayActivityTask?) async throws {
    await removeScheduledNotification(dayActivityTaskBeforeUpdate)
    try await scheduledNotification(dayActivityTask)
  }

  func onActivityRemoved(_ dayActivity: DayActivity) async throws {
    await removeScheduledNotification(dayActivity)
  }

  func onActivityTaskRemoved(_ dayActivityTask: DayActivityTask) async throws {
    await removeScheduledNotification(dayActivityTask)
  }

  // MARK: - Private

  private func scheduledNotification(_ dayActivity: DayActivity) async throws {
    if let reminderDate = dayActivity.reminderDate, reminderDate > date.now {
      try await userNotificationCenterProvider.schedule(
        userNotification: DayActivityNotification(
          type: .activity(dayActivity),
          calendar: calendar
        )
      )
    }
    for task in dayActivity.dayActivityTasks {
      try await scheduledNotification(task)
    }
  }

  private func scheduledNotification(_ dayActivityTask: DayActivityTask) async throws {
    guard let reminderDate = dayActivityTask.reminderDate, reminderDate > date.now else { return }
    try await userNotificationCenterProvider.schedule(
      userNotification: DayActivityNotification(
        type: .activityTask(dayActivityTask),
        calendar: calendar
      )
    )
  }

  private func removeScheduledNotification(_ dayActivity: DayActivity?) async {
    guard let dayActivity else { return }

    await userNotificationCenterProvider.remove(
      userNotification: DayActivityNotification(
        type: .activity(dayActivity),
        calendar: calendar
      )
    )

    for task in dayActivity.dayActivityTasks {
      await userNotificationCenterProvider.remove(
        userNotification: DayActivityNotification(
          type: .activityTask(task),
          calendar: calendar
        )
      )
    }
  }

  private func removeScheduledNotification(_ dayActivityTask: DayActivityTask?) async {
    guard let dayActivityTask else { return }

    await userNotificationCenterProvider.remove(
      userNotification: DayActivityNotification(
        type: .activityTask(dayActivityTask),
        calendar: calendar
      )
    )
  }
}
