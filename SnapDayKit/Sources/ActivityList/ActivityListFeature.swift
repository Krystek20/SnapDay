import Foundation
import ComposableArchitecture
import DayActivityForm
import Repositories
import Utilities
import Models
import Common

import enum UiComponents.ListItemAction
import struct UiComponents.ListItem

@Reducer
public struct ActivityListFeature: TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.activityRepository) var activityRepository
  @Dependency(\.dayUpdater) private var dayUpdater
  @Dependency(\.dismiss) private var dismiss
  @Dependency(\.calendar) private var calendar
  @Dependency(\.planRepository) private var planRepository
  @Dependency(\.uuid) private var uuid

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    enum Mode: Equatable {
      case management
      case selection(title: String)
    }

    var searchText = ""
    var activities: [Activity] = []
    var items: [ListItem] = []
    var information: InformationViewConfiguration?
    var selectedActivityIDs: Set<Activity.ID>
    var isPlanActivityDeletionAlertPresented = false

    @Presents var templateForm: DayActivityFormFeature.State?

    var newField: DayNewField?

    let day: Day?
    let mode: Mode

    var isSelectionMode: Bool {
      if case .selection = mode {
        return true
      }
      return false
    }

    var navigationTitle: String {
      switch mode {
      case .management:
        String(localized: "Saved Activities", bundle: .module)
      case .selection(let title):
        title
      }
    }

    var selectedActivities: [Activity] {
      activities.filter { selectedActivityIDs.contains($0.id) }
    }

    public init(day: Day) {
      self.day = day
      self.mode = .management
      self.selectedActivityIDs = []
    }

    public init(
      selectedActivityIDs: Set<Activity.ID>,
      title: String
    ) {
      self.day = nil
      self.mode = .selection(title: title)
      self.selectedActivityIDs = selectedActivityIDs
    }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case newButtonTapped
      case listItemActionPerfomed(ListItemAction)
      case activitySelectionTapped(Activity.ID)
      case selectionConfirmed
      case cancelButtonTapped
      case planActivityDeletionAlertDismissed
    }
    public enum InternalAction: Equatable {
      case loadActivities
      case removeDayActivities(Activity)
      case activityDeletionBlocked
      case activitiesLoaded(_ activities: [Activity])
      case addToDay(_ activity: Activity)
      case setIsFrequent(_ isFrequentEnabled: Bool, _ activity: Activity)
      case edit(_ activity: Activity)
      case setItems
    }
    public enum DelegateAction: Equatable {
      case daysUpdated
      case selectionConfirmed([Activity])
    }

    case binding(BindingAction<State>)

    case templateForm(PresentationAction<DayActivityFormFeature.Action>)

    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
  }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(.appeared):
        return .send(.internal(.loadActivities))
      case .view(.listItemActionPerfomed(let action)):
        return performListItemAction(action, state: &state)
      case .view(.newButtonTapped):
        state.newField = .activityName
        return .send(.internal(.setItems))
      case .view(.activitySelectionTapped(let activityID)):
        guard state.isSelectionMode else { return .none }
        if state.selectedActivityIDs.contains(activityID) {
          state.selectedActivityIDs.remove(activityID)
        } else {
          state.selectedActivityIDs.insert(activityID)
        }
        return .none
      case .view(.selectionConfirmed):
        guard state.isSelectionMode else { return .none }
        return .send(.delegate(.selectionConfirmed(state.selectedActivities)))
      case .view(.cancelButtonTapped):
        return .run { _ in
          await dismiss()
        }
      case .view(.planActivityDeletionAlertDismissed):
        state.isPlanActivityDeletionAlertPresented = false
        return .none
      case .internal(.loadActivities):
        return .run { send in
          let activities = try await activityRepository.loadActivities()
          await send(.internal(.activitiesLoaded(activities)))
        }
      case .internal(.removeDayActivities(let activity)):
        guard let day = state.day else { return .none }
        return .run { [day] send in
          let isUsedByPlan = try await planRepository.loadPlans().contains { plan in
            plan.schedule.contains { $0.activityID == activity.id }
          }
          guard !isUsedByPlan else {
            await send(.internal(.activityDeletionBlocked))
            return
          }
          try await dayUpdater.updateDaysByRemovedActivity(activity, from: day.date)
          try await activityRepository.deleteActivity(activity)
          await send(.delegate(.daysUpdated))
          await send(.internal(.loadActivities))
        }
      case .internal(.activitiesLoaded(let activities)):
        state.activities = activities
        return .send(.internal(.setItems))
      case .internal(.activityDeletionBlocked):
        state.isPlanActivityDeletionAlertPresented = true
        return .none
      case .internal(.addToDay(let activity)):
        guard let day = state.day else { return .none }
        let dayActivity = DayActivity.create(
          from: activity,
          uuid: uuid,
          calendar: { calendar },
          date: day.date,
          createdByUser: true
        )
        return .run { send in
          try await dayUpdater.saveDayActivity(dayActivity, syncSharable: false)
          await send(.delegate(.daysUpdated))
        }
      case .internal(.setIsFrequent(let isFrequentEnabled, var activity)):
        activity.isFrequentEnabled = isFrequentEnabled
        return .run { [activity] send in
          try await activityRepository.saveActivity(activity)
          try await dayUpdater.updateDaysByUpdatedActivity(activity, from: today)
          await send(.internal(.loadActivities))
          await send(.delegate(.daysUpdated))
        }
      case .internal(.edit(let activity)):
        guard let day = state.day else { return .none }
        state.templateForm = DayActivityFormFeature.State(
          form: DayActivityForm(
            activity: activity
          ),
          type: .edit,
          editDate: day.date
        )
        return .none
      case .internal(.setItems):
        state.items = ListItemsBuilder(
          activities: state.activities,
          newField: state.newField,
          searchText: state.searchText
        ).build()
        state.information = state.items.isEmpty && state.searchText.isEmpty ? .addActivity : nil
        return .none
      case .templateForm(let action):
        return handleTemplateForm(action, state: &state)
      case .delegate:
        return .none
      case .binding(\.searchText):
        return .send(.internal(.setItems))
      case .binding:
        return .none
      }
    }
    .ifLet(\.$templateForm, action: \.templateForm) {
      DayActivityFormFeature()
    }
  }

  private func performListItemAction(_ actionType: ListItemAction, state: inout State) -> Effect<Action> {
    switch actionType {
    case .rowAction, .reorder:
        .none
    case .itemTapped(let itemId, _):
        .run { send in
          guard let activity = try await activityRepository.activity(.id(itemId)) else { return }
          await send(.internal(.edit(activity)))
        }
    case .menuAction(let menuParameters, _):
        .run { send in
          if let activity = try await activityRepository.activity(.id(menuParameters.itemId)),
             let action = ActivityAction(rawValue: menuParameters.actionId) {
            switch action {
            case .addToDay:
              await send(.internal(.addToDay(activity)))
            case .edit:
              await send(.internal(.edit(activity)))
            case .enable:
              await send(.internal(.setIsFrequent(true, activity)))
            case .disable:
              await send(.internal(.setIsFrequent(false, activity)))
            case .remove:
              await send(.internal(.removeDayActivities(activity)))
            }
          }
        }
    case .newItemForm(let action):
        handleNewActivityAction(action, state: &state)
    }
  }

  private func handleTemplateForm(_ action: PresentationAction<DayActivityFormFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .dismiss:
      return .none
    case .presented(.delegate(.activityUpdated(let activityForm))):
      guard var toUpdate = state.activities.first(where: { $0.id == activityForm.id }) else { return .none }
      let tasksToDelete = toUpdate.tasks.filter { task in
        !activityForm.tasks.contains(where: { $0.id == task.id })
      }
      toUpdate.update(by: activityForm, startDate: today)
      return .run { [day = state.day, toUpdate, tasksToDelete] send in
        for task in tasksToDelete {
          try await activityRepository.deleteActivityTask(task)
        }
        try await activityRepository.saveActivity(toUpdate)
        if let day {
          try await dayUpdater.updateDaysByUpdatedActivity(toUpdate, from: day.date)
          await send(.delegate(.daysUpdated))
        }
        await send(.internal(.loadActivities))
      }
    case .presented(.delegate(.activityDeleted(let activityForm))):
      guard let toDelete = state.activities.first(where: { $0.id == activityForm.id }) else { return .none }
      return .send(.internal(.removeDayActivities(toDelete)))
    default:
      return .none
    }
  }

  private func handleNewActivityAction(_ action: NewItemFormAction, state: inout State) -> Effect<Action> {
    switch action {
    case .cancelled:
      state.newField = nil
      return .send(.internal(.setItems))
    case .submitted:
      guard let item = state.items.first(where: { $0.isForm }),
            item.title != .empty else {
        return handleNewActivityAction(.cancelled, state: &state)
      }
      state.newField = nil

      let activity = Activity(
        id: uuid(),
        name: item.title,
        startDate: today
      )

      return .run { [day = state.day, activity] send in
        try await activityRepository.saveActivity(activity)
        if let day {
          try await dayUpdater.updateDaysByUpdatedActivity(activity, from: day.date)
          await send(.delegate(.daysUpdated))
        }
        await send(.internal(.loadActivities))
      }
    }
  }

  // MARK: - Initialization

  public init() { }
}
