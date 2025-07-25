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

  public enum ViewContent: Hashable, Equatable {
    case empty
    case form
    case list
    case loading
    case appending
  }

  // MARK: - Dependencies

  @Dependency(\.contactsProvider) private var contactsProvider
  @Dependency(\.cloudService) private var cloudService

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable, TodayProvidable {

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

    public init() { }
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
      case shareUrl(ShareResult)
      case cancelAdding
      case setViewContent(ViewContent)
      case setRemoving(Collaboration, Bool)
    }
    public enum DelegateAction: Equatable { }

    case binding(BindingAction<State>)

    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
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
      let contactsForms = contacts.map { contant in
        let email = String(contant.emailAddresses.first?.value ?? "")
        let phoneNumber = contant.phoneNumbers.first?.value.stringValue ?? ""
        return (email, phoneNumber)
      }
      return invite(contacts: contactsForms, state: &state)
    case .newButtonTapped:
      state.content = .form
      state.focus = .addNew
      return .none
    case .inviteButtonTapped:
      let value = state.contact
      let byEmail = value.isValidEmail
      let byPhone = value.isValidPhone
      guard byEmail || byPhone else { return .none }
      return .run { send in
        await send(.internal(.cancelAdding))
        await send(.internal(.invite(byEmail ? value : "", byPhone ? value : "")))
      }
    case .cancelButtonTapped:
      return .send(.internal(.cancelAdding))
    case .reinviteButtonTapped(let participant):
      return .send(.internal(.invite(participant.email, participant.phoneNumber)))
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
        let content: ViewContent = state.collaborations.isEmpty ? .empty : .list
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
      return invite(contacts: [(email, phoneNumber)], state: &state)
    case .shareUrl(let shareResult):
      state.shareResult = shareResult
      state.isSharing = true
      return .none
    case .setViewContent(let value):
      state.content = value
      return .none
    case .setRemoving(let collaboration, let add):
      add
      ? state.removing.append(collaboration)
      : state.removing.removeAll(where: { $0 == collaboration })
      return .none
    case .cancelAdding:
      state.content = state.collaborations.isEmpty ? .empty : .list
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

  private func invite(contacts: [(email: String, phoneNumber: String)], state: inout State) -> Effect<Action> {
    .run { send in
      await send(.internal(.setViewContent(.appending)))

      var shareResult: ShareResult?
      for contact in contacts {
        let byEmail = !contact.email.isEmpty
        let byPhone = !contact.phoneNumber.isEmpty
        if byEmail {
          shareResult = try await cloudService.addParticipant(toEmailAddress: contact.email)
        } else if byPhone {
          shareResult = try await cloudService.addParticipant(toPhoneNumber: contact.phoneNumber)
        }
      }

      guard let shareResult else {
        return await send(.internal(.loadParticipants))
      }
      await send(.internal(.shareUrl(shareResult)))
      await send(.internal(.loadParticipants))
    }
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
