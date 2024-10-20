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
import WidgetKit

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
  @Dependency(\.deeplinkService) private var deeplinkService
  private let dayProvider = DayProvider()

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable, TodayProvidable {

    var title: String {
      let formatter = DateFormatter()
      formatter.dateFormat = "EEEE, d MMM yyyy"
      return formatter.string(from: date)
    }

    var daySummary: DaySummary? {
      guard let selectedDay else { return nil }
      return DaySummary(day: selectedDay)
    }

    var activities: [DayActivity] {
      @Dependency(\.calendar) var calendar
      return switch activityListOption {
      case .collapsed:
        selectedDay?.activities.filter { !$0.isDone } ?? []
      case .extended:
        selectedDay?.activities ?? []
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

    var dayInformation: InformationViewConfiguration? {
      guard let selectedDay, !newActivity.isFormVisible, !loading else { return nil }
      if selectedDay.activities.allSatisfy(\.isDone) && !selectedDay.activities.isEmpty {
        return .todaySuccess
      } else if selectedDay.activities.isEmpty {
        return selectedDay.date < today
        ? .pastDay
        : .todayOrFuture
      }
      return nil
    }

    var loading = false
    var date: Date
    var selectedDay: Day?
    var streamSetup = false
    var newActivity = DayNewActivity.empty
    var newActivityTask = DayNewActivityTask.empty
    var activityListOption: ActivityListOption = .collapsed
    var focus: DayNewField?
    var alert: DashboardAlert?

    @Presents var activityList: ActivityListFeature.State?
    @Presents var editDayActivity: DayActivityFormFeature.State?
    @Presents var dayActivityTaskForm: DayActivityFormFeature.State?
    @Presents var calendarPicker: CalendarPickerFeature.State?

    public init(date: Date) {
      self.date = date
    }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case newButtonTapped
      case newActivityActionPerformed(DayNewActivityAction)
      case calendarButtonTapped
      case activityListButtonTapped
      case dayActivityActionPerfomed(DayActivityActionType)
      case showCompletedActivitiesTapped
      case hideCompletedActivitiesTapped
      case todayButtonTapped
      case increaseButtonTapped
      case decreaseButtonTapped
      case confirmAlertButtonTapped
      case cancelAlertButtonTapped
    }
    public enum InternalAction: Equatable {
      case changesApplied(AppliedChanges)
      case loadDay
      case setDate(_ date: Date)
      case setDay(_ day: Day)
      case calendarDayChanged
      case handleDeepLink(DeeplinkService.DashboardAction?)
      case dayActivityAction(DayActivityAction)
      case dayActivityTaskAction(DayActivityTaskAction)
      case saveOrder

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
        case showAlertSelectActivity(DayActivity)
        case save(DayActivity)
        case reorder(DayActivity, DayActivity)
        case setImportant(Bool, DayActivity)
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

    case binding(BindingAction<State>)
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
        .run { _ in
          try await userNotificationCenterProvider.schedule(
            userNotification: EveningSummary(calendar: calendar)
          )
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
    case .newButtonTapped:
      return .send(.internal(.dayActivityAction(.showNewForm)))
    case .newActivityActionPerformed(let action):
      return handleDayNewActivityAction(action, state: &state)
    case .calendarButtonTapped:
      showDatePicker(state: &state)
      return .none
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
      state.date = calendar.date(byAdding: .day, value: 1, to: state.date) ?? state.date
      return .send(.internal(.loadDay))
    case .decreaseButtonTapped:
      state.date = calendar.date(byAdding: .day, value: -1, to: state.date) ?? state.date
      return .send(.internal(.loadDay))
    case .todayButtonTapped:
      state.date = today
      state.selectedDay = nil
      return .send(.internal(.loadDay))
    case .confirmAlertButtonTapped:
      defer { state.alert = nil }
      guard let alert = state.alert else { return .none }
      switch alert.type {
      case .incompleteSubtasks(let dayActivity):
        return .run { send in
          for dayActivityTask in dayActivity.dayActivityTasks {
            guard !dayActivityTask.isDone else { continue }
            await send(.internal(.dayActivityTaskAction(.select(dayActivityTask))))
          }
        }
      case .completeActivity(let dayActivity):
        return .send(.internal(.dayActivityAction(.select(dayActivity))))
      }
    case .cancelAlertButtonTapped:
      state.alert = nil
      return .none
    }
  }

  private func handleInternalAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .changesApplied(let appliedChanges):
      let shouldReload = appliedChanges.dates.contains { date in
        state.date == date
      }
      return .run { [shouldReload] send in
          guard shouldReload else { return }
          await send(.internal(.loadDay))
        }
    case .calendarDayChanged:
      return .send(.internal(.loadDay))
    case .setDate(let date):
      state.date = date
      return .send(.internal(.loadDay))
    case .loadDay:
      state.loading = true
      return .run { [date = state.date] send in
        do {
          let day = try await dayProvider.day(date)
          await send(.internal(.setDay(day)))
          if date == today {
            WidgetCenter.shared.reloadAllTimelines()
          }
        } catch {
          print("error: \(error)")
        }
      }
    case .setDay(let day):
      state.selectedDay = day
      state.loading = false
      return .run { _ in
        try await userNotificationCenterProvider.reloadReminders()
      }
    case .dayActivityAction(let action):
      return handleDayActivityAction(action, state: &state)
    case .dayActivityTaskAction(let action):
      return handleDayActivityTaskAction(action, state: &state)
    case .handleDeepLink(let deeplink):
      deeplinkService.consume()
      guard let deeplink else { return .none }
      state.activityList = nil
      state.editDayActivity = nil
      state.dayActivityTaskForm = nil
      state.calendarPicker = nil
      state.alert = nil
      switch deeplink {
      case .addActivity:
        return .send(.internal(.dayActivityAction(.showNewForm)))
      }
    case .saveOrder:
      guard var selectedDay = state.selectedDay else { return .none }
      for index in selectedDay.activities.indices {
        selectedDay.activities[index].position = index
      }

      return .run { [selectedDay] send in
        try await dayEditor.saveDay(selectedDay)
        await send(.internal(.loadDay))
      }
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
      case .reorder(let action):
        switch action {
        case .perform(let destination):
          .send(.internal(.dayActivityAction(.reorder(dayActivity, destination))))
        case .drop:
          .send(.internal(.saveOrder))
        }
      case .markImportant:
        .send(.internal(.dayActivityAction(.setImportant(true, dayActivity))))
      case .unmarkImportant:
        .send(.internal(.dayActivityAction(.setImportant(false, dayActivity))))
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
    case .showNewForm:
      state.newActivityTask = .empty
      state.newActivity.isFormVisible = true
      state.focus = .activityName
      return .none
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
      state.loading = true
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
      return .run { send in
        try await dayEditor.moveDayActivity(dayActivity, toDate)
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
      state.alert = DashboardAlert(
        type: .incompleteSubtasks(dayActivity: dayActivity),
        configuration: .incompleteSubtasks
      )
      return .none
    case .showAlertSelectActivity(let dayActivity):
      state.alert = DashboardAlert(
        type: .completeActivity(dayActivity: dayActivity),
        configuration: .completeActivity
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
    case .reorder(let dayActivity, let destinationDayActivity):
      guard dayActivity.priority(calendar: calendar) == destinationDayActivity.priority(calendar: calendar),
            let fromIndex = state.selectedDay?.activities.firstIndex(of: dayActivity),
            let toIndex = state.selectedDay?.activities.firstIndex(of: destinationDayActivity),
            fromIndex != toIndex else { return .none }

      state.selectedDay?.activities.move(
        fromOffsets: IndexSet(integer: fromIndex),
        toOffset: (toIndex > fromIndex ? (toIndex + 1) : toIndex)
      )
      return .none
    case .setImportant(let isImportant, let dayActivity):
      guard var dayActivity = findActivity(id: dayActivity.id, state: state) else { return .none }
      dayActivity.important = isImportant
      return .run { [dayActivity] send in
        try await dayActivityRepository.saveDayActivity(dayActivity)
        await send(.internal(.loadDay))
      }
    }
  }

  private func handleDayActivityTaskAction(_ action: Action.InternalAction.DayActivityTaskAction, state: inout State) -> Effect<Action> {
    switch action {
    case .showNewForm(let dayActivity):
      state.newActivity = .empty
      state.newActivityTask.activityId = dayActivity.id
      state.newActivityTask.isFormVisible = true
      state.focus = .taskName(identifier: dayActivity.id.uuidString)
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
    case .presented(.delegate(.daysUpdated)):
      return .send(.internal(.loadDay))
    default:
      return .none
    }
  }

  private func handleDayActivityTaskFormAction(_ action: PresentationAction<DayActivityFormFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
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

  private func handleDayNewActivityAction(_ action: DayNewActivityAction, state: inout State) -> Effect<Action> {
    switch action {
    case .dayActivity(.cancelled):
      state.newActivity = .empty
      state.focus = nil
      return .none
    case .dayActivity(.submitted):
      guard !state.newActivity.name.isEmpty, let day = state.selectedDay else {
        return .send(.view(.newActivityActionPerformed(.dayActivity(.cancelled))))
      }
      let dayActivity = DayActivity(
        id: uuid(),
        dayId: day.id,
        name: state.newActivity.name,
        isGeneratedAutomatically: false
      )
      return .concatenate(
        .send(.internal(.dayActivityAction(.create(dayActivity)))),
        .send(.view(.newActivityActionPerformed(.dayActivity(.cancelled))))
      )
    case .dayActivityTask(.cancelled):
      state.newActivityTask = .empty
      state.focus = nil
      return .none
    case .dayActivityTask(.submitted):
      let name = state.newActivityTask.name
      let activityId = state.newActivityTask.activityId
      state.newActivityTask = .empty
      state.focus = nil
      guard let activityId, !name.isEmpty else { return .none }
      let dayActivityTask = DayActivityTask(
        id: uuid(),
        dayActivityId: activityId,
        name: name
      )
      return .send(.internal(.dayActivityTaskAction(.create(dayActivityTask))))
    }
  }

  private func showDatePicker(state: inout State) {
    guard let selectedDay = state.selectedDay else { return }
    state.calendarPicker = CalendarPickerFeature.State(
      type: .singleSelection(.noConfirmation),
      date: selectedDay.date,
      actionIdentifier: CalendarActivityAction.changeDate.rawValue
    )
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
