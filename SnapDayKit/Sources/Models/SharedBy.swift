import Foundation

public enum ByAction {
  case none
  case update
  case remove
}

public struct SharedBy: Equatable, Hashable {
  public let identifier: String
  public let userId: String
  public let objectId: String
  public var action: ByAction

  public init(
    identifier: String,
    userId: String,
    objectId: String = "",
    action: ByAction = .none
  ) {
    self.identifier = identifier
    self.userId = userId
    self.objectId = objectId
    self.action = action
  }
}

public extension [SharedBy] {
  func isShared(by userRecordName: String) -> Bool {
    contains(where: { $0.userId == userRecordName })
  }

  func isShared(objectId: String) -> Bool {
    contains(where: { $0.objectId == objectId })
  }
}
