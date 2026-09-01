import Foundation
import ComposableArchitecture
import Repositories
import Utilities
import Models
import Common
import Combine
import CloudKit
import Contacts

public enum FriendsField: Hashable {
  case addNew
}

@Reducer
public struct FriendsFeature: TodayProvidable {

  private enum CancelID: Hashable {
    case invitation
    case invitationTimeout
  }

  public enum ViewContent: Hashable, Equatable {
    case noCollaboration
    case form
    case list
    case loading
    case empty
  }

  // MARK: - Dependencies

  @Dependency(\.contactsProvider) private var contactsProvider
  @Dependency(\.cloudService) private var cloudService
  @Dependency(\.dismiss) private var dismiss

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable, TodayProvidable {

    struct InvitationRecipient: Equatable {
      let email: String
      let phoneNumber: String
    }

    var contact: String = ""
    var isAddCollaboratorInviteEnabled: Bool {
      contact.isValidEmail || contact.isValidPhone
    }
    var collaborations: [Collaboration] = []
    var isSharing: Bool = false
    var shareResult: ShareResult?
    var content: ViewContent = .loading
    var focus: FriendsField?
    var removing = [Collaboration]()
    var showContactList = false
    var isGeneratingInvitiation = false
    var invitationAttemptID: UUID?
    var showInvitationError = false
    var hasPremiumAccess: Bool
    var pendingInvitation: [InvitationRecipient]?

    public init(hasPremiumAccess: Bool = false) {
      self.hasPremiumAccess = hasPremiumAccess
    }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case showContactList
      case contactsSelected([CNContact])
      case newButtonTapped
      case inviteButtonTapped
      case cancelButtonTapped
      case reinviteButtonTapped(Collaboration)
      case removeButtonTapped(Collaboration)
    }
    public enum InternalAction: Equatable {
      case loadParticipants
      case setCollaborations([Collaboration])
      case loadContactsIfAllowed
      case updateParticipantsWithContants(contacts: [Contact])
      case invite(String, String)
      case shareUrl(ShareResult, UUID)
      case invitationFailed(UUID)
      case invitationTimedOut(UUID)
      case closeForm
      case setViewContent(ViewContent)
      case setRemoving(Collaboration, Bool)
    }
    public enum DelegateAction: Equatable {
      case premiumAccessRequested
    }

