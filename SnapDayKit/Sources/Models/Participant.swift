public struct Participant: Equatable, Identifiable {

  public enum AcceptanceStatus: Int, Equatable {
    case unknown = 0
    case pending = 1
    case accepted = 2
    case removed = 3
  }

  public let id: String
  public let recordName: String?
  public let isCurrentUser: Bool
  public let isOwner: Bool
  public let name: String
  public let email: String
  public let phoneNumber: String
  public let acceptanceStatus: AcceptanceStatus

  public init(
    id: String,
    recordName: String?,
    isCurrentUser: Bool,
    isOwner: Bool,
    name: String,
    email: String,
    phoneNumber: String,
    acceptanceStatus: AcceptanceStatus
  ) {
    self.id = id
    self.recordName = recordName
    self.isCurrentUser = isCurrentUser
    self.isOwner = isOwner
    self.name = name
    self.email = email
    self.phoneNumber = phoneNumber
    self.acceptanceStatus = acceptanceStatus
  }
}
