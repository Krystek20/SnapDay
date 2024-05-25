import UserNotifications

private let identifierPrefix = "com.mobilove.snapday.notification."

public protocol UserNotification: Equatable {
  var identifier: String { get }
  var content: UNMutableNotificationContent { get }
  var trigger: UNCalendarNotificationTrigger? { get }
  var canBySchedule: Bool { get }
}

public extension UserNotification {
  var notificationIdentifierPrefix: String { identifierPrefix }
}

public enum UserNotificationCategoryIdentifier: String {
  case eveningSummary = "EVENING_SUMMARY"
  case dayActivityReminder = "DAY_ACTIVITY_REMINDER"
}
