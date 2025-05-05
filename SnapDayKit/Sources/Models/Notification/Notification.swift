import Foundation

public enum CloudNotification {

  private enum NotificationType: String {
    case collaborationStarted
  }

  case collaborationStarted(String)

  public init?(userInfo: [AnyHashable: Any]) {
    guard let cloudInfo = userInfo["ck"] as? [String: Any],
          let queryInfo = cloudInfo["qry"] as? [String: Any],
          let rid = queryInfo["rid"] as? String,
          let sid = queryInfo["sid"] as? String,
          let type = NotificationType(rawValue: sid) else {
      return nil
    }
    self = switch type {
    case .collaborationStarted:
        .collaborationStarted(rid)
    }
  }
}
