public enum ParticipantType: Equatable {
  case invited
  case invitee
}

public struct Participant: Equatable, Identifiable {

  public let id: String
  public let recordName: String?
  public let isCurrentUser: Bool
  public let isOwner: Bool
  public private(set) var name: String
  public let email: String
  public let phoneNumber: String
  public let acceptanceStatus: ParticipantAcceptanceStatus
  public let type: ParticipantType?

  public init(
    id: String,
    recordName: String?,
    isCurrentUser: Bool,
    isOwner: Bool,
    name: String,
    email: String,
    phoneNumber: String,
    acceptanceStatus: ParticipantAcceptanceStatus,
    type: ParticipantType? = nil
  ) {
    self.id = id
    self.recordName = recordName
    self.isCurrentUser = isCurrentUser
    self.isOwner = isOwner
    self.name = name
    self.email = email
    self.phoneNumber = phoneNumber
    self.acceptanceStatus = acceptanceStatus
    self.type = type
  }

  public mutating func updateName(_ name: String) {
    self.name = name
  }
}

extension Participant {
  public var value: String {
    !email.isEmpty
    ? email
    : phoneNumber
  }
}

public enum ParticipantAcceptanceStatus: Int, Equatable {
  case unknown = 0
  case pending = 1
  case accepted = 2
  case removed = 3
}
