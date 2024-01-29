import Dashboard
import PlanDetails
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
      case planDetails(PlanDetailsFeature.State)
      case details(DetailsFeature.State)
    }

    public enum Action: Equatable {
      case planDetails(PlanDetailsFeature.Action)
      case details(DetailsFeature.Action)
    }

    public var body: some ReducerOf<Self> {
      Scope(state: /State.planDetails, action: /Action.planDetails) {
        PlanDetailsFeature()
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
      case .path(.element(_, action: .planDetails(.delegate(let action)))):
        return handlePlanDetailsDelegate(action: action, state: &state)
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
    case .planTapped(let plan):
      state.path.append(
        .planDetails(PlanDetailsFeature.State(plan: plan))
      )
      return .none
    }
  }

  private func handlePlanDetailsDelegate(
    action: PlanDetailsFeature.Action.DelegateAction,
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