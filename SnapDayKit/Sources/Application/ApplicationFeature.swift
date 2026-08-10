import Onboarding
import ComposableArchitecture
import Foundation
import Utilities
import TipKit
#if DEBUG
import DeveloperTools
#endif

@Reducer
public struct ApplicationFeature {

  @Dependency(\.deeplinkService) private var deeplinkService
  @Dependency(\.cloudService) private var cloudService
  @Dependency(\.iconProvider) private var iconProvider
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

    var dashboard = DashboardCoordinatorFeature.State()
    var reports = ReportsCoordinatorFeature.State()
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
    case openDashboardRoute(DashboardCoordinatorFeature.ExternalRoute)
    case setTab(Tab)
    case dashboard(DashboardCoordinatorFeature.Action)
    case reports(ReportsCoordinatorFeature.Action)
    case onboarding(OnboardingFeature.Action)
    #if DEBUG
    case developerTools(PresentationAction<DeveloperToolsFeature.Action>)
    #endif
    case binding(BindingAction<State>)
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
      DashboardCoordinatorFeature()
    }

    Scope(state: \.reports, action: \.reports) {
      ReportsCoordinatorFeature()
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
              case .plans(let planID):
                if let planID {
                  await send(.openDashboardRoute(.plan(planID)))
                } else {
                  await send(.openDashboardRoute(.plans))
                }
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
      case .openDashboardRoute(let route):
        deeplinkService.consume()
        state.selectedTab = .dashboard
        return .send(.dashboard(.externalRoute(route)))
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
      #if DEBUG
      case .developerTools:
        return .none
      #endif
      case .binding:
        return .none
      }
    }
    #if DEBUG
    .ifLet(\.$developerTools, action: \.developerTools) {
      DeveloperToolsFeature()
    }
    #endif
  }
}
