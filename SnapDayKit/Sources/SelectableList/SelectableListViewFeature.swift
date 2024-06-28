import ComposableArchitecture
import Repositories
import Models
import Common

@Reducer
public struct SelectableListViewFeature {

  // MARK: - Dependencies

  @Dependency(\.dismiss) var dismiss

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {
    let title: String
    let selectedItem: Item?
    let items: [Item]
    let listId: String
    let isClearVisible: Bool

    var itemsToDisplay: [Item] {
      items.sorted(by: { $0.name < $1.name })
    }

    public init(
      title: String,
      selectedItem: Item?,
      items: [Item],
      listId: String,
      isClearVisible: Bool
    ) {
      self.title = title
      self.selectedItem = selectedItem
      self.items = items
      self.listId = listId
      self.isClearVisible = isClearVisible
    }
  }

  public enum Action: FeatureAction, Equatable {

    public enum ViewAction: Equatable {
      case selected(Item)
      case clearTapped
    }
    public enum InternalAction: Equatable { }

    @CasePathable
    public enum DelegateAction: Equatable {
      case selected(Item?, String)
    }

    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .view(.selected(let item)):
        return .run { [listId = state.listId] send in
          await send(.delegate(.selected(item, listId)))
          await dismiss()
        }
      case .view(.clearTapped):
        return .run { [listId = state.listId] send in
          await send(.delegate(.selected(nil, listId)))
          await dismiss()
        }
      case .delegate:
        return .none
      }
    }
  }
}
