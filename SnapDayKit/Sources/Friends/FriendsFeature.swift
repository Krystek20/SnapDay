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
    var participants: [Participant] = []
    var isSharing: Bool = false
    var shareResult: ShareResult?
    var content: ViewContent = .loading
    var focus: FriendsField?
    var removing = [Participant]()
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
      case reinviteButtonTapped(Participant)
      case removeButtonTapped(Participant)
    }
    public enum InternalAction: Equatable {
      case loadParticipants
      case setParticipants([Participant])
      case loadContactsIfAllowed
      case updateParticipantsWithContants(contacts: [Contact])
      case invite(String, String)
      case shareUrl(ShareResult)
      case cancelAdding
      case setViewContent(ViewContent)
      case setRemoving(Participant, Bool)
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
    case .contactsSelected(let contants):
      print(contants)
      return .none
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
    case .removeButtonTapped(let participant):
      return .run { send in
        await send(.internal(.setRemoving(participant, true)))
        await send(.internal(.loadParticipants))
        switch participant.type {
        case .invited:
          try await cloudService.removeParticipantFromInvited(participant)
        case .invitee:
          try await cloudService.stopParticipating(participant)
        case .none:
          return
        }
        await send(.internal(.setRemoving(participant, false)))
        await send(.internal(.loadParticipants))
      }
    }
  }

  private func handleInternalAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .loadParticipants:
      return .run { send in
        let participants = try await cloudService.participants()
        await send(.internal(.setParticipants(participants)))
        await send(.internal(.loadContactsIfAllowed))
      }
    case .setParticipants(let participants):
      state.participants = participants
        .filter { !state.removing.contains($0) }

      if state.content == .form {
        return .none
      } else {
        let content: ViewContent = state.participants.isEmpty ? .empty : .list
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
      for (index, participant) in state.participants.enumerated() {
        guard participant.name.isEmpty else { continue }
        var participant = participant
        let foundContact = contacts.first(where: { contact in
          let emailExist = contact.emails.contains(where: { email in
            email.lowercased().contains(participant.email.lowercased())
          })
          let phoneNumberExist = contact.phoneNumbers.contains(where: { phoneNumber in
            let phoneNumberTrimmed = phoneNumber
              .trimmingCharacters(in: .whitespacesAndNewlines)
              .replacingOccurrences(of: " ", with: "")
            let participantPhoneNumberTrimmed = participant
              .phoneNumber
              .trimmingCharacters(in: .whitespacesAndNewlines)
              .replacingOccurrences(of: " ", with: "")
            return phoneNumberTrimmed.contains(participantPhoneNumberTrimmed)
          })
          return emailExist || phoneNumberExist
        })
        guard let foundContact else { continue }
        participant.updateName(foundContact.name)
        state.participants[index] = participant
      }
      return .none
    case .invite(let email, let phoneNumber):
      return .run { send in
        await send(.internal(.setViewContent(.appending)))
        let byEmail = !email.isEmpty
        let byPhone = !phoneNumber.isEmpty
        if byEmail {
          guard let url = try await cloudService.addParticipant(toEmailAddress: email) else {
            await send(.internal(.loadParticipants))
            return
          }
          await send(.internal(.shareUrl(url)))
        } else if byPhone {
          guard let url = try await cloudService.addParticipant(toPhoneNumber: phoneNumber) else {
            await send(.internal(.loadParticipants))
            return
          }
          await send(.internal(.shareUrl(url)))
        }
        await send(.internal(.loadParticipants))
      }
    case .shareUrl(let shareResult):
      state.shareResult = shareResult
      state.isSharing = true
      return .none
    case .setViewContent(let value):
      state.content = value
      return .none
    case .setRemoving(let participant, let add):
      add
      ? state.removing.append(participant)
      : state.removing.removeAll(where: { $0 == participant })
      return .none
    case .cancelAdding:
      state.content = state.participants.isEmpty ? .empty : .list
      state.focus = nil
      state.contact = ""
      return .none
    }
  }

//  private func handleContactListAction(_ action: PresentationAction<ContactListFeature.Action>, state: inout State) -> Effect<Action> {
//    switch action {
//    case .presented(.delegate(.contactSelected(let contact))):
//      let value = contact.preferredContact
//      let byEmail = contact.emails.contains(value)
//      let byPhone = contact.phoneNumbers.contains(value)
//      guard byEmail || byPhone else { return .none }
//      return .send(.internal(.invite(byEmail ? value : "", byPhone ? value : "")))
//    case .presented(.delegate(.contactsLoaded(let contacts))):
//      return .send(.internal(.updateParticipantsWithContants(contacts: contacts)))
//    default:
//      return .none
//    }
//  }
}
