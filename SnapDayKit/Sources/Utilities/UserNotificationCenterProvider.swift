import UserNotifications
import Repositories
import Dependencies
import Models
import Combine

public protocol UserNotificationCenter {
  var delegate: (any UNUserNotificationCenterDelegate)? { get set }
  func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
  func add(_ request: UNNotificationRequest) async throws
  func pendingNotificationRequests() async -> [UNNotificationRequest]
  func setNotificationCategories(_ categories: Set<UNNotificationCategory>)
  func removePendingNotificationRequests(withIdentifiers identifiers: [String])
  func notificationSettings() async -> UNNotificationSettings
}

extension UNUserNotificationCenter: UserNotificationCenter { }

public final class UserNotificationCenterProvider: NSObject, TodayProvidable {

  public enum Status {
    case notDetermined
    case denied
    case authorized
  }

  private enum UserAction: String {
    case done = "DONE_ACTION"
    case remindInQuarter = "REMIND_IN_QUARTER_ACTION"
    case remindInHalfHour = "REMIND_IN_HALF_HOUR_ACTION"
    case remindInHour = "REMIND_IN_HOUR_ACTION"
  }

  // MARK: - Properties

  public var status: Status {
    get async {
      let authorizationStatus = await userNotificationCenter.notificationSettings().authorizationStatus
      return switch authorizationStatus {
      case .notDetermined:
          .notDetermined
      case .denied:
          .denied
      case .authorized, .provisional, .ephemeral:
          .authorized
      @unknown default:
          .denied
      }
    }
  }

  public var userActionStream: AsyncPublisher<AnyPublisher<Void, Never>> {
    userActionSubject.eraseToAnyPublisher().values
  }

  private var userNotificationCenter: UserNotificationCenter
  private let userActionSubject = PassthroughSubject<Void, Never>()

  @Dependency(\.userNotificationCenterProvider) private var userNotificationCenterProvider
  @Dependency(\.dayUpdater) private var dayUpdater
  @Dependency(\.calendar) private var calendar
  @Dependency(\.utcCalendar) private var utcCalendar
  @Dependency(\.date) private var date
  @Dependency(\.cloudService) private var cloudService
  @Dependency(\.tokenRepository) private var tokenRepository

  // MARK: - Initialization

  public init(userNotificationCenter: UserNotificationCenter = UNUserNotificationCenter.current()) {
    self.userNotificationCenter = userNotificationCenter
    super.init()
    self.userNotificationCenter.delegate = self
  }

  // MARK: - Public

  public func requestAuthorization() async throws -> Bool {
    try await userNotificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
  }

  public func registerRemoteNotifications(deviceToken: String) async throws {
    guard let userRecordName = await cloudService.userRecordName else {
      print("No user record for regestering: \(deviceToken)")
      return
    }
    try await tokenRepository.registerToken(deviceToken, for: userRecordName)
    print("APNs Device Token: \(deviceToken) for \(userRecordName)")
  }

  public func registerCategories() {
    let eveningSummaryCategory = UNNotificationCategory(
      identifier: UserNotificationCategoryIdentifier.eveningSummary.rawValue,
      actions: [],
      intentIdentifiers: []
    )
    let doneAction = UNNotificationAction(
      identifier: UserAction.done.rawValue,
      title: String(localized: "Mark as done", bundle: .module),
      options: []
    )
    let remindInQuarterAction = UNNotificationAction(
      identifier: UserAction.remindInQuarter.rawValue,
      title: String(localized: "Remind me in 15 minutes", bundle: .module),
      options: []
    )
    let remindInHalfHourAction = UNNotificationAction(
      identifier: UserAction.remindInHalfHour.rawValue,
      title: String(localized: "Remind me in 30 minutes", bundle: .module),
      options: []
    )
    let remindInHourAction = UNNotificationAction(
      identifier: UserAction.remindInHour.rawValue,
      title: String(localized: "Remind me in 60 minutes", bundle: .module),
      options: []
    )
    let dayActivityReminderCategory = UNNotificationCategory(
      identifier: UserNotificationCategoryIdentifier.dayActivityReminder.rawValue,
      actions: [remindInQuarterAction, remindInHalfHourAction, remindInHourAction, doneAction],
      intentIdentifiers: []
    )
    userNotificationCenter.setNotificationCategories([
      eveningSummaryCategory,
      dayActivityReminderCategory
    ])
  }

