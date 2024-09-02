import Foundation
import UserNotifications

public enum DayActivityNotificationKey: String {
  case identifier
  case kind
}

public enum DayActivityNotificationKind: String {
  case activity
  case activityTask
}

public enum ActivityNotificationType: Equatable {
  case activity(DayActivity)
  case activityTask(DayActivity, DayActivityTask)
}

public struct DayActivityNotification: UserNotification {

  // MARK: - Properties

  private let type: ActivityNotificationType
  private let calendar: Calendar
  private let shiftDay: Int

  public var identifier: String {
    let identifier = switch type {
    case .activity(let dayActivity):
      dayActivity.id.uuidString
    case .activityTask(_, let dayActivityTask):
      dayActivityTask.id.uuidString
    }
    return notificationIdentifierPrefix + identifier + "_\(shiftDay)"
  }

  public var canBySchedule: Bool {
    switch type {
    case .activity(let dayActivity):
      dayActivity.reminderDate != nil
    case .activityTask(_, let dayActivityTask):
      dayActivityTask.reminderDate != nil
    }
  }

  public var content: UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    content.categoryIdentifier = UserNotificationCategoryIdentifier.dayActivityReminder.rawValue
    content.sound = .default
    content.title = name
    content.body = "Hey there! Just a gentle nudge to tackle your planned activity today. You’ve got this!"
    content.userInfo = userInfo
    return content
  }

  public var trigger: UNCalendarNotificationTrigger? {
    guard let reminderDate else { return nil }
    let date = calendar.date(byAdding: .day, value: shiftDay, to: reminderDate) ?? reminderDate
    let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
  }

  private var name: String {
    switch type {
    case .activity(let dayActivity):
      dayActivity.name
    case .activityTask(let dayActivity, let dayActivityTask):
      dayActivity.name + " - " + dayActivityTask.name
    }
  }

  private var reminderDate: Date? {
    switch type {
    case .activity(let dayActivity):
      dayActivity.reminderDate
    case .activityTask(_, let dayActivityTask):
      dayActivityTask.reminderDate
    }
  }

  private var userInfo: [AnyHashable: Any] {
    switch type {
    case .activity(let dayActivity):
      [
        DayActivityNotificationKey.identifier.rawValue: dayActivity.id.uuidString,
        DayActivityNotificationKey.kind.rawValue: DayActivityNotificationKind.activity.rawValue
      ]
    case .activityTask(_, let dayActivityTask):
      [
        DayActivityNotificationKey.identifier.rawValue: dayActivityTask.id.uuidString,
        DayActivityNotificationKey.kind.rawValue: DayActivityNotificationKind.activityTask.rawValue
      ]
    }
  }

  // MARK: - Initialization

  public init(
    type: ActivityNotificationType,
    calendar: Calendar,
    shiftDay: Int = .zero
  ) {
    self.type = type
    self.calendar = calendar
    self.shiftDay = shiftDay
  }
}
