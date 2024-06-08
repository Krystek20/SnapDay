import Models
import UserNotifications

public struct DeveloperNotificiation: UserNotification {

  public var identifier: String
  public var content: UNMutableNotificationContent
  public var trigger: UNCalendarNotificationTrigger?
  public var canBySchedule: Bool

  init(
    identifier: String,
    content: UNMutableNotificationContent
  ) {
    self.identifier = identifier
    self.content = content
    self.trigger = nil
    self.canBySchedule = true
  }
}