  public func schedule(userNotification: any UserNotification) async throws {
    let isNotificationScheduled = await userNotificationCenter.pendingNotificationRequests().contains(where: {
      $0.identifier == userNotification.identifier
    })

    if isNotificationScheduled && !userNotification.canBySchedule {
      userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [userNotification.identifier])
    }

    guard !isNotificationScheduled && userNotification.canBySchedule else { return }
    let request = UNNotificationRequest(
      identifier: userNotification.identifier,
      content: userNotification.content,
      trigger: userNotification.trigger
    )
    try await userNotificationCenter.add(request)
  }

  public func remove(userNotification: any UserNotification) async {
    let isNotificationScheduled = await userNotificationCenter.pendingNotificationRequests().contains(where: {
      $0.identifier == userNotification.identifier
    })
    guard isNotificationScheduled else { return }
    userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [userNotification.identifier])
  }
}

extension UserNotificationCenterProvider {
  public func reloadReminders() async throws {
    let pendingRequests = await userNotificationCenter.pendingNotificationRequests()
      .filter { $0.content.categoryIdentifier == UserNotificationCategoryIdentifier.dayActivityReminder.rawValue }
    userNotificationCenter.removePendingNotificationRequests(withIdentifiers: pendingRequests.map(\.identifier))

    let dayActivities = try await dayUpdater.dayActivities(
      configuration: ActivitiesFetchConfiguration(range: today...tomorrow, done: false)
    )

    for dayActivity in dayActivities {
      if let reminderDate = dayActivity.reminderDate {

        var isDueTimeSet = false
        if let dueDate = dayActivity.dueDate, utcCalendar.dayFormat(reminderDate) == today {
          isDueTimeSet = dueDate > today
        }

        let shiftDays = [
          reminderDate > date.now ? 0 : nil,
          isDueTimeSet ? 1 : nil
        ].compactMap { $0 }

        for shiftDay in shiftDays {
          try await schedule(
            userNotification: DayActivityNotification(
              type: .activity(dayActivity),
              calendar: calendar,
              shiftDay: shiftDay,
              bodyTitle: bodyTitle
            )
          )
        }
      }

      for dayActivityTask in dayActivity.dayActivityTasks {
        guard let reminderDate = dayActivityTask.reminderDate else { continue }

        var isDueTimeSet = false
        if let dueDate = dayActivity.dueDate, utcCalendar.dayFormat(reminderDate) == today {
          isDueTimeSet = dueDate > today
        }

        let shiftDays = [
          reminderDate > date.now ? 0 : nil,
          isDueTimeSet ? 1 : nil
        ].compactMap { $0 }

        for shiftDay in shiftDays {
          try await userNotificationCenterProvider.schedule(
            userNotification: DayActivityNotification(
              type: .activityTask(dayActivity, dayActivityTask),
              calendar: calendar,
              shiftDay: shiftDay,
              bodyTitle: bodyTitle
            )
          )
        }
      }
    }
  }
}

#if DEBUG
extension UserNotificationCenterProvider {
  public var pendingRequests: [String] {
    get async {
      await userNotificationCenter.pendingNotificationRequests()
        .map { request in
          let identifier = request.identifier
          guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
             let triggerDate = calendar.nextDate(after: Date(), matching: trigger.dateComponents, matchingPolicy: .nextTime) else {
            return identifier
          }
          return identifier + " | \(triggerDate)"
        }
    }
  }

