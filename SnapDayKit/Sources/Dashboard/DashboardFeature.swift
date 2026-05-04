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
import Friends
import ManageActivity

import protocol UiComponents.InformationViewConfigurable
import struct UiComponents.ListItem
import enum UiComponents.ListItemAction

@Reducer
public struct DashboardFeature: TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.activityRepository) var activityRepository
  @Dependency(\.dayUpdater) private var dayUpdater
  @Dependency(\.uuid) private var uuid
  @Dependency(\.date) private var date
  @Dependency(\.utcCalendar) private var calendar
  @Dependency(\.userNotificationCenterProvider) private var userNotificationCenterProvider
  @Dependency(\.deeplinkService) private var deeplinkService
  @Dependency(\.widgetReloader) private var widgetReloader
  private let userDefaults: UserDefaults

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable, TodayProvidable {

    var title: String {
      let formatter = DateFormatter()
      formatter.dateFormat = "EEEE, d MMM yyyy"
      formatter.locale = .preferred
      return formatter.string(from: date)
    }

    var daySummary: DaySummary? {
      guard let selectedDay else { return nil }
      return DaySummary(day: selectedDay)
    }

    var newField: DayNewField?
    var items: [ListItem] = []

    var dayInformation: InformationViewConfiguration? {
      guard !hideDayInformation, let selectedDay, newField == nil else { return nil }
      if selectedDay.activities.allSatisfy(\.isDone) && !selectedDay.activities.isEmpty {
        return .todaySuccess
      } else if selectedDay.activities.isEmpty {
        return selectedDay.date < today
        ? .pastDay
        : .todayOrFuture
      }
      return nil
    }

    @ObservationStateIgnored var hideDayInformation = true
    @ObservationStateIgnored var streamSetup = false

    var selectedDay: Day?
    var alert: DashboardAlert?
    var hideCompleted: Bool
    var hideTasks: Bool
    var date: Date

    @Presents var activityList: ActivityListFeature.State?
    @Presents var editDayActivity: DayActivityFormFeature.State?
    @Presents var dayActivityTaskForm: DayActivityFormFeature.State?
    @Presents var calendarPicker: CalendarPickerFeature.State?
    @Presents var friends: FriendsFeature.State?
    @Presents var manageActivity: ManageActivityFeature.State?

    public init(
      date: Date,
      userDefaults: UserDefaults = .standard
    ) {
      self.date = date
      self.hideCompleted = userDefaults.bool(forKey: "hideCompleted")
      self.hideTasks = userDefaults.bool(forKey: "hideTasks")
    }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case newButtonTapped
      case calendarButtonTapped
      case activityListButtonTapped
      case listItemActionPerfomed(ListItemAction)
      case toggleShowCompletedActivities
      case toggleShowTasks
      case todayButtonTapped
      case increaseButtonTapped
      case decreaseButtonTapped
      case confirmAlertButtonTapped
      case cancelAlertButtonTapped
      case showFriendsTapped
      case assistantButtonTapped
    }

    public enum InternalAction: Equatable {
      case changesApplied(AppliedChanges)
      case loadDay
      case setDate(_ date: Date)
      case setDay(_ day: Day)
      case setItems
      case calendarDayChanged
      case handleDeepLink(DeeplinkService.DashboardAction?)
      case dayActivityAction(DayActivityAction)
      case dayActivityTaskAction(DayActivityTaskAction)
      case saveOrder
      case manageActivity
      case newItemForm(NewItemFormAction)

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
        case addParticipant(String, DayActivity)
        case removeParticipant(String, DayActivity)
        case stopCollaboration(DayActivity)
        case acceptInvitation(DayActivity)
        case discardInvitation(DayActivity)
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
    case friends(PresentationAction<FriendsFeature.Action>)
    case manageActivity(PresentationAction<ManageActivityFeature.Action>)

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
      case .friends:
        return .none
      case .manageActivity(.dismiss):
        return .send(.internal(.loadDay))
      case .manageActivity:
        return .none
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
    .ifLet(\.$friends, action: \.friends) {
      FriendsFeature()
    }
    .ifLet(\.$manageActivity, action: \.manageActivity) {
      ManageActivityFeature()
    }
  }

  // MARK: - Initialization

  public init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

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
          for await _ in NotificationCenter.default.publisher(for: .snapDayCloudKitChanged).values {
            try await dayUpdater.syncShared()
            await send(.internal(.loadDay))
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
    case .calendarButtonTapped:
      showDatePicker(state: &state)
      return .none
    case .activityListButtonTapped:
      guard let selectedDay = state.selectedDay else { return .none }
      state.activityList = ActivityListFeature.State(day: selectedDay)
      return .none
    case .listItemActionPerfomed(let actionType):
      return performListItemAction(actionType, state: &state)
    case .toggleShowCompletedActivities:
      state.hideCompleted.toggle()
      userDefaults.set(state.hideCompleted, forKey: "hideCompleted")
      return .send(.internal(.setItems))
    case .toggleShowTasks:
      state.hideTasks.toggle()
      userDefaults.set(state.hideTasks, forKey: "hideTasks")
      return .send(.internal(.setItems))
    case .increaseButtonTapped:
      state.date = calendar.date(byAdding: .day, value: 1, to: state.date) ?? state.date
      return .send(.internal(.loadDay))
    case .decreaseButtonTapped:
      state.date = calendar.date(byAdding: .day, value: -1, to: state.date) ?? state.date
      return .send(.internal(.loadDay))
    case .todayButtonTapped:
      state.date = today
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
    case .showFriendsTapped:
      state.friends = FriendsFeature.State()
      return .none
    case .assistantButtonTapped:
      state.manageActivity = ManageActivityFeature.State()
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
      state.selectedDay = day
      state.hideDayInformation = false
      return .run { send in
        await send(.internal(.setItems))
        try await userNotificationCenterProvider.reloadReminders()
      }
    case .setItems:
      state.items = ListItemsBuilder(
        activities: state.selectedDay?.activities ?? [],
        newField: state.newField,
        hideCompleted: state.hideCompleted,
        hideTasks: state.hideTasks
      ).build()
      return .none
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
      return switch deeplink {
      case .addActivity:
        .send(.internal(.dayActivityAction(.showNewForm)))
      case .dictate:
        .send(.internal(.manageActivity))
      }
    case .saveOrder:
      return .run { [selectedDay = state.selectedDay] send in
        guard var selectedDay else { return }
        for index in selectedDay.activities.indices {
          selectedDay.activities[index].position = index
          try await dayUpdater.saveDayActivity(selectedDay.activities[index], syncSharable: false)
        }
        await send(.internal(.loadDay))
      }
    case .manageActivity:
      state.manageActivity = ManageActivityFeature.State()
      return .none
    case .newItemForm(let action):
      return handleNewItemFormAction(action, state: &state)
    }
  }

  private func performListItemAction(_ actionType: ListItemAction, state: inout State) -> Effect<Action> {
    switch actionType {
    case .itemTapped(let itemId, let parentId):
      return .run { send in
        if let parentId,
           let dayActivity = try await dayUpdater.dayActivity(identifier: parentId),
           let task = dayActivity.dayActivityTasks.first(where: { $0.id.uuidString == itemId }) {
          await send(.internal(.dayActivityTaskAction(.showEditForm(task))))
        } else if let dayActivity = try await dayUpdater.dayActivity(identifier: itemId) {
          await send(.internal(.dayActivityAction(.showEditForm(dayActivity))))
        }
      }
    case .rowAction(let parameters):
      guard let action = DayActivityInvitationAction(rawValue: parameters.actionId),
            let dayActivity = state.selectedDay?.activities.first(where: { $0.id.uuidString == parameters.itemId }) else {
        return .none
      }
      return .run { send in
        switch action {
        case .accept:
          await send(.internal(.dayActivityAction(.acceptInvitation(dayActivity))))
        case .discard:
          await send(.internal(.dayActivityAction(.discardInvitation(dayActivity))))
        }
      }
    case .menuAction(let menuParameters, let submenuParameters):
      return .run { send in
        if let parentId = menuParameters.parentId,
           let dayActivity = try await dayUpdater.dayActivity(identifier: parentId),
           let task = dayActivity.dayActivityTasks.first(where: { $0.id.uuidString == menuParameters.itemId }),
           let action = DayActivityTaskAction(rawValue: menuParameters.actionId)
        {
          switch action {
          case .deselect:
            await send(.internal(.dayActivityTaskAction(.select(task))))
          case .select:
            await send(.internal(.dayActivityTaskAction(.select(task))))
          case .edit:
            await send(.internal(.dayActivityTaskAction(.showEditForm(task))))
          case .remove:
            await send(.internal(.dayActivityTaskAction(.remove(task))))
          }
        } else if let dayActivity = try await dayUpdater.dayActivity(identifier: menuParameters.itemId),
                  let action = DayActivityAction(rawValue: menuParameters.actionId) {
          switch action {
          case .deselect:
            await send(.internal(.dayActivityAction(.select(dayActivity))))
          case .select:
            await send(.internal(.dayActivityAction(.select(dayActivity))))
          case .edit:
            await send(.internal(.dayActivityAction(.showEditForm(dayActivity))))
          case .addTask:
            await send(.internal(.dayActivityTaskAction(.showNewForm(dayActivity))))
          case .save:
            await send(.internal(.dayActivityAction(.save(dayActivity))))
          case .move:
            await send(.internal(.dayActivityAction(.showDatePicker(dayActivity))))
          case .copy:
            await send(.internal(.dayActivityAction(.showMultiDatePicker(dayActivity))))
          case .remove:
            await send(.internal(.dayActivityAction(.remove(dayActivity))))
          case .selectImportant:
            await send(.internal(.dayActivityAction(.setImportant(true, dayActivity))))
          case .deselectImportant:
            await send(.internal(.dayActivityAction(.setImportant(false, dayActivity))))
          case .deselectCollaborator, .selectCollaborator:
            guard let submenuParameters, let submenuAction = DayActivityCollaborationAction(rawValue: submenuParameters.actionId) else { return }
            switch submenuAction {
            case .add:
              await send(.internal(.dayActivityAction(.addParticipant(submenuParameters.itemId, dayActivity))))
            case .remove:
              await send(.internal(.dayActivityAction(.removeParticipant(submenuParameters.itemId, dayActivity))))
            }
          case .stopCollaboration:
            await send(.internal(.dayActivityAction(.stopCollaboration(dayActivity))))
          }
        }
      }
    case .reorder(let action, let itemId):
      return .run { [activities = state.selectedDay?.activities] send in
        switch action {
        case .perform(let destinationId):
          guard let dayActivity = activities?.first(where: { $0.id.uuidString == itemId }),
                let destination = activities?.first(where: { $0.id.uuidString == destinationId }) else { return }
          await send(.internal(.dayActivityAction(.reorder(dayActivity, destination))))
        case .drop:
          await send(.internal(.saveOrder))
        }
      }
    case .newItemForm(let action):
      return .send(.internal(.newItemForm(action)))
    }
  }

  private func handleDayActivityAction(_ action: Action.InternalAction.DayActivityAction, state: inout State) -> Effect<Action> {
    switch action {
    case .showNewForm:
      state.newField = .activityName
      return .send(.internal(.setItems))
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
        try await dayUpdater.saveDayActivity(dayActivity, syncSharable: true)
        await send(.internal(.loadDay))
        try await userNotificationCenterProvider.reloadReminders()
        guard dayActivity.hasIncompletedSubtasksAndDone else { return }
        await send(.internal(.dayActivityAction(.showAlertSelectAll(dayActivity))))
      }
    case .create(let dayActivity):
      state.hideDayInformation = true
      return .run { [dayActivity] send in
        try await dayUpdater.saveDayActivity(dayActivity, syncSharable: false)
        await send(.internal(.loadDay))
      }
    case .update(let dayActivity):
      let activityBeforeUpdate = findActivity(id: dayActivity.id, state: state)
      let showAlertSelectAll = dayActivity.hasIncompletedSubtasksAndDone && activityBeforeUpdate?.isDone == false
      let showAlertSelectDayActivity = activityBeforeUpdate?.hasCompletedSubtasks == false && dayActivity.hasCompletedSubtasksAndNotDone
      return .run { [showAlertSelectAll, dayActivity] send in
        try await dayUpdater.saveDayActivity(dayActivity, syncSharable: true)
        await send(.internal(.loadDay))
        if showAlertSelectAll {
          await send(.internal(.dayActivityAction(.showAlertSelectAll(dayActivity))))
        } else if showAlertSelectDayActivity {
          await send(.internal(.dayActivityAction(.showAlertSelectActivity(dayActivity))))
        }
      }
    case .move(let dayActivity, let toDate):
      return .run { send in
        try await dayUpdater.moveDayActivity(dayActivity, toDate: toDate)
        await send(.internal(.loadDay))
      }
    case .copy(let dayActivity, let dates):
      return .run { send in
        try await dayUpdater.copyDayActivity(dayActivity, to: dates)
        await send(.internal(.loadDay))
      }
    case .remove(let dayActivity):
      return .run { [dayActivity] send in
        try await dayUpdater.removeDayActivity(dayActivity)
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
        try await dayUpdater.saveDayActivity(dayActivity, syncSharable: false)
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
      return .send(.internal(.setItems))
    case .setImportant(let isImportant, let dayActivity):
      guard var dayActivity = findActivity(id: dayActivity.id, state: state) else { return .none }
      dayActivity.important = isImportant
      return .run { [dayActivity] send in
        try await dayUpdater.saveDayActivity(dayActivity, syncSharable: true)
        await send(.internal(.loadDay))
      }
    case .addParticipant(let participantId, let dayActivity):
      return .run { send in
        do {
          try await dayUpdater.addParticipant(participantId, to: dayActivity)
          await send(.internal(.loadDay))
        } catch {
          print(error)
        }
      }
    case .stopCollaboration(let dayActivity):
      return .run { send in
        try await dayUpdater.stopCollaboration(in: dayActivity)
        await send(.internal(.loadDay))
      }
    case .removeParticipant(let participantId, let dayActivity):
      return .run { send in
        try await dayUpdater.removeParticipant(participantId, to: dayActivity)
        await send(.internal(.loadDay))
      }
    case .acceptInvitation(let dayActivity):
      return .run { send in
        try await dayUpdater.acceptInvitation(for: dayActivity)
        await send(.internal(.loadDay))
      }
    case .discardInvitation(let dayActivity):
      return .run { send in
        try await dayUpdater.discardInvitation(for: dayActivity)
        await send(.internal(.loadDay))
      }
    }
  }

  private func handleDayActivityTaskAction(_ action: Action.InternalAction.DayActivityTaskAction, state: inout State) -> Effect<Action> {
    switch action {
    case .showNewForm(let dayActivity):
      state.newField = .taskName(identifier: dayActivity.id.uuidString)
      return .send(.internal(.setItems))
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
        try await dayUpdater.saveDayActivityTask(dayActivityTask, syncSharable: true)
        await send(.internal(.loadDay))
        try await userNotificationCenterProvider.reloadReminders()
        guard let dayActivity = try await dayUpdater.dayActivity(identifier: dayActivityTask.dayActivityId.uuidString),
              dayActivity.hasCompletedSubtasksAndNotDone else { return }
        await send(.internal(.dayActivityAction(.showAlertSelectActivity(dayActivity))))
      }
    case .create(let dayActivityTask):
      guard var dayActivity = state.selectedDay?.activities.first(where: { $0.id == dayActivityTask.dayActivityId }) else { return .none }
      dayActivity.dayActivityTasks.append(dayActivityTask)
      return .run { [dayActivity] send in
        try await dayUpdater.saveDayActivity(dayActivity, syncSharable: true)
        await send(.internal(.loadDay))
      }
    case .update(let dayActivityTask):
      let dayActivityTaskBeforeUpdate = findActivityTask(id: dayActivityTask.id, activityId: dayActivityTask.dayActivityId, state: state)
      let wasCompleted = dayActivityTaskBeforeUpdate?.isDone == false && dayActivityTask.isDone
      return .run { [wasCompleted, dayActivityTask] send in
        try await dayUpdater.saveDayActivityTask(dayActivityTask, syncSharable: true)
        await send(.internal(.loadDay))
        guard wasCompleted,
              let dayActivity = try await dayUpdater.dayActivity(identifier: dayActivityTask.dayActivityId.uuidString),
              dayActivity.hasCompletedSubtasksAndNotDone
        else { return }
        await send(.internal(.dayActivityAction(.showAlertSelectActivity(dayActivity))))
      }
    case .remove(let dayActivityTask):
      return .run { [dayActivityTask] send in
        try await dayUpdater.removeDayActivityTask(dayActivityTask)
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
                let dayActivity = try await dayUpdater.dayActivity(identifier: objectIdentifier) else { return }
          await send(.internal(.dayActivityAction(.copy(dayActivity, dates: dates))))
        case .move:
          guard let objectIdentifier,
                let dayActivity = try await dayUpdater.dayActivity(identifier: objectIdentifier),
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

  private func handleNewItemFormAction(_ action: NewItemFormAction, state: inout State) -> Effect<Action> {
    switch action {
    case .cancelled:
      state.newField = nil
      return .send(.internal(.setItems))
    case .submitted:
      guard let newField = state.newField,
            let item = state.items.first(where: { $0.isForm }),
            item.title != .empty,
            let day = state.selectedDay else {
        return .send(.internal(.newItemForm(.cancelled)))
      }
      switch newField {
      case .activityName:
        let dayActivity = DayActivity(
          id: uuid(),
          date: day.date,
          name: item.title,
          isGeneratedAutomatically: false
        )
        state.newField = nil
        return .send(.internal(.dayActivityAction(.create(dayActivity))))
      case .taskName(let activityId):
        guard let dayActivityId = UUID(uuidString: activityId) else { return .none }
        let dayActivityTask = DayActivityTask(
          id: uuid(),
          dayActivityId: dayActivityId,
          name: item.title
        )
        state.newField = nil
        return .send(.internal(.dayActivityTaskAction(.create(dayActivityTask))))
      }
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
