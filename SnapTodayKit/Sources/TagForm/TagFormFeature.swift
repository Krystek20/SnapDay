import ComposableArchitecture
import Repositories
import Models
import Common

public struct TagFormFeature: Reducer {

  // MARK: - Dependencies

  @Dependency(\.tagRepository.saveTag) var saveTag
  @Dependency(\.dismiss) var dismiss

  // MARK: - State & Action

  public struct State: Equatable {
    @BindingState var tag: Tag

    public init(tag: Tag) {
      self.tag = tag
    }
  }

  public enum Action: BindableAction, FeatureAction, Equatable {

    public enum ViewAction: Equatable {
      case saveButtonTapped
    }
    public enum InternalAction: Equatable { }
    public enum DelegateAction: Equatable {
      case tagCreated(Tag)
    }

    case binding(BindingAction<State>)
    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case .view(.saveButtonTapped):
        return .run { [tag = state.tag] send in
          try await saveTag(tag)
          await send(.delegate(.tagCreated(tag)))
          await dismiss()
        }
      case .delegate:
        return .none
      }
    }
  }
}
