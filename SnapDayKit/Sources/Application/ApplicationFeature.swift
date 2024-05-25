import Dashboard
import Reports
import ComposableArchitecture
import Utilities
import DeveloperTools

@Reducer
public struct ApplicationFeature {

  @Dependency(\.userNotificationCenterProvider) private var userNotificationCenterProvider

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {
    var dashboard = DashboardFeature.State()
    var path = StackState<Path.State>()

    @Presents var developerTools: DeveloperToolsFeature.State?

    public init() { }
  }

  public enum Action: Equatable {
    case appeared
    case deviceShaked
    case dashboard(DashboardFeature.Action)
    case path(StackAction<Path.State, Path.Action>)

    case developerTools(PresentationAction<DeveloperToolsFeature.Action>)
  }

  @Reducer
  public struct Path {
    
    @ObservableState
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

  public init() { 
    userNotificationCenterProvider.registerCategories()
  }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Scope(state: \.dashboard, action: \.dashboard) {
      DashboardFeature()
    }

    Reduce { state, action in
      switch action {
      case .appeared:
        return .concatenate(
          .run { send in
            guard try await userNotificationCenterProvider.requestAuthorization() else { return }
          }
        )
      case .deviceShaked:
        state.developerTools = DeveloperToolsFeature.State()
        return .none
      case .dashboard(.delegate(let action)):
        return handleDashboardDelegate(action: action, state: &state)
      case .dashboard:
        return .none
      case .developerTools:
        return .none
      case .path:
        return .none
      }
    }
    .ifLet(\.$developerTools, action: \.developerTools) {
      DeveloperToolsFeature()
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
