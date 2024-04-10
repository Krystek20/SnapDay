import Foundation
import ComposableArchitecture
import ActivityList
import DayActivityForm
import Repositories
import Utilities
import Models
import Common
import ActivityForm
import DayActivityTaskForm
import Combine
import enum UiComponents.DayViewShowButtonState
import protocol UiComponents.InformationViewConfigurable

@Reducer
public struct DashboardFeature: Reducer, TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.timePeriodsProvider) private var timePeriodsProvider
  @Dependency(\.dayActivityRepository) private var dayActivityRepository
  @Dependency(\.dayEditor) private var dayEditor
  @Dependency(\.uuid) private var uuid
  @Dependency(\.date) private var date
  private let periodTitleProvider = PeriodTitleProvider()

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable, TodayProvidable {

    var activitiesPresentationType: ActivitiesPresentationType?
    var activityListOption: ActivityListOption = .collapsed
    var periods = Period.allCases
    var timePeriod: TimePeriod?
    var shift: Int = .zero
    var activitiesPresentationTitle = ""
    var dayActivityToEdit: DayActivity?

    var daySummary: DaySummary? {
      guard let selectedDay else { return nil }
      return DaySummary(day: selectedDay)
    }

    var linearChartValues: LinearChartValues? {
      guard let timePeriod, let selectedDay else { return nil }
      let linearChartValuesProvider = LinearChartValuesProvider()
      switch timePeriod.type {
      case .day:
        return linearChartValuesProvider.prepareValues(for: selectedDay)
      case .week, .month, .quarter:
        return linearChartValuesProvider.prepareValues(for: timePeriod, selectedDay: selectedDay, until: today)
      }
    }

    var activities: [DayActivity] {
      switch activityListOption {
      case .collapsed:
        selectedDay?.sortedDayActivities.filter { !$0.isDone } ?? []
      case .extended:
        selectedDay?.sortedDayActivities ?? []
      }
    }

    var dayViewShowButtonState: DayViewShowButtonState {
      guard let selectedDay,
            !selectedDay.activities.filter(\.isDone).isEmpty else { return .none }
      switch activityListOption {
      case .collapsed:
        return .show
      case .extended:
        return .hide
      }
    }

    var dayInformation: InformationViewConfigurable? {
      let emptyDayConfiguration: EmptyDayConfiguration = selectedDay?.isOlderThenToday == true ? .pastDay : .todayOrFuture
      return selectedDay?.activities.isEmpty == true ? emptyDayConfiguration : nil
    }

    var selectedPeriod: Period = .day
    var selectedDay: Day?

    @Presents var activityList: ActivityListFeature.State?
    @Presents var editDayActivity: DayActivityFormFeature.State?
    @Presents var addActivity: ActivityFormFeature.State?
    @Presents var dayActivityTaskForm: DayActivityTaskFormFeature.State?

    public init() { }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case activityListButtonTapped
      case oneTimeActivityButtonTapped
      case dayActivityTapped(DayActivity)
      case dayActivityEditTapped(DayActivity)
      case dayActivityRemoveTapped(DayActivity)
      case dayActivityTaskTapped(DayActivity, DayActivityTask)
      case dayActivityEditTaskTapped(DayActivity, DayActivityTask)
      case removeDayActivityTaskTapped(DayActivity, DayActivityTask)
      case showCompletedActivitiesTapped
      case hideCompletedActivitiesTapped
      case reportButtonTapped
      case selectedPeriod(Period)
      case increaseButtonTapped
      case decreaseButtonTapped
    }
    public enum InternalAction: Equatable {
      case loadTimePeriods
      case timePeriodLoaded(_ timePeriod: TimePeriod)
      case removeDayActivity(_ dayActivity: DayActivity)
      case calendarDayChanged
    }
    public enum DelegateAction: Equatable {
      case reportsTapped
    }

    case binding(BindingAction<State>)

    case activityList(PresentationAction<ActivityListFeature.Action>)
    case editDayActivity(PresentationAction<DayActivityFormFeature.Action>)
    case addActivity(PresentationAction<ActivityFormFeature.Action>)
    case dayActivityTaskForm(PresentationAction<DayActivityTaskFormFeature.Action>)

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
        return handleViewAction(viewAction, state: &state)
      case .internal(let internalAction):
        return handleInteralAction(internalAction, state: &state)
      case .editDayActivity(let action):
        return handleDayActivityFormAction(action, state: &state)
      case .activityList(let action):
        return handleActivityListAction(action, state: &state)
      case .addActivity(let action):
        return handleActivityFormAction(action, state: &state)
      case .dayActivityTaskForm(let action):
        return handleDayActivityTaskFormAction(action, state: &state)
      case .delegate:
        return .none
      case .binding(\.selectedPeriod):
        state.shift = .zero
        return .run { send in
          await send(.internal(.loadTimePeriods))
        }
      case .binding:
        return .none
      }
    }
    .ifLet(\.$activityList, action: \.activityList) {
      ActivityListFeature()
    }
    .ifLet(\.$editDayActivity, action: \.editDayActivity) {
      DayActivityFormFeature()
    }
    .ifLet(\.$addActivity, action: \.addActivity) {
      ActivityFormFeature()
    }
    .ifLet(\.$dayActivityTaskForm, action: \.dayActivityTaskForm) {
      DayActivityTaskFormFeature()
    }
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Private

  private func handleViewAction(_ action: Action.ViewAction, state: inout State) -> Effect<Action> {
    switch action {
    case .appeared:
      return .concatenate(
        .run { send in
          await send(.internal(.loadTimePeriods))
        },
        .run { send in
          for await _ in NotificationCenter.default.publisher(for: .NSCalendarDayChanged).values {
            await send(.internal(.calendarDayChanged))
          }
        }
      )
    case .activityListButtonTapped:
      state.activityList = ActivityListFeature.State(
        configuration: ActivityListFeature.ActivityListConfiguration(
          type: .multiSelection(selectedActivities: []),
          isActivityEditable: true,
          fetchingOption: .fromCoreData
        )
      )
      return .none
    case .oneTimeActivityButtonTapped:
      state.addActivity = ActivityFormFeature.State(
        activity: Activity(
          id: uuid(),
          isVisible: false
        )
      )
      return .none
    case .dayActivityTapped(var dayActivity):
      if dayActivity.doneDate == nil {
        dayActivity.doneDate = date()
      } else {
        dayActivity.doneDate = nil
      }
      return .run { [dayActivity] send in
        try await dayActivityRepository.saveActivity(dayActivity)
        await send(.internal(.loadTimePeriods))
      }
    case .dayActivityEditTapped(let dayActivity):
      state.editDayActivity = DayActivityFormFeature.State(dayActivity: dayActivity)
      return .none
    case .dayActivityRemoveTapped(let dayActivity):
      return .run { send in
        await send(.internal(.removeDayActivity(dayActivity)))
      }
    case .dayActivityTaskTapped(var dayActivity, var dayActivityTask):
      guard let index = dayActivity.dayActivityTasks.firstIndex(where: { $0.id ==  dayActivityTask.id }) else { return .none }
      if dayActivityTask.doneDate == nil {
        dayActivityTask.doneDate = date()
      } else {
        dayActivityTask.doneDate = nil
      }
      dayActivity.dayActivityTasks[index] = dayActivityTask
      return .run { [dayActivity] send in
        try await dayActivityRepository.saveActivity(dayActivity)
        await send(.internal(.loadTimePeriods))
      }
    case .dayActivityEditTaskTapped(let dayActivity, let dayActivityTask):
      state.dayActivityToEdit = dayActivity
      state.dayActivityTaskForm = DayActivityTaskFormFeature.State(
        dayActivityTask: dayActivityTask,
        type: .edit
      )
      return .none
    case .removeDayActivityTaskTapped(var dayActivity, let dayActivityTask):
      guard let index = dayActivity.dayActivityTasks.firstIndex(where: { $0.id ==  dayActivityTask.id }) else { return .none }
      dayActivity.dayActivityTasks.remove(at: index)
      return .run { [dayActivity] send in
        try await dayActivityRepository.saveActivity(dayActivity)
        await send(.internal(.loadTimePeriods))
      }
    case .showCompletedActivitiesTapped:
      state.activityListOption = .extended
      return .none
    case .hideCompletedActivitiesTapped:
      state.activityListOption = .collapsed
      return .none
    case .reportButtonTapped:
      return .run { send in
        await send(.delegate(.reportsTapped))
      }
    case .selectedPeriod(let period):
      state.selectedPeriod = period
      return .none
    case .increaseButtonTapped:
      state.shift += 1
      return .run { send in
        await send(.internal(.loadTimePeriods))
      }
    case .decreaseButtonTapped:
      state.shift -= 1
      return .run { send in
        await send(.internal(.loadTimePeriods))
      }
    }
  }

  private func handleInteralAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .calendarDayChanged:
      return .run { send in
        await send(.internal(.loadTimePeriods))
      }
    case .loadTimePeriods:
      return .run { [period = state.selectedPeriod, shift = state.shift] send in
        let timePerdiod = try await timePeriodsProvider.timePeriod(period, today, shift)
        await send(.internal(.timePeriodLoaded(timePerdiod)))
      }
    case .timePeriodLoaded(let timePeriod):
      state.timePeriod = timePeriod
      setupTimePeriodConfiguration(&state, timePeriod: timePeriod)
      return .none
    case .removeDayActivity(let dayActivity):
      return .run { [dayActivity, dayToUpdate = state.selectedDay] send in
        try await dayEditor.removeDayActivity(dayActivity, dayToUpdate?.date ?? today)
        await send(.internal(.loadTimePeriods))
      }
    }
  }

  private func handleDayActivityFormAction(_ action: PresentationAction<DayActivityFormFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.activityUpdated(let dayActivity))):
      return .run { [dayActivity, dayToUpdate = state.selectedDay] send in
        try await dayEditor.updateDayActivity(dayActivity, dayToUpdate?.date ?? today)
        await send(.internal(.loadTimePeriods))
      }
    case .presented(.delegate(.activityDeleted(let dayActivity))):
      return .run { send in
        await send(.internal(.removeDayActivity(dayActivity)))
      }
    default:
      return .none
    }
  }

  private func handleActivityListAction(_ action: PresentationAction<ActivityListFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.activityAdded(let activity))):
      return .run { [activity, dayToUpdate = state.selectedDay] send in
        try await dayEditor.updateDayActivities(activity, dayToUpdate?.date ?? today)
        await send(.internal(.loadTimePeriods))
      }
    case .presented(.delegate(.activityUpdated(let activity))):
      return .run { [activity, dayToUpdate = state.selectedDay] send in
        try await dayEditor.updateDayActivities(activity, dayToUpdate?.date ?? today)
        await send(.internal(.loadTimePeriods))
      }
    case .presented(.delegate(.activitiesSelected(let activities))):
      return .run { [activities, dayToUpdate = state.selectedDay] send in
        for activity in activities {
          try await dayEditor.addActivity(activity, dayToUpdate?.date ?? today)
        }
        await send(.internal(.loadTimePeriods))
      }
    default:
      return .none
    }
  }

  private func handleActivityFormAction(_ action: PresentationAction<ActivityFormFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.activityCreated(let activity))):
      return .run { [activity, dayToUpdate = state.selectedDay] send in
        try await dayEditor.addActivity(activity, dayToUpdate?.date ?? today)
        await send(.internal(.loadTimePeriods))
      }
    default:
      return .none
    }
  }

  private func handleDayActivityTaskFormAction(_ action: PresentationAction<DayActivityTaskFormFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.dayActivityTaskDeleted(let dayActivityTask))):
      guard var dayActivityToEdit = state.dayActivityToEdit else { return .none }
      dayActivityToEdit.dayActivityTasks.removeAll(where: { $0.id ==  dayActivityTask.id })
      state.dayActivityToEdit = nil
      return .run { [dayActivityToEdit] send in
        try await dayActivityRepository.saveActivity(dayActivityToEdit)
        await send(.internal(.loadTimePeriods))
      }
    case .presented(.delegate(.dayActivityTaskUpdated(let dayActivityTask))):
      guard var dayActivityToEdit = state.dayActivityToEdit,
            let index = dayActivityToEdit.dayActivityTasks.firstIndex(where: { $0.id == dayActivityTask.id }) else { return .none }
      dayActivityToEdit.dayActivityTasks[index] = dayActivityTask
      state.dayActivityToEdit = nil
      return .run { [dayActivityToEdit] send in
        try await dayActivityRepository.saveActivity(dayActivityToEdit)
        await send(.internal(.loadTimePeriods))
      }
    case .dismiss:
      state.dayActivityToEdit = nil
      return .none
    default:
      return .none
    }
  }

  private func setupTimePeriodConfiguration(_ state: inout State, timePeriod: TimePeriod) {
    do {
      let presentationTypeProvider = ActivitiesPresentationTypeProvider()
      let presentationType = try presentationTypeProvider.presentationType(for: timePeriod)
      state.activitiesPresentationType = presentationType
      state.selectedDay = findSelectedDay(for: presentationType, currentSelectedDay: state.selectedDay)
      let filterDate = FilterDate(type: presentationType, dateRange: timePeriod.dateRange)
      state.activitiesPresentationTitle = try periodTitleProvider.title(for: filterDate)
    } catch {
      print(error)
    }
  }

  private func findSelectedDay(for presentationType: ActivitiesPresentationType, currentSelectedDay: Day?) -> Day? {
    switch presentationType {
    case .monthsList:
      return nil
    case .calendar(let calendarItems):
      let calendarDays = calendarItems.compactMap(\.day)
      let todayDay = calendarItems.first(where: {
        guard case .day(let day) = $0 else { return false }
        return day.date == today
      })?.day
      guard let currentSelectedDate = currentSelectedDay?.date else { return todayDay }
      return calendarDays.contains(where: { $0.date == currentSelectedDate })
      ? calendarItems.first(where: {
        guard case .day(let day) = $0 else { return false }
        return day.date == currentSelectedDay?.date
      })?.day
      : todayDay ?? calendarDays.first
    case .daysList(let style):
      switch style {
      case .single(let day):
        return day
      case .multi(let days):
        return days.contains(where: { $0.date == currentSelectedDay?.date })
        ? days.first(where: { $0.date == currentSelectedDay?.date })
        : days.first(where: { $0.date == today }) ?? days.first
      }
    }
  }
}
