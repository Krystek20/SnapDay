import Foundation
import ComposableArchitecture
import Repositories
import Utilities
import Models
import Common
import CalendarPicker
import Friends
import ManageActivity
import Combine

@Reducer
public struct DashboardFeature: TodayProvidable {

  public enum PremiumGate: Equatable {
    case advancedRecurrence
    case aiAllowance
    case collaborationInvitation
  }

  // MARK: - Dependencies

  @Dependency(\.dayUpdater) private var dayUpdater
  @Dependency(\.utcCalendar) private var calendar
  @Dependency(\.deeplinkService) private var deeplinkService
  @Dependency(\.widgetReloader) private var widgetReloader
  private let userDefaults: UserDefaults

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable, TodayProvidable {

    var title: String {
      formattedTitle()
    }

    func formattedTitle(locale: Locale = .preferred) -> String {
      let formatter = DateFormatter()
      formatter.dateFormat = "EEEE, d MMM yyyy"
      formatter.locale = locale
      formatter.timeZone = TimeZone(secondsFromGMT: 0)
      return formatter.string(from: date)
    }

    var day: DashboardDayFeature.State
    var plans = DashboardPlansFeature.State()
    var notifications = DashboardNotificationsFeature.State()
    var hasPremiumAccess = false

    var shouldShowNotificationPrompt: Bool {
      notifications.canRequestAuthorization
      && (!(day.selectedDay?.activities.isEmpty ?? true) || !plans.summaries.isEmpty)
    }

    @ObservationStateIgnored var streamSetup = false

    var date: Date

    @Presents var calendarPicker: CalendarPickerFeature.State?
    @Presents var friends: FriendsFeature.State?
    @Presents var manageActivity: ManageActivityFeature.State?

    public init(
      date: Date,
      userDefaults: UserDefaults = .standard
    ) {
      self.date = date
      self.day = DashboardDayFeature.State(userDefaults: userDefaults)
    }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case calendarButtonTapped
      case todayButtonTapped
      case increaseButtonTapped
      case decreaseButtonTapped
      case showFriendsTapped
      case assistantButtonTapped
    }

    public enum InternalAction: Equatable {
      case changesApplied(AppliedChanges)
      case load
      case loadDay
      case setDate(_ date: Date)
      case setDay(_ day: Day)
      case calendarDayChanged
      case handleDeepLink(DeeplinkService.DashboardAction?)
      case manageActivity
    }
    public enum DelegateAction: Equatable {
      case allPlansTapped
      case planTapped(Plan)
      case premiumAccessRequested(PremiumGate)
    }

