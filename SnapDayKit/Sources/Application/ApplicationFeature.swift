import ComposableArchitecture
import Foundation
import Models
import Onboarding
import Payment
import Plans
import Repositories
import Utilities
import TipKit
#if DEBUG
import DeveloperTools
#endif

@Reducer
public struct ApplicationFeature {

  private enum CancelID {
    case onboardingPlanCreation
    case premiumEntitlementUpdates
  }

  @Dependency(\.deeplinkService) private var deeplinkService
  @Dependency(\.cloudService) private var cloudService
  @Dependency(\.iconProvider) private var iconProvider
  @Dependency(\.planCreationRepository) private var planCreationRepository
  @Dependency(\.calendar) private var calendar
  @Dependency(\.date.now) private var now
  @Dependency(\.uuid) private var uuid
  @Dependency(\.paymentClient) private var paymentClient
  private static let isOnboardingShownKey = "isOnboardingShown"
  private let userDefaults: UserDefaults

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {
    var showOnboarding: Bool
    var selectedTab = Tab.dashboard

    var dashboard = DashboardCoordinatorFeature.State()
    var reports = ReportsCoordinatorFeature.State()
    var onboarding = OnboardingFeature.State()
    var onboardingGeneratedActivityIDs: Set<Activity.ID> = []
    var isOnboardingPlanSaveErrorPresented = false
    var premiumEntitlement = PremiumEntitlement.unknown

    #if DEBUG
    @Presents var developerTools: DeveloperToolsFeature.State?
    #endif

    public init(userDefaults: UserDefaults = .standard) {
      showOnboarding = !userDefaults.bool(forKey: ApplicationFeature.isOnboardingShownKey)
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
    case onboardingPlanSaved
    case onboardingPlanSaveFailed
    case onboardingPlanSaveErrorDismissed
    case premiumEntitlementUpdated(PremiumEntitlement)
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

  public init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

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
          },
          .run { send in
            for await entitlement in paymentClient.entitlementUpdates() {
              await send(.premiumEntitlementUpdated(entitlement))
            }
          }
          .cancellable(id: CancelID.premiumEntitlementUpdates, cancelInFlight: true)
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
      case .onboarding(.delegate(.completed)):
        state.onboarding = OnboardingFeature.State()
        state.showOnboarding = false
        state.selectedTab = .dashboard
        userDefaults.set(true, forKey: Self.isOnboardingShownKey)
        return .none
      case .onboarding(.delegate(.skipped)):
        state.onboarding = OnboardingFeature.State()
        state.showOnboarding = false
        state.selectedTab = .dashboard
        userDefaults.set(true, forKey: Self.isOnboardingShownKey)
        return .none
      case .onboarding(.delegate(.createPlanRequested(let request))):
        let startDate = calendar.startOfDay(for: now)
        let activity = request.activityTitle.map {
          Activity(
            id: uuid(),
            name: $0,
            startDate: startDate
          )
        }
        state.onboardingGeneratedActivityIDs = Set(activity.map { [$0.id] } ?? [])
        return .send(
          .onboarding(
            .presentPlan(
              NewPlanFeature.State(
                onboardingName: request.name,
                startDate: startDate,
                suggestedActivity: activity,
                scheduledWeekdays: scheduledWeekdays(
                  for: request.cadence,
                  startDate: startDate
                ),
                calendar: calendar
              )
            )
          )
        )
      case .onboarding(.delegate(.planCreationCancelled)):
        state.onboardingGeneratedActivityIDs = []
        return .cancel(id: CancelID.onboardingPlanCreation)
      case .onboarding(.delegate(.planCreated(let draft))):
        let generatedActivityIDs = state.onboardingGeneratedActivityIDs
        let generatedActivities = draft.uniqueActivities.filter {
          generatedActivityIDs.contains($0.id)
        }
        let plan = draft.plan(id: uuid(), scheduleEntryID: { uuid() })
        let occurrences = plan.scheduledOccurrences(
          from: plan.startDate,
          calendar: calendar
        )
        return .run { send in
          do {
            try await planCreationRepository.create(
              plan,
              generatedActivities,
              occurrences
            )
            await send(.onboardingPlanSaved)
          } catch {
            await send(.onboardingPlanSaveFailed)
          }
        }
        .cancellable(id: CancelID.onboardingPlanCreation, cancelInFlight: true)
      case .onboarding:
        return .none
      case .onboardingPlanSaved:
        state.onboardingGeneratedActivityIDs = []
        state.onboarding = OnboardingFeature.State()
        state.showOnboarding = false
        state.selectedTab = .dashboard
        userDefaults.set(true, forKey: Self.isOnboardingShownKey)
        return .send(.dashboard(.dashboard(.internal(.load))))
      case .onboardingPlanSaveFailed:
        state.isOnboardingPlanSaveErrorPresented = true
        return .send(.onboarding(.newPlan(.submissionFailed)))
      case .onboardingPlanSaveErrorDismissed:
        state.isOnboardingPlanSaveErrorPresented = false
        return .none
      case .premiumEntitlementUpdated(let entitlement):
        state.premiumEntitlement = entitlement
        return .none
      #if DEBUG
      case .developerTools(.presented(.delegate(.showOnboardingAgain))):
        userDefaults.removeObject(forKey: Self.isOnboardingShownKey)
        state.onboarding = OnboardingFeature.State()
        state.showOnboarding = true
        state.developerTools = nil
        return .none
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

  private func scheduledWeekdays(
    for cadence: OnboardingPlanRequest.Cadence?,
    startDate: Date
  ) -> Set<PlanWeekday> {
    switch cadence {
    case .daily:
      Set(PlanWeekday.allCases)
    case .weekdays:
      [.monday, .tuesday, .wednesday, .thursday, .friday]
    case .weekends:
      [.saturday, .sunday]
    case .onceWeekly:
      PlanWeekday(rawValue: calendar.component(.weekday, from: startDate)).map { [$0] } ?? []
    case nil:
      []
    }
  }
}
