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
import CalendarPicker
import Combine
import enum UiComponents.DayViewShowButtonState
import protocol UiComponents.InformationViewConfigurable

@Reducer
public struct DashboardFeature: TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.timePeriodsProvider) private var timePeriodsProvider
  @Dependency(\.dayActivityRepository) private var dayActivityRepository
  @Dependency(\.dayEditor) private var dayEditor
  @Dependency(\.uuid) private var uuid
  @Dependency(\.date) private var date
  @Dependency(\.calendar) private var calendar
  @Dependency(\.userNotificationCenterProvider) private var userNotificationCenterProvider
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

    var daySummary: DaySummary? {
      guard let selectedDay else { return nil }
      return DaySummary(day: selectedDay)
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
    var streamSetup: Bool = false

    @Presents var activityList: ActivityListFeature.State?
    @Presents var editDayActivity: DayActivityFormFeature.State?
    @Presents var addActivity: ActivityFormFeature.State?
    @Presents var dayActivityTaskForm: DayActivityTaskFormFeature.State?
    @Presents var calendarPicker: CalendarPickerFeature.State?
    @Presents var dayActivityAlert: AlertState<Action.DayActivityAlert>?
    @Presents var dayActivityTaskAlert: AlertState<Action.DayActivityTaskAlert>?

    public init() { }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case activityListButtonTapped
      case addDayActivityButtonTapped
      case dayActivityActionPerfomed(DayActivityActionType)
      case showCompletedActivitiesTapped
      case hideCompletedActivitiesTapped
      case reportButtonTapped
      case todayButtonTapped
      case selectedPeriod(Period)
      case increaseButtonTapped
      case decreaseButtonTapped
    }
    public enum InternalAction: Equatable {
      case changesApplied(AppliedChanges)
      case loadTimePeriods
      case timePeriodLoaded(_ timePeriod: TimePeriod)
      case calendarDayChanged
      case dayActivityAction(DayActivityAction)
      case dayActivityTaskAction(DayActivityTaskAction)

      public enum DayActivityAction: Equatable {
        case showNewForm
        case showEditForm(DayActivity)
        case select(DayActivity)
        case create(DayActivity)
        case update(DayActivity)
        case copy(DayActivity, dates: [Date])
        case move(DayActivity, date: Date)
        case remove(DayActivity)
        case showDatePicker(DayActivity)
        case showMultiDatePicker(DayActivity)
        case showAlertSelectAll(DayActivity)
      }

      public enum DayActivityTaskAction: Equatable {
        case showNewForm(DayActivity)
        case showEditForm(DayActivityTask)
        case select(DayActivityTask)
        case create(DayActivityTask)
        case update(DayActivityTask)
        case remove(DayActivityTask)
        case showAlertSelectActivity(DayActivity, DayActivityTask)
      }
    }
    public enum DelegateAction: Equatable {
      case reportsTapped
    }
    public enum DayActivityAlert: Equatable {
      case confirmTapped(dayActivity: DayActivity)
      case cancelTapped(dayActivity: DayActivity)
    }
    public enum DayActivityTaskAlert: Equatable {
      case confirmTapped(dayActivity: DayActivity, dayActivityTask: DayActivityTask)
      case cancelTapped(dayActivityTask: DayActivityTask)
    }

    case binding(BindingAction<State>)

    case dayActivityAlert(PresentationAction<DayActivityAlert>)
    case dayActivityTaskAlert(PresentationAction<DayActivityTaskAlert>)
    case activityList(PresentationAction<ActivityListFeature.Action>)
    case editDayActivity(PresentationAction<DayActivityFormFeature.Action>)
    case addActivity(PresentationAction<ActivityFormFeature.Action>)
    case dayActivityTaskForm(PresentationAction<DayActivityTaskFormFeature.Action>)
    case calendarPicker(PresentationAction<CalendarPickerFeature.Action>)

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
        return handleInternalAction(internalAction, state: &state)
      case .editDayActivity(let action):
        return handleDayActivityFormAction(action, state: &state)
      case .activityList(let action):
        return handleActivityListAction(action, state: &state)
      case .addActivity(let action):
        return handleActivityFormAction(action, state: &state)
      case .dayActivityTaskForm(let action):
        return handleDayActivityTaskFormAction(action, state: &state)
      case .calendarPicker(let action):
        return handleCalendarPickerAction(action, state: &state)
      case .dayActivityAlert(let action):
        return handleDayActivityAlertAction(action, state: &state)
      case .dayActivityTaskAlert(let action):
        return handleDayActivityTaskAlertAction(action, state: &state)
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
    .ifLet(\.$calendarPicker, action: \.calendarPicker) {
      CalendarPickerFeature()
    }
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Private

  private func handleViewAction(_ action: Action.ViewAction, state: inout State) -> Effect<Action> {
    switch action {
    case .appeared:
      guard !state.streamSetup else { return .none }
      state.streamSetup = true
      return .merge(
        .run { send in
          await send(.internal(.loadTimePeriods))
        },
        .run { send in
          for await notification in NotificationCenter.default.publisher(for: .snapDayStoreDidChange).values {
            guard let userInfo = notification.object as? [UserInfoKey: Any],
                  let transactions = userInfo[.transactions] as? Transactions else { return }
            let appliedChanges = try await dayEditor.applyChanges(transactions)
            await send(.internal(.changesApplied(appliedChanges)))
          }
        },
        .run { send in
          for await _ in userNotificationCenterProvider.userActionStream {
            await send(.internal(.loadTimePeriods))
          }
        },
        .run { send in
          try await userNotificationCenterProvider.schedule(
            userNotification: EveningSummary(calendar: calendar)
          )
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
    case .addDayActivityButtonTapped:
      return .send(.internal(.dayActivityAction(.showNewForm)))
    case .dayActivityActionPerfomed(let actionType):
      return performDayActivityAction(actionType)
    case .showCompletedActivitiesTapped:
      state.activityListOption = .extended
      return .none
    case .hideCompletedActivitiesTapped:
      state.activityListOption = .collapsed
      return .none
    case .reportButtonTapped:
      return .send(.delegate(.reportsTapped))
    case .selectedPeriod(let period):
      state.selectedPeriod = period
      return .none
    case .increaseButtonTapped:
      state.shift += 1
      return .send(.internal(.loadTimePeriods))
    case .decreaseButtonTapped:
      state.shift -= 1
      return .send(.internal(.loadTimePeriods))
    case .todayButtonTapped:
      state.shift = .zero
      state.selectedDay = nil
      return .send(.internal(.loadTimePeriods))
    }
  }

  private func handleInternalAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .changesApplied(let appliedChanges):
      let shouldReload = appliedChanges.dates.contains { date in
        state.timePeriod?.dateRange.contains(date) ?? false
      }
      return .merge(
        .run { [shouldReload] send in
          guard shouldReload else { return }
          await send(.internal(.loadTimePeriods))
        }
      )
    case .calendarDayChanged:
      return .send(.internal(.loadTimePeriods))
    case .loadTimePeriods:
      return .run { [period = state.selectedPeriod, shift = state.shift] send in
        do {
          let timePerdiod = try await timePeriodsProvider.timePeriod(period, today, shift)
          await send(.internal(.timePeriodLoaded(timePerdiod)))
        } catch {
          print("error: \(error)")
        }
      }
    case .timePeriodLoaded(let timePeriod):
      state.timePeriod = timePeriod
      setupTimePeriodConfiguration(&state, timePeriod: timePeriod)
      return .run { _ in
        try await userNotificationCenterProvider.reloadReminders()
      }
    case .dayActivityAction(let action):
      return handleDayActivityAction(action, state: &state)
    case .dayActivityTaskAction(let action):
      return handleDayActivityTaskAction(action, state: &state)
    }
  }

  private func performDayActivityAction(_ actionType: DayActivityActionType) -> Effect<Action> {
    switch actionType {
    case .dayActivity(let dayActivityAction, let dayActivity):
      switch dayActivityAction {
      case .tapped:
        dayActivity.areAllSubtasksDone
        ? .send(.internal(.dayActivityAction(.showAlertSelectAll(dayActivity))))
        : .send(.internal(.dayActivityAction(.select(dayActivity))))
      case .edit:
        .send(.internal(.dayActivityAction(.showEditForm(dayActivity))))
      case .copy:
        .send(.internal(.dayActivityAction(.showMultiDatePicker(dayActivity))))
      case .move:
        .send(.internal(.dayActivityAction(.showDatePicker(dayActivity))))
      case .remove:
        .send(.internal(.dayActivityAction(.remove(dayActivity))))
      case .addActivityTask:
        .send(.internal(.dayActivityTaskAction(.showNewForm(dayActivity))))
      }
    case .dayActivityTask(let dayActivityTaskAction, let dayActivityTask):
      switch dayActivityTaskAction {
      case .tapped:
        .run { send in
          guard let dayActivity = try await dayActivityRepository.activity(dayActivityTask.dayActivityId.uuidString) else { return }
          if dayActivity.areAllSubtasksDone(exclude: dayActivityTask) {
            await send(.internal(.dayActivityTaskAction(.showAlertSelectActivity(dayActivity, dayActivityTask))))
          } else {
            await send(.internal(.dayActivityTaskAction(.select(dayActivityTask))))
          }
        }
      case .edit:
        .send(.internal(.dayActivityTaskAction(.showEditForm(dayActivityTask))))
      case .remove:
        .send(.internal(.dayActivityTaskAction(.remove(dayActivityTask))))
      }
    }
  }

  private func handleDayActivityAction(_ action: Action.InternalAction.DayActivityAction, state: inout State) -> Effect<Action> {
    switch action {
    case .showNewForm:
      guard let selectedDay = state.selectedDay else { return .none }
      state.editDayActivity = DayActivityFormFeature.State(
        type: .new,
        dayActivity: DayActivity(
          id: uuid(),
          dayId: selectedDay.id,
          isGeneratedAutomatically: false
        ),
        availableDateHours: calendar.currentDateRange(selectedDay.date)
      )
      return .none
    case .showEditForm(let dayActivity):
      guard let selectedDay = state.selectedDay else { return .none }
      state.editDayActivity = DayActivityFormFeature.State(
        type: .edit,
        dayActivity: dayActivity,
        availableDateHours: calendar.currentDateRange(selectedDay.date)
      )
      return .none
    case .select(var dayActivity):
      dayActivity.doneDate = dayActivity.doneDate == nil ? date() : nil
      return .run { [dayActivity] send in
        try await dayActivityRepository.saveActivity(dayActivity)
        await send(.internal(.loadTimePeriods))
      }
    case .create(let dayActivity):
      return .run { [dayActivity, selectedDay = state.selectedDay] send in
        try await dayEditor.addDayActivity(dayActivity, selectedDay?.date ?? today)
        await send(.internal(.loadTimePeriods))
      }
    case .update(let dayActivity):
      return .run { [dayActivity, selectedDay = state.selectedDay] send in
        try await dayEditor.updateDayActivity(dayActivity, selectedDay?.date ?? today)
        await send(.internal(.loadTimePeriods))
      }
    case .move(let dayActivity, let toDate):
      guard let fromDate = state.selectedDay?.date else { return .none }
      return .run { send in
        try await dayEditor.moveDayActivity(dayActivity, fromDate, toDate)
        await send(.internal(.loadTimePeriods))
      }
    case .copy(let dayActivity, let dates):
      return .run { send in
        try await dayEditor.copyDayActivity(dayActivity, dates)
        await send(.internal(.loadTimePeriods))
      }
    case .remove(let dayActivity):
      return .run { [dayActivity, selectedDay = state.selectedDay] send in
        try await dayEditor.removeDayActivity(dayActivity, selectedDay?.date ?? today)
        await send(.internal(.loadTimePeriods))
      }
    case .showDatePicker(let dayActivity):
      guard let selectedDay = state.selectedDay else { return .none }
      state.calendarPicker = CalendarPickerFeature.State(
        type: .singleSelection,
        date: selectedDay.date,
        objectIdentifier: dayActivity.id.uuidString,
        actionIdentifier: CalendarActivityAction.move.rawValue,
        buttonTitle: String(localized: "Move", bundle: .module)
      )
      return .none
    case .showMultiDatePicker(let dayActivity):
      guard let selectedDay = state.selectedDay else { return .none }
      state.calendarPicker = CalendarPickerFeature.State(
        type: .multiSelection,
        date: selectedDay.date,
        objectIdentifier: dayActivity.id.uuidString,
        actionIdentifier: CalendarActivityAction.copy.rawValue,
        buttonTitle: String(localized: "Copy", bundle: .module)
      )
      return .none
    case .showAlertSelectAll(let dayActivity):
      state.dayActivityAlert = AlertState<Action.DayActivityAlert>.showAlertSelectAll(
        confirmAction: .confirmTapped(dayActivity: dayActivity),
        cancelAction: .cancelTapped(dayActivity: dayActivity)
      )
      return .none
    }
  }

  private func handleDayActivityTaskAction(_ action: Action.InternalAction.DayActivityTaskAction, state: inout State) -> Effect<Action> {
    switch action {
    case .showNewForm(let dayActivity):
      guard let day = state.selectedDay else { return .none }
      state.dayActivityTaskForm = DayActivityTaskFormFeature.State(
        dayActivityTask: DayActivityTask(
          id: uuid(),
          dayActivityId: dayActivity.id
        ),
        type: .new,
        availableDateHours: calendar.currentDateRange(day.date)
      )
      return .none
    case .showEditForm(let dayActivityTask):
      guard let day = state.selectedDay else { return .none }
      state.dayActivityTaskForm = DayActivityTaskFormFeature.State(
        dayActivityTask: dayActivityTask,
        type: .edit,
        availableDateHours: calendar.currentDateRange(day.date)
      )
      return .none
    case .select(var dayActivityTask):
      dayActivityTask.doneDate = dayActivityTask.doneDate == nil ? date() : nil
      return .run { [dayActivityTask] send in
        try await dayActivityRepository.saveActivityTask(dayActivityTask)
        await send(.internal(.loadTimePeriods))
      }
    case .create(let dayActivityTask):
      guard var dayActivity = state.selectedDay?.activities.first(where: { $0.id == dayActivityTask.dayActivityId }) else { return .none }
      dayActivity.dayActivityTasks.append(dayActivityTask)
      return .run { [dayActivity] send in
        try await dayActivityRepository.saveActivity(dayActivity)
        await send(.internal(.loadTimePeriods))
      }
    case .update(let dayActivityTask):
      return .run { [dayActivityTask] send in
        try await dayActivityRepository.saveActivityTask(dayActivityTask)
        await send(.internal(.loadTimePeriods))
      }
    case .remove(let dayActivityTask):
      return .run { [dayActivityTask] send in
        try await dayActivityRepository.removeDayActivityTask(dayActivityTask)
        await send(.internal(.loadTimePeriods))
      }
    case .showAlertSelectActivity(let dayActivity, let dayActivityTask):
      state.dayActivityTaskAlert = AlertState<Action.DayActivityTaskAlert>.dayActivityTaskAlert(
        confirmAction: .confirmTapped(dayActivity: dayActivity, dayActivityTask: dayActivityTask),
        cancelAction: .cancelTapped(dayActivityTask: dayActivityTask)
      )
      return .none
    }
  }

  private func handleDayActivityFormAction(_ action: PresentationAction<DayActivityFormFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.activityCreated(let dayActivity))):
      return .send(.internal(.dayActivityAction(.create(dayActivity))))
    case .presented(.delegate(.activityUpdated(let dayActivity))):
      return .send(.internal(.dayActivityAction(.update(dayActivity))))
    case .presented(.delegate(.activityDeleted(let dayActivity))):
      return .send(.internal(.dayActivityAction(.remove(dayActivity))))
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
      return .run { [activity, selectedDay = state.selectedDay] send in
        try await dayEditor.addActivity(activity, selectedDay?.date ?? today)
        await send(.internal(.loadTimePeriods))
      }
    default:
      return .none
    }
  }

  private func handleDayActivityTaskFormAction(_ action: PresentationAction<DayActivityTaskFormFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.dayActivityTaskCreated(let dayActivityTask))):
      return .send(.internal(.dayActivityTaskAction(.create(dayActivityTask))))
    case .presented(.delegate(.dayActivityTaskUpdated(let dayActivityTask))):
      return .send(.internal(.dayActivityTaskAction(.update(dayActivityTask))))
    case .presented(.delegate(.dayActivityTaskDeleted(let dayActivityTask))):
      return .send(.internal(.dayActivityTaskAction(.remove(dayActivityTask))))
    default:
      return .none
    }
  }

  private func handleDayActivityAlertAction(_ action: PresentationAction<Action.DayActivityAlert>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.cancelTapped(let dayActivity)):
      state.dayActivityAlert = nil
      return .send(.internal(.dayActivityAction(.select(dayActivity))))
    case .presented(.confirmTapped(let dayActivity)):
      state.dayActivityAlert = nil
      return .run { send in
        await send(.internal(.dayActivityAction(.select(dayActivity))))
        for dayActivityTask in dayActivity.dayActivityTasks {
          guard !dayActivityTask.isDone else { continue }
          await send(.internal(.dayActivityTaskAction(.select(dayActivityTask))))
        }
      }
    default:
      return .none
    }
  }

  private func handleDayActivityTaskAlertAction(_ action: PresentationAction<Action.DayActivityTaskAlert>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.cancelTapped(let dayActivityTask)):
      state.dayActivityTaskAlert = nil
      return .send(.internal(.dayActivityTaskAction(.select(dayActivityTask))))
    case .presented(.confirmTapped(let dayActivity, let dayActivityTask)):
      state.dayActivityTaskAlert = nil
      return .run { send in
        await send(.internal(.dayActivityAction(.select(dayActivity))))
        await send(.internal(.dayActivityTaskAction(.select(dayActivityTask))))
      }
    default:
      return .none
    }
  }

  private func handleCalendarPickerAction(_ action: PresentationAction<CalendarPickerFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.datesSelected(let dates, let objectIdentifier, let actionIdentifier))):
      guard let objectIdentifier, let actionIdentifier, let action = CalendarActivityAction(rawValue: actionIdentifier) else { return .none }
      return .run { [objectIdentifier, action, dates] send in
        guard let dayActivity = try await dayActivityRepository.activity(objectIdentifier) else { return }
        switch action {
        case .copy:
          await send(.internal(.dayActivityAction(.copy(dayActivity, dates: dates))))
        case .move:
          guard let firstDate = dates.first else { return }
          await send(.internal(.dayActivityAction(.move(dayActivity, date: firstDate))))
        }
      }
    case .dismiss:
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
