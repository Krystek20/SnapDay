import Foundation
import ComposableArchitecture
import Repositories
import Utilities
import Models
import Common
import BackgroundTasks

@Reducer
public struct DeveloperToolsFeature: TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.dayRepository) private var dayRepository
  @Dependency(\.calendar) private var calendar
  @Dependency(\.uuid) private var uuid
  @Dependency(\.date) private var date
  @Dependency(\.userNotificationCenterProvider) private var userNotificationCenterProvider

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {
    private let key = "backgroundUpdatedNotificationEnabled"
    var pendingIdentifiers: [String] = []
    var pendingBackgroundTask: [String] = []
    var backgroundUpdatedNotificationEnabled: Bool {
      get {
        UserDefaults.standard.bool(forKey: key)
      }
      set {
        UserDefaults.standard.setValue(newValue, forKey: key)
      }
    }
    public init() { }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable { 
      case appeared
      case sendDayActivityReminderNotificationButtonTapped
      case sendDayActivityTaskReminderNotificationButtonTapped
      case sendEveningSummaryReminderNotificationButtonTapped
    }
    public enum InternalAction: Equatable {
      case loadPendingRequests
      case loadBackgroundPendingRequests
      case setPendingIdentifiers([String])
      case setBackgroundPendingIdentifiers([String])
      case schedule(notification: DeveloperNotificiation)
    }
    public enum DelegateAction: Equatable { }

    case binding(BindingAction<State>)

    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
  }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        handleViewAction(viewAction, state: &state)
      case .internal(let internalAction):
        handleInternalAction(internalAction, state: &state)
      case .delegate:
        .none
      case .binding:
        .none
      }
    }
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Private

  private func handleViewAction(_ action: Action.ViewAction, state: inout State) -> Effect<Action> {
    switch action {
    case .appeared:
      .merge(
        .send(.internal(.loadPendingRequests)),
        .send(.internal(.loadBackgroundPendingRequests))
      )
    case .sendDayActivityReminderNotificationButtonTapped:
      .run { send in
        let day = try await dayRepository.loadDay(today)
        let dayActivity = day?.activities.randomElement() ?? DayActivity(
          id: uuid(),
          dayId: uuid(),
          isGeneratedAutomatically: false
        )
        let dayActivityNotification = DayActivityNotification(
          type: .activity(dayActivity),
          calendar: calendar
        )
        let notification = DeveloperNotificiation(
          identifier: uuid().uuidString,
          content: dayActivityNotification.content
        )
        await send(.internal(.schedule(notification: notification)))
      }
    case .sendDayActivityTaskReminderNotificationButtonTapped:
        .run { send in
          guard
            let day = try await dayRepository.loadDay(today),
            let dayActivity = day.activities.first(where: { !$0.dayActivityTasks.isEmpty }),
            let dayActivityTask = dayActivity.dayActivityTasks.randomElement()
          else { return }

          let dayActivityTaskNotification = DayActivityNotification(
            type: .activityTask(dayActivity, dayActivityTask),
            calendar: calendar
          )

          let notification = DeveloperNotificiation(
            identifier: uuid().uuidString,
            content: dayActivityTaskNotification.content
          )

          await send(.internal(.schedule(notification: notification)))
        }
    case .sendEveningSummaryReminderNotificationButtonTapped:
        .run { send in
          let eveningSummary = EveningSummary(calendar: calendar)
          let notification = DeveloperNotificiation(
            identifier: uuid().uuidString,
            content: eveningSummary.content
          )
          await send(.internal(.schedule(notification: notification)))
        }
    }
  }

  private func handleInternalAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .schedule(let notification):
      return .run { send in
        try await userNotificationCenterProvider.schedule(
          userNotification: notification
        )
      }
    case .loadPendingRequests:
      return .run { send in
//        #if DEBUG
        let identifiers = await userNotificationCenterProvider.pendingRequests
        await send(.internal(.setPendingIdentifiers(identifiers)))
//        #endif
      }
    case .loadBackgroundPendingRequests:
      return .run { send in
        let pendingTasks = await BGTaskScheduler.shared.pendingTaskRequests().map(\.taskIdentifier)
        await send(.internal(.setBackgroundPendingIdentifiers(pendingTasks)))
      }
    case .setPendingIdentifiers(let identifiers):
      state.pendingIdentifiers = identifiers
      return .none
    case .setBackgroundPendingIdentifiers(let identifiers):
      state.pendingBackgroundTask = identifiers
      return .none
    }
  }
}

fileprivate extension BGTaskRequest {
  var taskIdentifier: String {
    var date = ""
    if let earliestBeginDate {
      date = "\(earliestBeginDate)"
    }
    return identifier + " - " + date
  }
}
