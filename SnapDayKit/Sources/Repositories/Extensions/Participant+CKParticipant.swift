import CloudKit
import Models

extension Participant {
  init(
    _ participant: CKShare.Participant,
    currentUser: CKShare.Participant?,
    type: ParticipantType? = nil
  ) {
    let givenName = participant.userIdentity.nameComponents?.givenName ?? ""
    let familyName = participant.userIdentity.nameComponents?.familyName ?? ""
    let emailAddress = participant.userIdentity.lookupInfo?.emailAddress ?? ""
    let phoneNumber = participant.userIdentity.lookupInfo?.phoneNumber ?? ""
    let name = switch (givenName.isEmpty, familyName.isEmpty) {
    case (true, true):
      ""
    case (true, false):
      familyName
    case (false, true):
      givenName
    case (false, false):
      givenName + " " + familyName
    }

    self.init(
      id: participant.participantID,
      recordName: participant.userIdentity.userRecordID?.recordName,
      isCurrentUser: participant == currentUser,
      isOwner: participant.role == .owner,
      name: name,
      email: emailAddress,
      phoneNumber: phoneNumber,
      acceptanceStatus: ParticipantAcceptanceStatus(rawValue: participant.acceptanceStatus.rawValue) ?? .unknown,
      type: type
    )
  }
}
