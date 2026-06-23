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
  @Dependency(\.uuid) private var uuid

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    var searchText = ""
    var activities: [Activity] = []
    var items: [ListItem] = []
    var information: InformationViewConfiguration?

    @Presents var templateForm: DayActivityFormFeature.State?
    @Presents var dayActivityForm: DayActivityFormFeature.State?

    var newField: DayNewField?

    let day: Day

    public init(day: Day) {
      self.day = day
    }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case newButtonTapped
      case listItemActionPerfomed(ListItemAction)
      case cancelButtonTapped
    }
    public enum InternalAction: Equatable {
      case loadActivities
      case removeDayActivities(Activity)
      case activitiesLoaded(_ activities: [Activity])
      case addToDay(_ activity: Activity)
      case setIsFrequent(_ isFrequentEnabled: Bool, _ activity: Activity)
      case edit(_ activity: Activity)
      case setItems
    }
    public enum DelegateAction: Equatable {
      case daysUpdated
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
      case .view(.cancelButtonTapped):
        return .run { _ in
          await dismiss()
        }
      case .internal(.loadActivities):
        return .run { send in
          let activities = try await activityRepository.loadActivities()
          await send(.internal(.activitiesLoaded(activities)))
        }
      case .internal(.removeDayActivities(let activity)):
        return .run { [day = state.day] send in
          try await dayUpdater.updateDaysByRemovedActivity(activity, from: day.date)
          try await activityRepository.deleteActivity(activity)
          await send(.delegate(.daysUpdated))
          await send(.internal(.loadActivities))
        }
      case .internal(.activitiesLoaded(let activities)):
        state.activities = activities
        return .send(.internal(.setItems))
      case .internal(.addToDay(let activity)):
        let dayActivity = DayActivity.create(
          from: activity,
          uuid: uuid,
          calendar: { calendar },
          date: state.day.date,
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
        state.templateForm = DayActivityFormFeature.State(
          form: DayActivityForm(
            activity: activity
          ),
          type: .edit,
          editDate: state.day.date
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
        try await dayUpdater.updateDaysByUpdatedActivity(toUpdate, from: day.date)
        await send(.internal(.loadActivities))
        await send(.delegate(.daysUpdated))
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
        try await dayUpdater.updateDaysByUpdatedActivity(activity, from: day.date)
        await send(.delegate(.daysUpdated))
        await send(.internal(.loadActivities))
      }
    }
  }

  // MARK: - Initialization

  public init() { }
}
