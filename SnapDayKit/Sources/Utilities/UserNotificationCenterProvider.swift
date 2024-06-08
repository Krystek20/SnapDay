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
}

extension UNUserNotificationCenter: UserNotificationCenter { }

public final class UserNotificationCenterProvider: NSObject, TodayProvidable {

  private enum UserAction: String {
    case done = "DONE_ACTION"
    case remindInHour = "REMIND_IN_HOUR_ACTION"
  }

  // MARK: - Properties

  public var userActionStream: AsyncPublisher<AnyPublisher<Void, Never>> {
    userActionSubject.eraseToAnyPublisher().values
  }

  private var userNotificationCenter: UserNotificationCenter
  private let userActionSubject = PassthroughSubject<Void, Never>()

  @Dependency(\.userNotificationCenterProvider) private var userNotificationCenterProvider
  @Dependency(\.dayActivityRepository) private var dayActivityRepository
  @Dependency(\.calendar) private var calendar
  @Dependency(\.date) private var date

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

  public func registerCategories() {
    let eveningSummaryCategory = UNNotificationCategory(
      identifier: UserNotificationCategoryIdentifier.eveningSummary.rawValue,
      actions: [],
      intentIdentifiers: []
    )
    let doneAction = UNNotificationAction(
      identifier: UserAction.done.rawValue,
      title: "Mark as done",
      options: []
    )
    let remindInHourAction = UNNotificationAction(
      identifier: UserAction.remindInHour.rawValue,
      title: "Remind me in 30 minutes",
      options: []
    )
    let dayActivityReminderCategory = UNNotificationCategory(
      identifier: UserNotificationCategoryIdentifier.dayActivityReminder.rawValue,
      actions: [remindInHourAction, doneAction],
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

    let dayActivities = try await dayActivityRepository.activities(today...tomorrow)
    for dayActivity in dayActivities {
      if let reminderDate = dayActivity.reminderDate, reminderDate > date.now {
        try await schedule(
          userNotification: DayActivityNotification(
            type: .activity(dayActivity),
            calendar: calendar
          )
        )
      }
      for dayActivityTask in dayActivity.dayActivityTasks {
        guard let reminderDate = dayActivityTask.reminderDate, reminderDate > date.now else { continue }
        try await userNotificationCenterProvider.schedule(
          userNotification: DayActivityNotification(
            type: .activityTask(dayActivityTask),
            calendar: calendar
          )
        )
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
          guard var dayActivity = try await dayActivityRepository.activity(identifier) else { return }
          dayActivity.doneDate = dayActivity.doneDate == nil ? date() : nil
          try await dayActivityRepository.saveActivity(dayActivity)
          userActionSubject.send()
        case .activityTask:
          guard var dayActivityTask = try await dayActivityRepository.activityTask(identifier) else { return }
          dayActivityTask.doneDate = dayActivityTask.doneDate == nil ? date() : nil
          try await dayActivityRepository.saveActivityTask(dayActivityTask)
          userActionSubject.send()
        }
      case .remindInHour:
        var notification: (any UserNotification)?
        switch kind {
        case .activity:
          guard var dayActivity = try await dayActivityRepository.activity(identifier),
                let reminderDate = dayActivity.reminderDate else { return }
          dayActivity.reminderDate = calendar.date(byAdding: .minute, value: 30, to: reminderDate)
          try await dayActivityRepository.saveActivity(dayActivity)
          notification = DayActivityNotification(type: .activity(dayActivity), calendar: calendar)
        case .activityTask:
          guard var dayActivityTask = try await dayActivityRepository.activityTask(identifier),
                let reminderDate = dayActivityTask.reminderDate else { return }
          dayActivityTask.reminderDate = calendar.date(byAdding: .minute, value: 30, to: reminderDate)
          try await dayActivityRepository.saveActivityTask(dayActivityTask)
          notification = DayActivityNotification(type: .activityTask(dayActivityTask), calendar: calendar)
        }
        guard let notification else { return }
        await remove(userNotification: notification)
        try await schedule(userNotification: notification)
        userActionSubject.send()
      }
    } catch {
      print(error)
    }
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
