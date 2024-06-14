import Dashboard
import Reports
import ComposableArchitecture
import Utilities
import DeveloperTools

@Reducer
public struct ApplicationFeature: TodayProvidable {

  @Dependency(\.userNotificationCenterProvider) private var userNotificationCenterProvider
  @Dependency(\.backgroundUpdater) private var backgroundUpdater
  private let dayProvider = DayProvider()

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
    case createDayBackgroundTaskCalled
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
        return .merge(
          .run { _ in
            guard try await userNotificationCenterProvider.requestAuthorization() else { return }
          },
          .run { _ in
            try backgroundUpdater.scheduleCreatingDayBackgroundTask()
          }
        )
      case .createDayBackgroundTaskCalled:
        DeveloperToolsLogger.shared.append(.refresh(.runInBackground))
        return .run { _ in
          try backgroundUpdater.scheduleCreatingDayBackgroundTask()
          _ = try await dayProvider.day(for: tomorrow)
          try await userNotificationCenterProvider.reloadReminders()
        }
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