    case binding(BindingAction<State>)
    case calendarPicker(PresentationAction<CalendarPickerFeature.Action>)
    case day(DashboardDayFeature.Action)
    case plans(DashboardPlansFeature.Action)
    case notifications(DashboardNotificationsFeature.Action)
    case friends(PresentationAction<FriendsFeature.Action>)
    case manageActivity(PresentationAction<ManageActivityFeature.Action>)

    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
    case premiumAccessGranted(PremiumGate)
    case premiumEntitlementUpdated(Bool)
  }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Scope(state: \.day, action: \.day) {
      DashboardDayFeature(userDefaults: userDefaults)
    }
    Scope(state: \.plans, action: \.plans) {
      DashboardPlansFeature()
    }
    Scope(state: \.notifications, action: \.notifications) {
      DashboardNotificationsFeature(userDefaults: userDefaults)
    }

    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        return handleViewAction(viewAction, state: &state)
      case .internal(let internalAction):
        return handleInternalAction(internalAction, state: &state)
      case .calendarPicker(let action):
        return handleCalendarPickerAction(action, state: &state)
      case .day(.delegate(.calendarPickerRequested(let picker))):
        state.calendarPicker = picker
        return .none
      case .day(.delegate(.premiumAccessRequested)):
        return .send(.delegate(.premiumAccessRequested(.advancedRecurrence)))
      case .day(.delegate(.reloadRequested)):
        return .send(.internal(.load))
      case .day(.delegate(.remindersReloadRequested)):
        return .send(.notifications(.reloadRemindersIfAuthorized))
      case .day:
        return .none
      case .plans(.delegate(.allPlansTapped)):
        return .send(.delegate(.allPlansTapped))
      case .plans(.delegate(.planTapped(let plan))):
        return .send(.delegate(.planTapped(plan)))
      case .plans:
        return .none
      case .notifications(.delegate(.reloadRequested)):
        return .send(.internal(.load))
      case .notifications:
        return .none
      case .friends(.presented(.delegate(.premiumAccessRequested))):
        return .send(.delegate(.premiumAccessRequested(.collaborationInvitation)))
      case .friends:
        return .none
      case .manageActivity(.dismiss):
        return .send(.internal(.load))
      case .manageActivity:
        return .none
      case .delegate:
        return .none
      case .premiumAccessGranted(let gate):
        state.hasPremiumAccess = true
        return resumePremiumAction(gate, state: state)
      case .premiumEntitlementUpdated(let hasAccess):
        state.hasPremiumAccess = hasAccess
        return updatePresentedPremiumEntitlement(hasAccess, state: state)
      case .binding:
        return .none
      }
    }
    .ifLet(\.$calendarPicker, action: \.calendarPicker) {
      CalendarPickerFeature()
    }
    .ifLet(\.$friends, action: \.friends) {
      FriendsFeature()
    }
    .ifLet(\.$manageActivity, action: \.manageActivity) {
      ManageActivityFeature()
    }
  }

  // MARK: - Actions

  private func handleViewAction(
    _ action: Action.ViewAction,
    state: inout State
  ) -> Effect<Action> {
    switch action {
    case .appeared:
      guard !state.streamSetup else { return .none }
      state.streamSetup = true
      return .merge(
        .send(.internal(.load)),
        .send(.notifications(.start)),
        .run { send in
          for await _ in NotificationCenter.default.publisher(for: .snapDayCloudKitChanged).values {
            try await dayUpdater.syncShared()
            await send(.internal(.load))
          }
        },
        .run { send in
          for await _ in NotificationCenter.default.publisher(for: .NSCalendarDayChanged).values {
            await send(.internal(.calendarDayChanged))
          }
        },
        .run { send in
          for await deeplink in deeplinkService.deeplinkPublisher.values {
            guard let deeplink, case .dashboard(let action) = deeplink else { continue }
            await send(.internal(.handleDeepLink(action)))
          }
        }
      )
    case .calendarButtonTapped:
      showDatePicker(state: &state)
      return .none
    case .increaseButtonTapped:
      state.date = calendar.date(byAdding: .day, value: 1, to: state.date) ?? state.date
      return .send(.internal(.load))
    case .decreaseButtonTapped:
      state.date = calendar.date(byAdding: .day, value: -1, to: state.date) ?? state.date
      return .send(.internal(.load))
    case .todayButtonTapped:
      state.date = today
      return .send(.internal(.load))
    case .showFriendsTapped:
      state.friends = FriendsFeature.State(hasPremiumAccess: state.hasPremiumAccess)
      return .none
    case .assistantButtonTapped:
      state.manageActivity = ManageActivityFeature.State()
      return .none
    }
  }

  private func handleInternalAction(
    _ action: Action.InternalAction,
    state: inout State
  ) -> Effect<Action> {
    switch action {
    case .changesApplied(let appliedChanges):
      let shouldReload = appliedChanges.dates.contains { state.date == $0 }
      return .run { [shouldReload] send in
        guard shouldReload else { return }
        await send(.internal(.load))
      }
    case .calendarDayChanged:
      state.date = today
      return .send(.internal(.load))
    case .setDate(let date):
      state.date = date
      return .send(.internal(.load))
    case .load:
      return .merge(
        .send(.internal(.loadDay)),
        .send(.plans(.load))
      )
    case .loadDay:
      return .run { [date = state.date] send in
        do {
          let day = try await dayUpdater.day(date)
          await send(.internal(.setDay(day)))
          await widgetReloader.requestReload()
        } catch {
          print("error: \(error)")
        }
      }
    case .setDay(let day):
      return .concatenate(
        .send(.day(.setDay(day))),
        .send(.notifications(.reloadRemindersIfAuthorized))
      )
    case .handleDeepLink(let deeplink):
      deeplinkService.consume()
      guard let deeplink else { return .none }
      state.calendarPicker = nil
      let destination: Effect<Action> = switch deeplink {
      case .addActivity:
        .send(.day(.view(.newButtonTapped)))
      case .dictate:
        .send(.internal(.manageActivity))
      }
      return .concatenate(.send(.day(.dismissPresentations)), destination)
    case .manageActivity:
      state.manageActivity = ManageActivityFeature.State()
      return .none
    }
  }

  private func handleCalendarPickerAction(
    _ action: PresentationAction<CalendarPickerFeature.Action>,
    state: inout State
  ) -> Effect<Action> {
    switch action {
    case .presented(
      .delegate(.datesSelected(let dates, let objectIdentifier, let actionIdentifier))
    ):
      guard let actionIdentifier,
            let action = CalendarActivityAction(rawValue: actionIdentifier) else { return .none }
      return .run { [objectIdentifier, action, dates] send in
        switch action {
        case .copy:
          guard let objectIdentifier,
                let dayActivity = try await dayUpdater.dayActivity(
                  identifier: objectIdentifier
                ) else { return }
          await send(.day(.dayActivity(.copy(dayActivity, dates: dates))))
        case .move:
          guard let objectIdentifier,
                let dayActivity = try await dayUpdater.dayActivity(
                  identifier: objectIdentifier
                ),
                let firstDate = dates.first else { return }
          await send(.day(.dayActivity(.move(dayActivity, date: firstDate))))
        case .changeDate:
          guard let firstDate = dates.first else { return }
          await send(.internal(.setDate(firstDate)))
        }
      }
    case .dismiss:
      return .none
    default:
      return .none
    }
  }

  private func resumePremiumAction(_ gate: PremiumGate, state: State) -> Effect<Action> {
    switch gate {
    case .advancedRecurrence:
      return .send(.day(.premiumAccessGranted))
    case .collaborationInvitation:
      guard state.friends != nil else { return .none }
      return .send(.friends(.presented(.premiumAccessGranted)))
    case .aiAllowance:
      return .none
    }
  }

  private func updatePresentedPremiumEntitlement(
    _ hasAccess: Bool,
    state: State
  ) -> Effect<Action> {
    var effects: [Effect<Action>] = [
      .send(.day(.premiumEntitlementUpdated(hasAccess)))
    ]
    if state.friends != nil {
      effects.append(.send(.friends(.presented(.premiumEntitlementUpdated(hasAccess)))))
    }
    return .merge(effects)
  }

  private func showDatePicker(state: inout State) {
    state.calendarPicker = CalendarPickerFeature.State(
      type: .singleSelection(.noConfirmation),
      date: state.date,
      actionIdentifier: CalendarActivityAction.changeDate.rawValue
    )
  }

  // MARK: - Initialization

  public init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }
}
