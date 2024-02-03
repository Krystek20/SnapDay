import Dashboard
import TimePeriodDetails
import Details
import ComposableArchitecture

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
      case timePeriodDetails(TimePeriodDetailsFeature.State)
      case details(DetailsFeature.State)
    }

    public enum Action: Equatable {
      case timePeriodDetails(TimePeriodDetailsFeature.Action)
      case details(DetailsFeature.Action)
    }

    public var body: some ReducerOf<Self> {
      Scope(state: /State.timePeriodDetails, action: /Action.timePeriodDetails) {
        TimePeriodDetailsFeature()
      }
      Scope(state: /State.details, action: /Action.details) {
        DetailsFeature()
      }
    }
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Scope(state: \.dashboard, action: /Action.dashboard) {
      DashboardFeature()
    }

    Reduce { state, action in
      switch action {
      case .dashboard(.delegate(let action)):
        return handleDashboardDelegate(action: action, state: &state)
      case .dashboard:
        return .none
      case .path(.element(_, action: .timePeriodDetails(.delegate(let action)))):
        return handleTimePeriodDetailsDelegate(action: action, state: &state)
      case .path:
        return .none
      }
    }
    .forEach(\.path, action: /Action.path) {
      Path()
    }
  }

  // MARK: - Private

  private func handleDashboardDelegate(
    action: DashboardFeature.Action.DelegateAction,
    state: inout ApplicationFeature.State
  ) -> EffectOf<Self> {
    switch action {
    case .timePeriodTapped(let timePeriod):
      state.path.append(
        .timePeriodDetails(TimePeriodDetailsFeature.State(timePeriod: timePeriod))
      )
      return .none
    }
  }

  private func handleTimePeriodDetailsDelegate(
    action: TimePeriodDetailsFeature.Action.DelegateAction,
    state: inout ApplicationFeature.State
  ) -> EffectOf<Self> {
    switch action {
    case .startGameTapped:
      state.path.append(
        .details(DetailsFeature.State())
      )
      return .none
    }
  }
}
