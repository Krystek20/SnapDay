import ComposableArchitecture
import Common
import Models

public struct DayActivityFormFeature: Reducer {

  // MARK: - Dependencies

  @Dependency(\.dismiss) var dismiss

  // MARK: - State & Action

  public struct State: Equatable {
    @BindingState var dayActivity: DayActivity

    public init(dayActivity: DayActivity) {
      self.dayActivity = dayActivity
    }
  }

  public enum Action: BindableAction, FeatureAction, Equatable {
    public enum ViewAction: Equatable {
      case saveButtonTapped
      case deleteButtonTapped
    }
    public enum InternalAction: Equatable { }
    public enum DelegateAction: Equatable {
      case activityDeleted(DayActivity)
      case activityUpdated(DayActivity)
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
      case .view(.saveButtonTapped):
        return .run { [activity = state.dayActivity] send in
          await send(.delegate(.activityUpdated(activity)))
          await dismiss()
        }
      case .view(.deleteButtonTapped):
        return .run { [activity = state.dayActivity] send in
          await send(.delegate(.activityDeleted(activity)))
          await dismiss()
        }
      case .delegate:
        return .none
      case .binding:
        return .none
      }
    }
  }
}
