import ComposableArchitecture

@Reducer
public struct PlansFeature {

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    public init() { }
  }

  public enum Action: Equatable {

    public enum ViewAction: Equatable {
      case appeared
    }

    case view(ViewAction)
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { _, action in
      switch action {
      case .view(.appeared):
        return .none
      }
    }
  }
}