    case binding(BindingAction<State>)

    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
    case premiumAccessGranted
    case premiumEntitlementUpdated(Bool)
  }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        return handleViewAction(viewAction, state: &state)
      case .internal(let internalAction):
        return handleInternalAction(internalAction, state: &state)
      case .binding:
        return .none
      case .delegate:
        return .none
      case .premiumAccessGranted:
        state.hasPremiumAccess = true
        guard let recipients = state.pendingInvitation else { return .none }
        state.pendingInvitation = nil
        return invite(recipients: recipients, state: &state)
      case .premiumEntitlementUpdated(let hasAccess):
        state.hasPremiumAccess = hasAccess
        return .none
      }
    }
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Private

  private func handleViewAction(_ action: Action.ViewAction, state: inout State) -> Effect<Action> {
    switch action {
    case .appeared:
      return .run { send in
          await send(.internal(.setViewContent(.loading)))
          await send(.internal(.loadParticipants))
      }
    case .showContactList:
      state.showContactList = true
      return .none
    case .contactsSelected(let contacts):
      let recipients = contacts.map { contact in
        let email = String(contact.emailAddresses.first?.value ?? "")
        let phoneNumber = contact.phoneNumbers.first?.value.stringValue ?? ""
        return State.InvitationRecipient(email: email, phoneNumber: phoneNumber)
      }
      return requestInvitation(recipients: recipients, state: &state)
    case .newButtonTapped:
      state.content = .form
      state.focus = .addNew
      return .none
    case .inviteButtonTapped:
      return inviteButtonTapped(state: &state)
    case .cancelButtonTapped:
      return .run { send in
        await send(.internal(.closeForm))
        await dismiss()
      }
    case .reinviteButtonTapped(let participant):
      return requestInvitation(
        recipients: [State.InvitationRecipient(
          email: participant.email,
          phoneNumber: participant.phoneNumber
        )],
        state: &state
      )
    case .removeButtonTapped(let collaboration):
      return stopCollaborating(collaboration: collaboration, state: &state)
    }
  }

  private func handleInternalAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .loadParticipants:
      return loadParticipants(state: &state)
    case .setCollaborations(let collaborations):
      state.collaborations = collaborations
        .filter { !state.removing.contains($0) }

      if state.content == .form {
        return .none
      } else {
        let content: ViewContent = state.collaborations.isEmpty ? .noCollaboration : .list
        return .send(.internal(.setViewContent(content)))
      }
    case .loadContactsIfAllowed:
      return .run { send in
        guard contactsProvider.state == .allowed else { return }
        let contacts = try contactsProvider.loadContacts()
        await send(.internal(.updateParticipantsWithContants(contacts: contacts)))
      }
    case .updateParticipantsWithContants(let contacts):
      guard !contacts.isEmpty else { return .none }
      for (index, collaboration) in state.collaborations.enumerated() {
        guard collaboration.name.isEmpty else { continue }
        var collaboration = collaboration
        let foundContact = contacts.first(where: { contact in
          let emailExist = contact.emails.contains(where: { email in
            email.lowercased().contains(collaboration.email.lowercased())
          })
          let phoneNumberExist = contact.phoneNumbers.contains(where: { phoneNumber in
            let phoneNumberTrimmed = phoneNumber
              .trimmingCharacters(in: .whitespacesAndNewlines)
              .replacingOccurrences(of: " ", with: "")
            let participantPhoneNumberTrimmed = collaboration
              .phoneNumber
              .trimmingCharacters(in: .whitespacesAndNewlines)
              .replacingOccurrences(of: " ", with: "")
            return phoneNumberTrimmed.contains(participantPhoneNumberTrimmed)
          })
          return emailExist || phoneNumberExist
        })
        guard let foundContact else { continue }
        collaboration.name = foundContact.name
        state.collaborations[index] = collaboration
      }
      return .none
    case .invite(let email, let phoneNumber):
      return invite(
        recipients: [State.InvitationRecipient(email: email, phoneNumber: phoneNumber)],
        state: &state
      )
    case .shareUrl(let shareResult, let attemptID):
      guard state.invitationAttemptID == attemptID else { return .none }
      state.invitationAttemptID = nil
      state.shareResult = shareResult
      state.isGeneratingInvitiation = false
      state.content = state.collaborations.isEmpty ? .noCollaboration : .list
      state.isSharing = true
      return .cancel(id: CancelID.invitationTimeout)
    case .invitationFailed(let attemptID):
      guard state.invitationAttemptID == attemptID else { return .none }
      state.invitationAttemptID = nil
      state.isGeneratingInvitiation = false
      state.content = state.collaborations.isEmpty ? .noCollaboration : .list
      state.showInvitationError = true
      return .cancel(id: CancelID.invitationTimeout)
    case .invitationTimedOut(let attemptID):
      guard state.invitationAttemptID == attemptID else { return .none }
      let error = NSError(
        domain: "SnapDay.Invitation",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Invitation preparation timed out"]
      )
      Telemetry.capture(error, stage: "timeout")
      state.invitationAttemptID = nil
      state.isGeneratingInvitiation = false
      state.content = state.collaborations.isEmpty ? .noCollaboration : .list
      state.showInvitationError = true
      return .cancel(id: CancelID.invitation)
    case .setViewContent(let value):
      state.content = value
      return .none
    case .setRemoving(let collaboration, let add):
      add
      ? state.removing.append(collaboration)
      : state.removing.removeAll(where: { $0 == collaboration })
      return .none
    case .closeForm:
      let content: ViewContent = state.collaborations.isEmpty
      ? state.isGeneratingInvitiation ? .empty : .noCollaboration
      : .list

      state.content = content
      state.focus = nil
      state.contact = ""
      return .none
    }
  }

  private func loadParticipants(state: inout State) -> Effect<Action> {
    .run { send in
      let shares = try await cloudService.allShares()
      let collaborations = shares.reduce(into: [Collaboration](), { result, share in
        if share.isCurrentUserOwner == true {
          for participant in share.participants where !participant.isCurrentUser {
            let existingIndex = result.firstIndex(where: {
              ($0.recordName != nil && $0.recordName == participant.recordName)
              || (!$0.email.isEmpty && $0.email == participant.email)
              || (!$0.phoneNumber.isEmpty && $0.phoneNumber == participant.phoneNumber)
            })
            if let existingIndex {
              result[existingIndex].updateInvitedByCurrentUser(participant)
            } else {
              let collaboration = Collaboration(
                participantIds: [participant.id],
                recordName: participant.recordName,
                name: participant.name,
                email: participant.email,
                phoneNumber: participant.phoneNumber,
                invitedByCurrentUser: participant.acceptanceStatus,
                invitedCurrentUser: .unknown
              )
              result.append(collaboration)
            }
          }
        } else {
          for participant in share.participants where participant.isOwner {
            let existingIndex = result.firstIndex(where: {
              ($0.recordName != nil && $0.recordName == participant.recordName)
              || (!$0.email.isEmpty && $0.email == participant.email)
              || (!$0.phoneNumber.isEmpty && $0.phoneNumber == participant.phoneNumber)
            })
            if let existingIndex {
              result[existingIndex].updateInvitedCurrentUser(participant)
            } else {
              let collaboration = Collaboration(
                participantIds: [participant.id],
                recordName: participant.recordName,
                name: participant.name,
                email: participant.email,
                phoneNumber: participant.phoneNumber,
                invitedByCurrentUser: .unknown,
                invitedCurrentUser: participant.acceptanceStatus
              )
              result.append(collaboration)
            }
          }
        }
      })

      await send(.internal(.setCollaborations(collaborations)))
      await send(.internal(.loadContactsIfAllowed))
    }
  }

  private func requestInvitation(
    recipients: [State.InvitationRecipient],
    state: inout State
  ) -> Effect<Action> {
    guard state.hasPremiumAccess else {
      state.pendingInvitation = recipients
      return .send(.delegate(.premiumAccessRequested))
    }
    state.pendingInvitation = nil
    return invite(recipients: recipients, state: &state)
  }

  private func invite(
    recipients: [State.InvitationRecipient],
    state: inout State
  ) -> Effect<Action> {
    guard state.invitationAttemptID == nil else {
      Telemetry.breadcrumb("duplicate_attempt_ignored")
      return .none
    }

    let attemptID = UUID()
    state.invitationAttemptID = attemptID
    state.isGeneratingInvitiation = true
    state.showInvitationError = false
    Telemetry.breadcrumb("ui_started", data: ["recipient_count": recipients.count])

    let invitation = Effect<Action>.run { send in
      await send(.internal(.closeForm))

      do {
        var shareResult: ShareResult?
        for recipient in recipients {
          let byEmail = !recipient.email.isEmpty
          let byPhone = !recipient.phoneNumber.isEmpty
          if byEmail {
            shareResult = try await cloudService.addParticipant(toEmailAddress: recipient.email)
          } else if byPhone {
            shareResult = try await cloudService.addParticipant(toPhoneNumber: recipient.phoneNumber)
          }
        }

        guard let shareResult else {
          return await send(.internal(.invitationFailed(attemptID)))
        }
        await send(.internal(.shareUrl(shareResult, attemptID)))
        await send(.internal(.loadParticipants))
      } catch {
        NSLog("[FriendsFeature] Invitation creation failed: \(error)")
        await send(.internal(.invitationFailed(attemptID)))
      }
    }
    .cancellable(id: CancelID.invitation, cancelInFlight: true)

    let timeout = Effect<Action>.run { send in
      try await Task.sleep(for: .seconds(30))
      await send(.internal(.invitationTimedOut(attemptID)))
    }
    .cancellable(id: CancelID.invitationTimeout, cancelInFlight: true)

    return .merge(invitation, timeout)
  }

  private func inviteButtonTapped(state: inout State) -> Effect<Action> {
    let value = state.contact
    let byEmail = value.isValidEmail
    let byPhone = value.isValidPhone
    guard byEmail || byPhone else { return .none }
    return requestInvitation(
      recipients: [State.InvitationRecipient(
        email: byEmail ? value : "",
        phoneNumber: byPhone ? value : ""
      )],
      state: &state
    )
  }

  private func stopCollaborating(collaboration: Collaboration, state: inout State) -> Effect<Action> {
    return .run { send in
      await send(.internal(.setRemoving(collaboration, true)))
      await send(.internal(.loadParticipants))
      try await cloudService.removeParticipantFromInvited(collaboration.participantIds)
      if let recordName = collaboration.recordName {
        try await cloudService.stopParticipating(recordName)
      }
      await send(.internal(.setRemoving(collaboration, false)))
      await send(.internal(.loadParticipants))
    }
  }
}
