import CloudKit
import Models

extension Participant {
  init(
    _ participant: CKShare.Participant,
    currentUser: CKShare.Participant?
  ) {
    self.init(
      id: participant.participantID,
      recordName: participant.userIdentity.userRecordID?.recordName,
      isCurrentUser: participant == currentUser,
      isOwner: participant.role == .owner,
      name: participant.name,
      email: participant.userIdentity.lookupInfo?.emailAddress ?? "",
      phoneNumber: participant.userIdentity.lookupInfo?.phoneNumber ?? "",
      acceptanceStatus: AcceptanceStatus(rawValue: participant.acceptanceStatus.rawValue) ?? .unknown
    )
  }
}

extension CKShare.Participant {
  var name: String {
    let givenName = userIdentity.nameComponents?.givenName ?? ""
    let familyName = userIdentity.nameComponents?.familyName ?? ""
    return switch (givenName.isEmpty, familyName.isEmpty) {
    case (true, true):
      ""
    case (true, false):
      familyName
    case (false, true):
      givenName
    case (false, false):
      givenName + " " + familyName
    }
  }
}

//extension Participant.InvitationState {
//  init(acceptanceStatus: CKShare.ParticipantAcceptanceStatus) {
//    switch acceptanceStatus {
//    case .unknown:
//      self = .none
//    case .pending:
//      self = .pending
//    case .accepted:
//      self = .accepted
//    case .removed:
//      self = .none
//    @unknown default:
//      self = .none
//    }
//  }
//}
