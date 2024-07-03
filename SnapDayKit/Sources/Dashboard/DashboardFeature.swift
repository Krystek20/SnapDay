import Foundation
import ComposableArchitecture
import ActivityList
import DayActivityForm
import Repositories
import Utilities
import Models
import Common
import CalendarPicker
import Combine
import enum UiComponents.DayViewShowButtonState
import protocol UiComponents.InformationViewConfigurable
import struct UiComponents.DayNewActivity

@Reducer
public struct DashboardFeature: TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.dayActivityRepository) private var dayActivityRepository
  @Dependency(\.activityRepository) var activityRepository
  @Dependency(\.dayEditor) private var dayEditor
  @Dependency(\.uuid) private var uuid
  @Dependency(\.date) private var date
  @Dependency(\.calendar) private var calendar
  @Dependency(\.userNotificationCenterProvider) private var userNotificationCenterProvider
  private let dayProvider = DayProvider()

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable, TodayProvidable {

    public enum Field: Hashable {
      case name
    }

    var title: String {
      let formatter = DateFormatter()
      formatter.dateFormat = "EEEE, d MMM yyyy"
      return formatter.string(from: date ?? today)
    }

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
      let emptyDayConfiguration: EmptyDayConfiguration = selectedDay?.isOlderThenToday == true 
      ? .pastDay
      : .todayOrFuture
      return selectedDay?.activities.isEmpty == true ? emptyDayConfiguration : nil
    }

    var date: Date?
    var selectedDay: Day?
    var streamSetup: Bool = false
    var newActivity: DayNewActivity = DayNewActivity(
      name: "",
      isFormVisible: false
    )
    var activityListOption: ActivityListOption = .collapsed
    var focus: Field?

    @Presents var activityList: ActivityListFeature.State?
    @Presents var editDayActivity: DayActivityFormFeature.State?
    @Presents var dayActivityTaskForm: DayActivityFormFeature.State?
    @Presents var calendarPicker: CalendarPickerFeature.State?
    @Presents var dayActivityAlert: AlertState<Action.DayActivityAlert>?
    @Presents var dayActivityTaskAlert: AlertState<Action.DayActivityTaskAlert>?

    public init() { }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case newButtonTapped
      case doneNewButtonTapped
      case cancelNewButtonTapped
      case calendarButtonTapped
      case activityListButtonTapped
      case dayActivityActionPerfomed(DayActivityActionType)
      case showCompletedActivitiesTapped
      case hideCompletedActivitiesTapped
      case todayButtonTapped
      case increaseButtonTapped
      case decreaseButtonTapped
    }
    public enum InternalAction: Equatable {
      case showDatePicker
      case changesApplied(AppliedChanges)
      case loadDay
      case setDate(_ date: Date)
      case setDay(_ day: Day)
      case calendarDayChanged
      case dayActivityAction(DayActivityAction)
      case dayActivityTaskAction(DayActivityTaskAction)

      public enum DayActivityAction: Equatable {
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
        case showAlertSelectActivity(DayActivity)
        case save(DayActivity)
      }

      public enum DayActivityTaskAction: Equatable {
        case showNewForm(DayActivity)
        case showEditForm(DayActivityTask)
        case select(DayActivityTask)
        case create(DayActivityTask)
        case update(DayActivityTask)
        case remove(DayActivityTask)
      }
    }
    public enum DelegateAction: Equatable { }
    public enum DayActivityAlert: Equatable {
      case confirmTapped(dayActivity: DayActivity)
      case cancelTapped
    }
    public enum DayActivityTaskAlert: Equatable {
      case confirmTapped(dayActivity: DayActivity)
      case cancelTapped
    }

    case binding(BindingAction<State>)

    case dayActivityAlert(PresentationAction<DayActivityAlert>)
    case dayActivityTaskAlert(PresentationAction<DayActivityTaskAlert>)
    case activityList(PresentationAction<ActivityListFeature.Action>)
    case editDayActivity(PresentationAction<DayActivityFormFeature.Action>)
    case dayActivityTaskForm(PresentationAction<DayActivityFormFeature.Action>)
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
    .ifLet(\.$dayActivityTaskForm, action: \.dayActivityTaskForm) {
      DayActivityFormFeature()
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
          await send(.internal(.loadDay))
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
            await send(.internal(.loadDay))
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
    case .newButtonTapped:
      state.newActivity.isFormVisible = true
      state.focus = .name
      return .none
    case .doneNewButtonTapped:
      let name = state.newActivity.name
      state.newActivity.isFormVisible = false
      state.newActivity.name = ""
      state.focus = nil
      guard !name.isEmpty, let day = state.selectedDay else { return .none }
      return .run { [day] send in
        let dayActivity = DayActivity(
          id: uuid(),
          dayId: day.id,
          name: name,
          isGeneratedAutomatically: false
        )
        try await dayEditor.addDayActivity(dayActivity, day.date)
        await send(.internal(.loadDay))
      }
    case .cancelNewButtonTapped:
      state.newActivity.isFormVisible = false
      state.newActivity.name = ""
      state.focus = nil
      return .none
    case .calendarButtonTapped:
      return .send(.internal(.showDatePicker))
    case .activityListButtonTapped:
      guard let selectedDay = state.selectedDay else { return .none }
      state.activityList = ActivityListFeature.State(day: selectedDay)
      return .none
    case .dayActivityActionPerfomed(let actionType):
      return performDayActivityAction(actionType)
    case .showCompletedActivitiesTapped:
      state.activityListOption = .extended
      return .none
    case .hideCompletedActivitiesTapped:
      state.activityListOption = .collapsed
      return .none
    case .increaseButtonTapped:
      let currentDate = state.date ?? today
      state.date = calendar.date(byAdding: .day, value: 1, to: currentDate)
      return .send(.internal(.loadDay))
    case .decreaseButtonTapped:
      let currentDate = state.date ?? today
      state.date = calendar.date(byAdding: .day, value: -1, to: currentDate)
      return .send(.internal(.loadDay))
    case .todayButtonTapped:
      state.date = nil
      state.selectedDay = nil
      return .send(.internal(.loadDay))
    }
  }

  private func handleInternalAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .changesApplied(let appliedChanges):
      let shouldReload = appliedChanges.dates.contains { date in
        state.date == date
      }
      return .merge(
        .run { [shouldReload] send in
          guard shouldReload else { return }
          await send(.internal(.loadDay))
        }
      )
    case .calendarDayChanged:
      return .send(.internal(.loadDay))
    case .setDate(let date):
      state.date = date
      return .send(.internal(.loadDay))
    case .loadDay:
      return .run { [date = state.date] send in
        do {
          let day = try await dayProvider.day(date ?? today)
          await send(.internal(.setDay(day)))
        } catch {
          print("error: \(error)")
        }
      }
    case .setDay(let day):
      state.selectedDay = day
      return .run { _ in
        try await userNotificationCenterProvider.reloadReminders()
      }
    case .dayActivityAction(let action):
      return handleDayActivityAction(action, state: &state)
    case .dayActivityTaskAction(let action):
      return handleDayActivityTaskAction(action, state: &state)
    case .showDatePicker:
      guard let selectedDay = state.selectedDay else { return .none }
      state.calendarPicker = CalendarPickerFeature.State(
        type: .singleSelection(.noConfirmation),
        date: selectedDay.date,
        actionIdentifier: CalendarActivityAction.changeDate.rawValue
      )
      return .none
    }
  }

  private func performDayActivityAction(_ actionType: DayActivityActionType) -> Effect<Action> {
    switch actionType {
    case .dayActivity(let dayActivityAction, let dayActivity):
      switch dayActivityAction {
      case .tapped:
        .send(.internal(.dayActivityAction(.select(dayActivity))))
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
      case .save:
        .send(.internal(.dayActivityAction(.save(dayActivity))))
      }
    case .dayActivityTask(let dayActivityTaskAction, let dayActivityTask):
      switch dayActivityTaskAction {
      case .tapped:
        .send(.internal(.dayActivityTaskAction(.select(dayActivityTask))))
      case .edit:
        .send(.internal(.dayActivityTaskAction(.showEditForm(dayActivityTask))))
      case .remove:
        .send(.internal(.dayActivityTaskAction(.remove(dayActivityTask))))
      }
    }
  }

  private func handleDayActivityAction(_ action: Action.InternalAction.DayActivityAction, state: inout State) -> Effect<Action> {
    switch action {
    case .showEditForm(let dayActivity):
      guard let selectedDay = state.selectedDay else { return .none }
      state.editDayActivity = DayActivityFormFeature.State(
        form: DayActivityForm(dayActivity: dayActivity, showCompleted: true),
        type: .edit,
        editDate: selectedDay.date
      )
      return .none
    case .select(var dayActivity):
      dayActivity.doneDate = dayActivity.doneDate == nil ? date() : nil
      return .run { [dayActivity] send in
        try await dayActivityRepository.saveDayActivity(dayActivity)
        await send(.internal(.loadDay))
        try await userNotificationCenterProvider.reloadReminders()
        guard dayActivity.hasIncompletedSubtasksAndDone else { return }
        await send(.internal(.dayActivityAction(.showAlertSelectAll(dayActivity))))
      }
    case .create(let dayActivity):
      return .run { [dayActivity, selectedDay = state.selectedDay] send in
        try await dayEditor.addDayActivity(dayActivity, selectedDay?.date ?? today)
        await send(.internal(.loadDay))
      }
    case .update(let dayActivity):
      let activityBeforeUpdate = findActivity(id: dayActivity.id, state: state)
      let showAlertSelectAll = dayActivity.hasIncompletedSubtasksAndDone && activityBeforeUpdate?.isDone == false
      let showAlertSelectDayActivity = activityBeforeUpdate?.hasCompletedSubtasks == false && dayActivity.hasCompletedSubtasksAndNotDone
      return .run { [showAlertSelectAll, dayActivity, selectedDay = state.selectedDay] send in
        try await dayEditor.updateDayActivity(dayActivity, selectedDay?.date ?? today)
        await send(.internal(.loadDay))
        if showAlertSelectAll {
          await send(.internal(.dayActivityAction(.showAlertSelectAll(dayActivity))))
        } else if showAlertSelectDayActivity {
          await send(.internal(.dayActivityAction(.showAlertSelectActivity(dayActivity))))
        }
      }
    case .move(let dayActivity, let toDate):
      guard let fromDate = state.selectedDay?.date else { return .none }
      return .run { send in
        try await dayEditor.moveDayActivity(dayActivity, fromDate, toDate)
        await send(.internal(.loadDay))
      }
    case .copy(let dayActivity, let dates):
      return .run { send in
        try await dayEditor.copyDayActivity(dayActivity, dates)
        await send(.internal(.loadDay))
      }
    case .remove(let dayActivity):
      return .run { [dayActivity, selectedDay = state.selectedDay] send in
        try await dayEditor.removeDayActivity(dayActivity, selectedDay?.date ?? today)
        await send(.internal(.loadDay))
      }
    case .showDatePicker(let dayActivity):
      guard let selectedDay = state.selectedDay else { return .none }
      state.calendarPicker = CalendarPickerFeature.State(
        type: .singleSelection(.navigationButton(title: String(localized: "Move", bundle: .module))),
        date: selectedDay.date,
        objectIdentifier: dayActivity.id.uuidString,
        actionIdentifier: CalendarActivityAction.move.rawValue
      )
      return .none
    case .showMultiDatePicker(let dayActivity):
      guard let selectedDay = state.selectedDay else { return .none }
      state.calendarPicker = CalendarPickerFeature.State(
        type: .multiSelection(title: String(localized: "Copy", bundle: .module)),
        date: selectedDay.date,
        objectIdentifier: dayActivity.id.uuidString,
        actionIdentifier: CalendarActivityAction.copy.rawValue
      )
      return .none
    case .showAlertSelectAll(let dayActivity):
      state.dayActivityAlert = AlertState<Action.DayActivityAlert>.showAlertSelectAll(
        confirmAction: .confirmTapped(dayActivity: dayActivity),
        cancelAction: .cancelTapped
      )
      return .none
    case .showAlertSelectActivity(let dayActivity):
      state.dayActivityTaskAlert = AlertState<Action.DayActivityTaskAlert>.dayActivityTaskAlert(
        confirmAction: .confirmTapped(dayActivity: dayActivity),
        cancelAction: .cancelTapped
      )
      return .none
    case .save(var dayActivity):
      guard let selectedDay = state.selectedDay else { return .none }
      let activity = Activity(
        uuid: { uuid() },
        startDate: selectedDay.date,
        dayActivity: dayActivity
      )
      dayActivity.activity = activity
      return .run { [dayActivity, activity] send in
        try await activityRepository.saveActivity(activity)
        if #available(iOS 17.0, *) {
          SaveActivityTip.show = true
        }
        try await dayActivityRepository.saveDayActivity(dayActivity)
        await send(.internal(.loadDay))
      }
    }
  }

  private func handleDayActivityTaskAction(_ action: Action.InternalAction.DayActivityTaskAction, state: inout State) -> Effect<Action> {
    switch action {
    case .showNewForm(let dayActivity):
      guard let day = state.selectedDay else { return .none }
      state.dayActivityTaskForm = DayActivityFormFeature.State(
        form: DayActivityForm(
          dayActivityTask: DayActivityTask(
            id: uuid(),
            dayActivityId: dayActivity.id
          ),
          showCompleted: true
        ),
        type: .new,
        editDate: day.date
      )
      return .none
    case .showEditForm(let dayActivityTask):
      guard let day = state.selectedDay else { return .none }
      state.dayActivityTaskForm = DayActivityFormFeature.State(
        form: DayActivityForm(dayActivityTask: dayActivityTask, showCompleted: true),
        type: .edit,
        editDate: day.date
      )
      return .none
    case .select(var dayActivityTask):
      dayActivityTask.doneDate = dayActivityTask.doneDate == nil ? date() : nil
      return .run { [dayActivityTask] send in
        try await dayActivityRepository.saveDayActivityTask(dayActivityTask)
        await send(.internal(.loadDay))
        try await userNotificationCenterProvider.reloadReminders()
        guard let dayActivity = try await dayActivityRepository.activity(dayActivityTask.dayActivityId.uuidString),
              dayActivity.hasCompletedSubtasksAndNotDone else { return }
        await send(.internal(.dayActivityAction(.showAlertSelectActivity(dayActivity))))
      }
    case .create(let dayActivityTask):
      guard var dayActivity = state.selectedDay?.activities.first(where: { $0.id == dayActivityTask.dayActivityId }) else { return .none }
      dayActivity.dayActivityTasks.append(dayActivityTask)
      return .run { [dayActivity] send in
        try await dayActivityRepository.saveDayActivity(dayActivity)
        await send(.internal(.loadDay))
      }
    case .update(let dayActivityTask):
      let dayActivityTaskBeforeUpdate = findActivityTask(id: dayActivityTask.id, activityId: dayActivityTask.dayActivityId, state: state)
      let wasCompleted = dayActivityTaskBeforeUpdate?.isDone == false && dayActivityTask.isDone
      return .run { [wasCompleted, dayActivityTask] send in
        try await dayActivityRepository.saveDayActivityTask(dayActivityTask)
        await send(.internal(.loadDay))
        guard wasCompleted,
              let dayActivity = try await dayActivityRepository.activity(dayActivityTask.dayActivityId.uuidString),
              dayActivity.hasCompletedSubtasksAndNotDone
        else { return }
        await send(.internal(.dayActivityAction(.showAlertSelectActivity(dayActivity))))
      }
    case .remove(let dayActivityTask):
      return .run { [dayActivityTask] send in
        try await dayActivityRepository.removeDayActivityTask(dayActivityTask)
        await send(.internal(.loadDay))
      }
    }
  }

  private func handleDayActivityFormAction(_ action: PresentationAction<DayActivityFormFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.activityCreated(let form))):
      guard let dayActivity = DayActivity(form: form) else { return .none }
      return .send(.internal(.dayActivityAction(.create(dayActivity))))
    case .presented(.delegate(.activityUpdated(let form))):
      guard var dayActivity = findActivity(id: form.id, state: state) else { return .none }
      dayActivity.update(by: form)
      return .send(.internal(.dayActivityAction(.update(dayActivity))))
    case .presented(.delegate(.activityDeleted(let form))):
      guard let dayActivity = findActivity(id: form.id, state: state) else { return .none }
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
        await send(.internal(.loadDay))
      }
    case .presented(.delegate(.activityUpdated(let activity))):
      return .run { [activity, dayToUpdate = state.selectedDay] send in
        try await dayEditor.updateDayActivities(activity, dayToUpdate?.date ?? today)
        await send(.internal(.loadDay))
      }
    case .presented(.delegate(.activityDeleted)):
      return .send(.internal(.loadDay))
    case .presented(.delegate(.activitiesSelected(let activities))):
      guard let selectedDay = state.selectedDay else { return .none }
      return .run { [activities, dayToUpdate = selectedDay] send in
        for activity in activities {
          let dayActivity = DayActivity.create(
            from: activity,
            uuid: { uuid() },
            calendar: { calendar },
            dayId: dayToUpdate.id,
            dayDate: dayToUpdate.date,
            createdByUser: true
          )
          try await dayEditor.addDayActivity(dayActivity, dayToUpdate.date)
        }
        await send(.internal(.loadDay))
      }
    default:
      return .none
    }
  }

  private func handleDayActivityTaskFormAction(_ action: PresentationAction<DayActivityFormFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.activityCreated(let form))):
      guard let dayActivityTask = DayActivityTask(form: form) else { return .none }
      return .send(.internal(.dayActivityTaskAction(.create(dayActivityTask))))
    case .presented(.delegate(.activityUpdated(let form))):
      guard var dayActivityTask = findActivityTask(form: form, state: state) else { return .none }
      dayActivityTask.update(by: form)
      return .send(.internal(.dayActivityTaskAction(.update(dayActivityTask))))
    case .presented(.delegate(.activityDeleted(let form))):
      guard let dayActivityTask = findActivityTask(form: form, state: state) else { return .none }
      return .send(.internal(.dayActivityTaskAction(.remove(dayActivityTask))))
    default:
      return .none
    }
  }

  private func handleDayActivityAlertAction(_ action: PresentationAction<Action.DayActivityAlert>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.cancelTapped):
      state.dayActivityAlert = nil
      return .none
    case .presented(.confirmTapped(let dayActivity)):
      state.dayActivityAlert = nil
      return .run { send in
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
    case .presented(.cancelTapped):
      state.dayActivityTaskAlert = nil
      return .none
    case .presented(.confirmTapped(let dayActivity)):
      state.dayActivityTaskAlert = nil
      return .send(.internal(.dayActivityAction(.select(dayActivity))))
    default:
      return .none
    }
  }

  private func handleCalendarPickerAction(_ action: PresentationAction<CalendarPickerFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.datesSelected(let dates, let objectIdentifier, let actionIdentifier))):
      guard let actionIdentifier,
            let action = CalendarActivityAction(rawValue: actionIdentifier) else { return .none }
      return .run { [objectIdentifier, action, dates] send in
        switch action {
        case .copy:
          guard let objectIdentifier,
                let dayActivity = try await dayActivityRepository.activity(objectIdentifier) else { return }
          await send(.internal(.dayActivityAction(.copy(dayActivity, dates: dates))))
        case .move:
          guard let objectIdentifier,
                let dayActivity = try await dayActivityRepository.activity(objectIdentifier),
                let firstDate = dates.first else { return }
          await send(.internal(.dayActivityAction(.move(dayActivity, date: firstDate))))
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

  private func findActivityTask(form: DayActivityForm, state: State) -> DayActivityTask? {
    findActivityTask(id: form.id, activityId: form.ids[.parentId], state: state)
  }

  private func findActivityTask(id: UUID?, activityId: UUID?, state: State) -> DayActivityTask? {
    findActivity(id: activityId, state: state)?.dayActivityTasks.first(where: { $0.id == id })
  }

  private func findActivity(id: UUID?, state: State) -> DayActivity? {
    state.selectedDay?.activities.first(where: { $0.id == id })
  }
}
