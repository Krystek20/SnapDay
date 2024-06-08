import Foundation
import ComposableArchitecture
import Repositories
import Utilities
import Models
import Common

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
    var pendingIdentifiers: [String] = []
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
      case setPendingIdentifiers([String])
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
        .send(.internal(.loadPendingRequests))
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
          let day = try await dayRepository.loadDay(today)
          let dayActivityTask = day?.activities.reduce(into: [DayActivityTask](), { result, dayActivity in
            result.append(contentsOf: dayActivity.dayActivityTasks)
          }).randomElement() ?? DayActivityTask(id: uuid(), dayActivityId: uuid())
          let dayActivityTaskNotification = DayActivityNotification(
            type: .activityTask(dayActivityTask),
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
        #if DEBUG
        let identifiers = await userNotificationCenterProvider.pendingRequests
        await send(.internal(.setPendingIdentifiers(identifiers)))
        #endif
      }
    case .setPendingIdentifiers(let identifiers):
      state.pendingIdentifiers = identifiers
      return .none
    }
  }
}
