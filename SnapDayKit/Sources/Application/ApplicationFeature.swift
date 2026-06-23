import Dashboard
import Reports
import Onboarding
import ActivityDetails
import ComposableArchitecture
import Utilities
import TipKit
#if DEBUG
import DeveloperTools
#endif

@Reducer
public struct ApplicationFeature: TodayProvidable {

  @Dependency(\.deeplinkService) private var deeplinkService
  @Dependency(\.cloudService) private var cloudService
  @Dependency(\.iconProvider) private var iconProvider
  private static let isOnboardingShownKey = "isOnboardingShown"

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {
    var path = StackState<Path.State>()

    var showOnboarding: Bool {
      didSet {
        userDefaults.setValue(!showOnboarding, forKey: ApplicationFeature.isOnboardingShownKey)
      }
    }

    var selectedTab = Tab.dashboard

    var dashboard = DashboardFeature.State(date: Calendar.today)
    var reports = ReportsFeature.State()
    var onboarding = OnboardingFeature.State()

    #if DEBUG
    @Presents var developerTools: DeveloperToolsFeature.State?
    #endif

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
      self.userDefaults = userDefaults
      self.showOnboarding = !userDefaults.bool(forKey: ApplicationFeature.isOnboardingShownKey)
    }
  }

  public enum Action: BindableAction, Equatable {
    case appeared
    case cleanIcons
    case setupCloud
    case deviceShaked
    case handleUrl(URL)
    case setTab(Tab)
    case dashboard(DashboardFeature.Action)
    case path(StackAction<Path.State, Path.Action>)
    case reports(ReportsFeature.Action)
    case onboarding(OnboardingFeature.Action)
    #if DEBUG
    case developerTools(PresentationAction<DeveloperToolsFeature.Action>)
    #endif
    case binding(BindingAction<State>)
  }

  @Reducer
  public struct Path {
    
    @ObservableState
    public enum State: Equatable {
      case activityDetails(ActivityDetailsFeature.State)
    }

    public enum Action: Equatable {
      case activityDetails(ActivityDetailsFeature.Action)
    }

    public var body: some ReducerOf<Self> {
      Scope(state: /State.activityDetails, action: /Action.activityDetails) {
        ActivityDetailsFeature()
      }
    }
  }

  public enum Tab: String {
    case dashboard
    case reports
  }

  // MARK: - Initialization

  public init() { }

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
            try? Tips.configure()
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
          },
          .run { send in
            for await _ in NotificationCenter.default.publisher(for: .snapDayCloudKitChanged).values {
              await send(.setupCloud)
              await send(.cleanIcons)
            }
          }
        )
      case .cleanIcons:
        return .run { _ in
          await iconProvider.cleanIcons()
        }
      case .setupCloud:
        return .run { _ in
          do {
            try await cloudService.initializeIfNeeded()
          } catch {
            print("Cannot setupCloud: \(error)")
          }
        }
      case .deviceShaked:
        #if DEBUG
        state.developerTools = DeveloperToolsFeature.State()
        #endif
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
      case .reports(.delegate(let action)):
        return handleReportsDelegate(action: action, state: &state)
      case .reports:
        return .none
      case .onboarding(.delegate(.finished)):
        state.showOnboarding = false
        return .none
      case .onboarding:
        return .none
      #if DEBUG
      case .developerTools:
        return .none
      #endif
      case .path:
        return .none
      case .binding:
        return .none
      }
    }
    #if DEBUG
    .ifLet(\.$developerTools, action: \.developerTools) {
      DeveloperToolsFeature()
    }
    #endif
    .forEach(\.path, action: \.path) {
      Path()
    }
  }

  // MARK: - Private

  private func handleReportsDelegate(
    action: ReportsFeature.Action.DelegateAction,
    state: inout ApplicationFeature.State
  ) -> EffectOf<Self> {
    switch action {
    case .activityTapped(let activity, let activities, let period):
      state.path.append(
        .activityDetails(
          ActivityDetailsFeature.State(
            reportType: .activity(activity, activities, nil),
            period: period
          )
        )
      )
      return .none
    case .tagTapped(let tag, let tags, let period):
      state.path.append(
        .activityDetails(
          ActivityDetailsFeature.State(
            reportType: .tag(tag, tags, nil),
            period: period
          )
        )
      )
      return .none
    }
  }
}