  public func sendDeveloperMessage(_ message: String) async throws {
    guard UserDefaults.standard.bool(forKey: "backgroundUpdatedNotificationEnabled") else { return }
    let content = UNMutableNotificationContent()
    content.title = "Developer message"
    content.subtitle = message
    content.sound = UNNotificationSound.default
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    try await userNotificationCenter.add(request)
  }
}
#endif

extension UserNotificationCenterProvider: UNUserNotificationCenterDelegate {
  public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
    [.badge, .sound, .banner, .list]
  }

  @MainActor
  public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
    guard let userInfo = response.notification.request.content.userInfo as? [String: String],
          let rawValue = userInfo[DayActivityNotificationKey.kind.rawValue],
          let kind = DayActivityNotificationKind(rawValue: rawValue),
          let identifier = userInfo[DayActivityNotificationKey.identifier.rawValue],
          let userAction = UserAction(rawValue: response.actionIdentifier) else { return }

    do {
      switch userAction {
      case .done:
        switch kind {
        case .activity:
          guard var dayActivity = try await dayUpdater.dayActivity(identifier: identifier) else { return }
          dayActivity.doneDate = dayActivity.doneDate == nil ? date() : nil
          try await dayUpdater.saveDayActivity(dayActivity, syncSharable: true)
          userActionSubject.send()
        case .activityTask:
          guard var dayActivityTask = try await dayUpdater.dayActivityTask(identifier: identifier) else { return }
          dayActivityTask.doneDate = dayActivityTask.doneDate == nil ? date() : nil
          try await dayUpdater.saveDayActivityTask(dayActivityTask, syncSharable: true)
          userActionSubject.send()
        }
      case .remindInQuarter:
        try await remind(identifier: identifier, kind: kind, minutes: 15)
      case .remindInHalfHour:
        try await remind(identifier: identifier, kind: kind, minutes: 30)
      case .remindInHour:
        try await remind(identifier: identifier, kind: kind, minutes: 60)
      }
    } catch {
      print(error)
    }
  }

  private func remind(
    identifier: String,
    kind: DayActivityNotificationKind,
    minutes: Int
  ) async throws {
    var notification: (any UserNotification)?
    switch kind {
    case .activity:
      guard var dayActivity = try await dayUpdater.dayActivity(identifier: identifier) else { return }
      dayActivity.reminderDate = calendar.date(byAdding: .minute, value: minutes, to: date.now)
      try await dayUpdater.saveDayActivity(dayActivity, syncSharable: false)
      notification = DayActivityNotification(
        type: .activity(dayActivity),
        calendar: calendar,
        bodyTitle: bodyTitle
      )
    case .activityTask:
      guard var dayActivityTask = try await dayUpdater.dayActivityTask(identifier: identifier),
            let dayActivity = try await dayUpdater.dayActivity(identifier: dayActivityTask.dayActivityId.uuidString) else { return }
      dayActivityTask.reminderDate = calendar.date(byAdding: .minute, value: minutes, to: date.now)
      try await dayUpdater.saveDayActivityTask(dayActivityTask, syncSharable: false)
      notification = DayActivityNotification(
        type: .activityTask(dayActivity, dayActivityTask),
        calendar: calendar,
        bodyTitle: bodyTitle
      )
    }
    guard let notification else { return }
    await remove(userNotification: notification)
    try await schedule(userNotification: notification)
    userActionSubject.send()
  }
}

fileprivate extension UserNotificationCenterProvider {
  var bodyTitle: String {
    String(localized: "Hey there! Just a gentle nudge to tackle your planned activity today. You’ve got this!", bundle: .module)
  }
}

extension DependencyValues {
  public var userNotificationCenterProvider: UserNotificationCenterProvider {
    get { self[UserNotificationCenterProvider.self] }
    set { self[UserNotificationCenterProvider.self] = newValue }
  }
}

extension UserNotificationCenterProvider: DependencyKey {
  public static var liveValue: UserNotificationCenterProvider {
    UserNotificationCenterProvider()
  }
}
