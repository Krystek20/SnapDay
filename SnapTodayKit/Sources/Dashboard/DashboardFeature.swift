import ComposableArchitecture

public struct DashboardFeature: Reducer {

  // MARK: - State & Action

  public struct State: Equatable {
    public init() { }
  }

  public enum Action: Equatable {
    case startGameTapped
    case delegate(Delegate)
  }

  public enum Delegate: Equatable {
    case startGameTapped
  }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .startGameTapped:
        return .run { send in
          await send(.delegate(.startGameTapped))
        }
      case .delegate:
        return .none
      }
    }
  }

  // MARK: - Initialization

  public init() { }
}
