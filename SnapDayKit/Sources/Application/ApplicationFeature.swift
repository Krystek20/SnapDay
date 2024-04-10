import Dashboard
import Reports
import ComposableArchitecture

@Reducer
public struct ApplicationFeature: Reducer {

  // MARK: - State & Action

  public struct State: Equatable {
    var dashboard = DashboardFeature.State()
    var path = StackState<Path.State>()

    public init() { }
  }

  public enum Action: Equatable {
    case dashboard(DashboardFeature.Action)
    case path(StackAction<Path.State, Path.Action>)
  }

  public struct Path: Reducer {
    public enum State: Equatable {
      case reports(ReportsFeature.State)
    }

    public enum Action: Equatable {
      case reports(ReportsFeature.Action)
    }

    public var body: some ReducerOf<Self> {
      Scope(state: /State.reports, action: /Action.reports) {
        ReportsFeature()
      }
    }
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Scope(state: \.dashboard, action: \.dashboard) {
      DashboardFeature()
    }

    Reduce { state, action in
      switch action {
      case .dashboard(.delegate(let action)):
        return handleDashboardDelegate(action: action, state: &state)
      case .dashboard:
        return .none
      case .path:
        return .none
      }
    }
    .forEach(\.path, action: \.path) {
      Path()
    }
  }

  // MARK: - Private

  private func handleDashboardDelegate(
    action: DashboardFeature.Action.DelegateAction,
    state: inout ApplicationFeature.State
  ) -> EffectOf<Self> {
    switch action {
    case .reportsTapped:
      state.path.append(
        .reports(ReportsFeature.State())
      )
      return .none
    }
  }
}
