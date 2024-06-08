import Foundation
import UserNotifications

public struct EveningSummary: UserNotification {

  // MARK: - Properties

  private let calendar: Calendar

  public var identifier: String {
    notificationIdentifierPrefix + "eveningSummary"
  }

  public var canBySchedule: Bool { true }

  public var content: UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    content.categoryIdentifier = UserNotificationCategoryIdentifier.eveningSummary.rawValue
    content.sound = .default
    content.title = "Good Evening!"
    content.body = "Don't forget to review your day and prepare for tomorrow."
    return content
  }

  public var trigger: UNCalendarNotificationTrigger? {
    var dateComponents = DateComponents()
    dateComponents.calendar = calendar
    dateComponents.hour = 21
    dateComponents.minute = 15
    return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
  }

  // MARK: - Initialization

  public init(calendar: Calendar) {
    self.calendar = calendar
  }
}
