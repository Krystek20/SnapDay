import Foundation
import Models

public struct AppliedChanges: Equatable {
  public enum ChangedNotificationType: Equatable {
    case dayActivity(DayActivityNotification)
  }

  public let dates: [Date]
  public let notifications: [ChangedNotificationType]
}

extension [AppliedChanges.ChangedNotificationType] {
  public var eraseToAny: [any UserNotification] {
    map { notification in
      switch notification {
      case .dayActivity(let notification):
        notification
      }
    }
  }
}
