public struct DayActivityParticipant: Identifiable, Equatable, Hashable {
  public let id: String
  public let userRecordName: String
  public let name: String
  public let isOwner: Bool
  public let isShared: Bool

  public init(
    id: String,
    userRecordName: String,
    name: String,
    isOwner: Bool,
    isShared: Bool
  ) {
    self.id = id
    self.userRecordName = userRecordName
    self.name = name
    self.isOwner = isOwner
    self.isShared = isShared
  }
}
