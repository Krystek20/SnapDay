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

//public enum InvitationState: Equatable {
//  case none
//  case pending
//  case accepted
//}
//
//
//public private(set) var invitedByCurrentUser: InvitationState
//public private(set) var invitedCurrentUser: InvitationState

//public mutating func updateInvitedByCurrentUser(_ state: InvitationState) {
//  self.invitedByCurrentUser = state
//}
//
//public mutating func updateInvitedCurrentUser(_ state: InvitationState) {
//  self.invitedCurrentUser = state
//}

//
//var participant = Participant(ckParticipant, currentUser: ckShare.currentUserParticipant)
//if ckShare.owner == ckShare.currentUserParticipant {
//  let invitationState = Participant.InvitationState(acceptanceStatus: ckParticipant.acceptanceStatus)
//  participant.updateInvitedByCurrentUser(invitationState)
//} else {
//
//}
//
//
//
//if ckShare.owner == ckShare.currentUserParticipant {
//  for ckParticipant in ckShare.participants where ckParticipant != ckShare.currentUserParticipant {
//
//    if let existingParticipantIndex = result.firstIndex(where: { $0.recordName == ckParticipant.userIdentity.userRecordID?.recordName }) {
//      print("PARTICIPANT - invited EXISTING: \(result[existingParticipantIndex].recordName)")
//      result[existingParticipantIndex].updateInvitedByCurrentUser(invitationState)
//    } else {
//
//
//      print("PARTICIPANT - invited: \(participant.recordName)")
//      result.append(participant)
//    }
//  }
//} else {
//  let invitationState = Participant.InvitationState(acceptanceStatus: ckShare.currentUserParticipant?.acceptanceStatus ?? .unknown)
//  if let existingParticipantIndex = result.firstIndex(where: { $0.recordName == ckShare.owner.userIdentity.userRecordID?.recordName }) {
//    print("PARTICIPANT - invitee EXISTING: \(result[existingParticipantIndex].recordName)")
//    result[existingParticipantIndex].updateInvitedCurrentUser(invitationState)
//  } else {
//    var participant = Participant(ckShare.owner, currentUser: ckShare.currentUserParticipant)
//    participant.updateInvitedCurrentUser(invitationState)
//    print("PARTICIPANT - invitee: \(participant.recordName)")
//    result.append(participant)
//  }
//}
