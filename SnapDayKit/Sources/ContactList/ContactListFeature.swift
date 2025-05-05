import Foundation
import ComposableArchitecture
import Repositories
import Utilities
import Models
import Common

@Reducer
public struct ContactListFeature: TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.dismiss) private var dismiss
  @Dependency(\.contactsProvider) private var contactsProvider

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable, TodayProvidable {

    var contacts = [Contact]()
    var contactViewType: ContactViewType = .allowButton

    public init() { }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case inviteTapped(Contact)
      case showContactsTapped
      case changedPreferedContact(Contact, String)
    }
    public enum InternalAction: Equatable {
      case loadContacts
      case setContacts([Contact])
      case determineContactsPermissions
    }
    public enum DelegateAction: Equatable {
      case contactSelected(Contact)
      case contactsLoaded([Contact])
    }

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
      return .send(.internal(.determineContactsPermissions))
    case .showContactsTapped:
      return .send(.internal(.loadContacts))
    case .inviteTapped(let contact):
      return .run { send in
        await send(.delegate(.contactSelected(contact)))
        await dismiss()
      }
    case .changedPreferedContact(var contact, let value):
      guard let index = state.contacts.firstIndex(where: { $0.id == contact.id }) else { return .none }
      contact.preferredContact = value
      state.contacts[index] = contact
      return .none
    }
  }

  private func handleInternalAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .setContacts(let contants):
      state.contacts = contants
        .sorted(by: { $0.name < $1.name })
      return .send(.delegate(.contactsLoaded(state.contacts)))
    case .determineContactsPermissions:
      state.contactViewType = switch contactsProvider.state {
      case .allowed:
          .list
      case .notAllowed:
          .daniedInformation
      case .notDetermined:
          .allowButton
      }
      let shouldLoadList = state.contactViewType == .list
      return shouldLoadList
      ? .send(.internal(.loadContacts))
      : .none
    case .loadContacts:
      return .run { send in
        let contacts = try contactsProvider.loadContacts()
        await send(.internal(.setContacts(contacts)))
        await send(.internal(.determineContactsPermissions))
      }
    }
  }
}
