import Foundation
import ComposableArchitecture
import Utilities
import Models
import enum UiComponents.DayViewShowButtonState

@Reducer
public struct EveningSummaryFeature: TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.timePeriodsProvider) private var timePeriodsProvider
  @Dependency(\.dayActivityRepository) private var dayActivityRepository
  @Dependency(\.dayEditor) private var dayEditor
  @Dependency(\.date) private var date
  private let periodTitleProvider = PeriodTitleProvider()
  private let userNotificationCenterProvider = UserNotificationCenterProvider()

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable, TodayProvidable {
    
    var day: Day?
    var activityListOption: ActivityListOption = .collapsed

    var completedActivities: CompletedActivities {
      day?.completedActivities ?? CompletedActivities(doneCount: .zero, totalCount: .zero, percent: .zero)
    }
    var showDoneView: Bool = false

    var dayViewShowButtonState: DayViewShowButtonState {
      guard let day,
            !day.activities.filter(\.isDone).isEmpty else { return .none }
      switch activityListOption {
      case .collapsed:
        return .show
      case .extended:
        return .hide
      }
    }

    var activitiesToShow: [DayActivity] {
      switch activityListOption {
      case .collapsed:
        day?.sortedDayActivities.filter { !$0.isDone } ?? []
      case .extended:
        day?.sortedDayActivities ?? []
      }
    }

    public init() { }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case activityTapped(DayActivity)
      case taskActivityTapped(DayActivity, DayActivityTask)
      case showCompletedActivitiesTapped
      case hideCompletedActivitiesTapped
    }
    public enum InternalAction: Equatable {
      case loadDay
      case setDay(Day?)
    }

    case binding(BindingAction<State>)

    case view(ViewAction)
    case `internal`(InternalAction)
  }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        return handleViewAction(viewAction, state: &state)
      case .internal(let internalAction):
        return handleInternalAction(internalAction, state: &state)
      case .binding:
        return .none
      }
    }
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Private

  private func handleViewAction(_ action: Action.ViewAction, state: inout State) -> Effect<Action> {
    switch action {
    case .appeared:
      return .send(.internal(.loadDay))
    case .activityTapped(var dayActivity):
      if dayActivity.doneDate == nil {
        dayActivity.doneDate = date()
      } else {
        dayActivity.doneDate = nil
      }
      return .run { [dayActivity] send in
        try await dayActivityRepository.saveActivity(dayActivity)
        await send(.internal(.loadDay))
      }
    case .taskActivityTapped(var dayActivity, var dayActivityTask):
      guard let index = dayActivity.dayActivityTasks.firstIndex(where: { $0.id ==  dayActivityTask.id }) else { return .none }
      if dayActivityTask.doneDate == nil {
        dayActivityTask.doneDate = date()
      } else {
        dayActivityTask.doneDate = nil
      }
      dayActivity.dayActivityTasks[index] = dayActivityTask
      return .run { [dayActivity] send in
        try await dayActivityRepository.saveActivity(dayActivity)
        await send(.internal(.loadDay))
      }
    case .showCompletedActivitiesTapped:
      state.activityListOption = .extended
      return .none
    case .hideCompletedActivitiesTapped:
      state.activityListOption = .collapsed
      return .none
    }
  }

  private func handleInternalAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .loadDay:
      return .run { send in
        let timePeriod = try await timePeriodsProvider.timePeriod(.day, today, .zero)
        await send(.internal(.setDay(timePeriod.days.first)))
      }
    case .setDay(let day):
      let allActivitiesDone = day?.activities.filter { !$0.isDone }.isEmpty == true
      if state.day == nil || !allActivitiesDone {
        state.showDoneView = allActivitiesDone
      }
      state.day = day
      return .none
    }
  }
}
