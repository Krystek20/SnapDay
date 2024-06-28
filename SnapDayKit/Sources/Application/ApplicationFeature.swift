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
    var selectedTab = Tab.dashboard

    var dashboard = DashboardFeature.State()
    var reports = ReportsFeature.State()

    @Presents var developerTools: DeveloperToolsFeature.State?

    public init() { }
  }

  public enum Action: BindableAction, Equatable {
    case appeared
    case createDayBackgroundTaskCalled
    case deviceShaked
    case dashboard(DashboardFeature.Action)
    case reports(ReportsFeature.Action)
    case developerTools(PresentationAction<DeveloperToolsFeature.Action>)
    case binding(BindingAction<State>)
  }

  public enum Tab: String {
    case dashboard
    case reports
  }

  // MARK: - Initialization

  public init() {
    userNotificationCenterProvider.registerCategories()
  }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Scope(state: \.dashboard, action: \.dashboard) {
      DashboardFeature()
    }
    
    Scope(state: \.reports, action: \.reports) {
      ReportsFeature()
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
          },
          .run { _ in
            try await dayProvider.removeBrokenDays()
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
      case .dashboard:
        return .none
      case .reports:
        return .none
      case .developerTools:
        return .none
      case .binding:
        return .none
      }
    }
    .ifLet(\.$developerTools, action: \.developerTools) {
      DeveloperToolsFeature()
    }
  }
}
