import Dashboard
import Reports
import Onboarding
import ComposableArchitecture
import Utilities
import DeveloperTools
import TipKit

@Reducer
public struct ApplicationFeature: TodayProvidable {

  @Dependency(\.userNotificationCenterProvider) private var userNotificationCenterProvider
  @Dependency(\.backgroundUpdater) private var backgroundUpdater
  @Dependency(\.deeplinkService) private var deeplinkService
  private let dayProvider = DayProvider()
  private static let isOnboardingShownKey = "isOnboardingShown"

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    var showOnboarding: Bool {
      didSet {
        userDefaults.setValue(!showOnboarding, forKey: ApplicationFeature.isOnboardingShownKey)
      }
    }

    var selectedTab = Tab.dashboard

    var dashboard = DashboardFeature.State(date: Calendar.today)
    var reports = ReportsFeature.State()
    var onboarding = OnboardingFeature.State()

    @Presents var developerTools: DeveloperToolsFeature.State?
    
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
      self.userDefaults = userDefaults
      self.showOnboarding = !userDefaults.bool(forKey: ApplicationFeature.isOnboardingShownKey)
    }
  }

  public enum Action: BindableAction, Equatable {
    case appeared
    case createDayBackgroundTaskCalled
    case deviceShaked
    case handleUrl(URL)
    case setTab(Tab)
    case dashboard(DashboardFeature.Action)
    case reports(ReportsFeature.Action)
    case onboarding(OnboardingFeature.Action)
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

    Scope(state: \.onboarding, action: \.onboarding) {
      OnboardingFeature()
    }

    Reduce { state, action in
      switch action {
      case .appeared:
        return .merge(
          .run { _ in
            if #available(iOS 17.0, *) {
              try? Tips.configure()
            }
          },
          .run { _ in
            DeveloperToolsLogger.shared.append(.refresh(.setup))
            try await backgroundUpdater.scheduleCreatingDayBackgroundTask()
          },
          .run { send in
            for await deeplink in deeplinkService.deeplinkPublisher.values {
              switch deeplink {
              case .dashboard:
                await send(.setTab(.dashboard))
              case .none:
                break
              }
            }
          }
        )
      case .createDayBackgroundTaskCalled:
        DeveloperToolsLogger.shared.append(.refresh(.runInBackground))
        return .run { _ in
          try await backgroundUpdater.scheduleCreatingDayBackgroundTask()
          DeveloperToolsLogger.shared.append(.refresh(.setupInBackground))
          _ = try await dayProvider.day(tomorrow)
          try await userNotificationCenterProvider.reloadReminders()
          try await userNotificationCenterProvider.sendDeveloperMessage("Next day set and reminders scheduled")
        }
      case .deviceShaked:
        state.developerTools = DeveloperToolsFeature.State()
        return .none
      case .handleUrl(let url):
        deeplinkService.handleUrl(url)
        return .none
      case .setTab(let tab):
        guard state.selectedTab != tab else { return .none }
        state.selectedTab = tab
        return .none
      case .dashboard:
        return .none
      case .reports:
        return .none
      case .onboarding(.delegate(.finished)):
        state.showOnboarding = false
        return .none
      case .onboarding:
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
