import Models
import struct SwiftUI.Color

public struct Collaboration: Identifiable, Equatable {
  public var id: String { participantIds.joined(separator: ";") }
  var participantIds: [String]
  let recordName: String?
  var name: String
  var email: String
  var phoneNumber: String

  var invitedByCurrentUser: Participant.AcceptanceStatus
  var invitedCurrentUser: Participant.AcceptanceStatus

  mutating func updateInvitedByCurrentUser(_ participant: Participant) {
    invitedByCurrentUser = participant.acceptanceStatus
    participantIds.append(participant.id)
  }

  mutating func updateInvitedCurrentUser(_ participant: Participant) {
    invitedCurrentUser = participant.acceptanceStatus
    participantIds.append(participant.id)
  }

  private mutating func updateParticipantInformation(participant: Participant) {
    if name.isEmpty && !participant.name.isEmpty {
      name = participant.name
    }

    if email.isEmpty && !participant.email.isEmpty {
      email = participant.email
    }

    if phoneNumber.isEmpty && !participant.phoneNumber.isEmpty {
      phoneNumber = participant.phoneNumber
    }
  }
}

extension Collaboration {

  var displayName: String {
    if !name.isEmpty {
      name
    } else if !email.isEmpty {
      email
    } else {
      phoneNumber
    }
  }

  var title: String {
    switch status {
    case .pending:
      String(localized: "Invitation sent to \(displayName)", bundle: .module)
    case .boardShared:
      String(localized: "You shared with \(displayName)", bundle: .module)
    case .awaitingMutual:
      String(localized: "\(displayName) shared with you", bundle: .module)
    case .mutual:
      String(localized: "You and \(displayName) are connected", bundle: .module)
    }
  }

  var subtitle: String? {
    guard !name.isEmpty else { return nil }
    return !email.isEmpty ? email : phoneNumber
  }

  var description: String {
    switch status {
    case .pending:
      String(localized: "Waiting for them to accept your invitation.", bundle: .module)
    case .boardShared:
      String(localized: "They accepted your board, but haven’t shared theirs yet.", bundle: .module)
    case .awaitingMutual:
      String(localized: "They shared with you, but you haven’t accepted yet.", bundle: .module)
    case .mutual:
      String(localized: "You’re both sharing boards with each other.", bundle: .module)
    }
  }

  var iconName: String {
    switch status {
    case .pending:
      "paperplane.circle.fill"
    case .boardShared:
      "arrowshape.turn.up.right.circle.fill"
    case .awaitingMutual:
      "envelope.circle.fill"
    case .mutual:
      "person.2.circle.fill"
    }
  }

  var color: Color {
    switch status {
    case .pending:
      .sunburstOrange
    case .boardShared:
      .actionBlue
    case .awaitingMutual:
      .actionBlueLight
    case .mutual:
      .greenSuccess
    }
  }

  private var status: CollaborationStatus {
    switch (invitedByCurrentUser, invitedCurrentUser) {
    case (.pending, _):
        .pending
    case (.accepted, .unknown), (.accepted, .removed):
        .boardShared
    case (_, .pending):
        .awaitingMutual
    case (.accepted, .accepted):
        .mutual
    default:
        .pending
    }
  }
}

fileprivate enum CollaborationStatus {
  case pending // Waiting for other to accept
  case boardShared // Current User share, but don’t see theirs
  case awaitingMutual // They share, but Current User hasn’t accepted
  case mutual // Full 2-way collaboration
}
