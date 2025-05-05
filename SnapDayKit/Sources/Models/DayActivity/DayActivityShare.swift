import Foundation

public struct DayActivityShare: Equatable, Hashable {
  /// invitationId - shared day activity id
  public let invitationId: String?
  public let isOwner: Bool
  public let participants: [DayActivityParticipant]
  public let availableParticipants: [DayActivityParticipant]

  public init(
    invitationId: String?,
    isOwner: Bool,
    participants: [DayActivityParticipant],
    availableParticipants: [DayActivityParticipant]
  ) {
    self.invitationId = invitationId
    self.isOwner = isOwner
    self.participants = participants
      .sorted(by: { $0.name < $1.name })
    self.availableParticipants = availableParticipants
      .sorted(by: { $0.name < $1.name })
  }

  static public func notSharedYet(availableParticipants: [DayActivityParticipant]) -> DayActivityShare {
    DayActivityShare(
      invitationId: nil,
      isOwner: true,
      participants: [],
      availableParticipants: availableParticipants
    )
  }
}
