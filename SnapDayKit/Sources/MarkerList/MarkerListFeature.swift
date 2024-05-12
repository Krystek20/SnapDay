import ComposableArchitecture
import Repositories
import Models
import Common

@Reducer
public struct MarkerListFeature {

  public enum MarkerListType: Equatable {
    case tag(selected: Tag?, available: [Tag])
    case label(selected: ActivityLabel?, available: [ActivityLabel])
  }
  
  public enum MarkerListSelection: Equatable {
    case tag(selected: Tag)
    case label(selected: ActivityLabel)
  }

  // MARK: - Dependencies

  @Dependency(\.dismiss) var dismiss

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {
    let type: MarkerListType

    public init(type: MarkerListType) {
      self.type = type
    }
  }

  public enum Action: BindableAction, FeatureAction, Equatable {

    public enum ViewAction: Equatable {
      case markerSelected(MarkerListSelection)
    }
    public enum InternalAction: Equatable { }

    @CasePathable
    public enum DelegateAction: Equatable {
      case markerSelected(MarkerListSelection)
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
      case .view(.markerSelected(let marker)):
        return .run { send in
          await send(.delegate(.markerSelected(marker)))
          await dismiss()
        }
      case .binding:
        return .none
      case .delegate:
        return .none
      }
    }
  }
}
