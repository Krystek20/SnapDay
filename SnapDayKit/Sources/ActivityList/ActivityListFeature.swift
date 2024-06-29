import Foundation
import ComposableArchitecture
import DayActivityForm
import Repositories
import Utilities
import Models
import Common

@Reducer
public struct ActivityListFeature: TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.activityRepository) var activityRepository
  @Dependency(\.dayActivityRepository) private var dayActivityRepository
  @Dependency(\.dismiss) private var dismiss
  @Dependency(\.calendar) private var calendar
  @Dependency(\.uuid) private var uuid

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    var searchText = ""

    var activities: [Activity] = []
    var displayedActivities: [Activity] {
      guard !searchText.isEmpty else { return activities }
      return activities.filter { $0.name.contains(searchText) }
    }
    var selectedActivities: [Activity] = []

    @Presents var templateForm: DayActivityFormFeature.State?
    @Presents var dayActivityForm: DayActivityFormFeature.State?

    let day: Day

    public init(day: Day) {
      self.day = day
    }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case newButtonTapped
      case addButtonTapped
      case activityTapped(Activity)
      case activityEditTapped(Activity)
    }
    public enum InternalAction: Equatable {
      case loadOnStart
      case loadActivities
      case activitiesLoaded(_ activities: [Activity])
    }
    public enum DelegateAction: Equatable {
      case activityAdded(Activity)
      case activityUpdated(Activity)
      case activityDeleted(Activity)
      case activitiesSelected([Activity])
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
        return .run { send in
          await send(.internal(.loadOnStart))
        }
      case .view(.addButtonTapped):
        return .run { [selectedActivities = state.selectedActivities] send in
          await send(.delegate(.activitiesSelected(selectedActivities)))
          await dismiss()
        }
      case .view(.newButtonTapped):
        state.templateForm = DayActivityFormFeature.State(
          form: DayActivityForm(
            activity: Activity(
              id: uuid()
            )
          ),
          type: .new,
          editDate: state.day.date
        )
        return .none
      case .view(.activityTapped(let activity)):
        if let index = state.selectedActivities.firstIndex(where: { $0.id == activity.id }) {
          state.selectedActivities.remove(at: index)
        } else {
          state.selectedActivities.append(activity)
        }
        return .none
      case .view(.activityEditTapped(let activity)):
        state.templateForm = DayActivityFormFeature.State(
          form: DayActivityForm(
            activity: activity
          ),
          type: .edit,
          editDate: state.day.date
        )
        return .none
      case .internal(.loadOnStart):
        return .send(.internal(.loadActivities))
      case .internal(.loadActivities):
        return .run { send in
          let activities = try await activityRepository.loadActivities()
          await send(.internal(.activitiesLoaded(activities)))
        }
      case .internal(.activitiesLoaded(let activities)):
        state.activities = activities
        return .none
      case .templateForm(let action):
        return handleTemplateForm(action, state: &state)
      case .delegate:
        return .none
      case .binding:
        return .none
      }
    }
    .ifLet(\.$templateForm, action: \.templateForm) {
      DayActivityFormFeature()
    }
  }

  private func handleTemplateForm(_ action: PresentationAction<DayActivityFormFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .dismiss:
      return .none
    case .presented(.delegate(.activityCreated(let activityForm))):
      return .run { [activityForm] send in
        let activity = Activity(form: activityForm, startDate: today)
        try await activityRepository.saveActivity(activity)
        await send(.delegate(.activityAdded(activity)))
        await send(.internal(.loadActivities))
      }
    case .presented(.delegate(.activityUpdated(let activityForm))):
      guard var toUpdate = state.activities.first(where: { $0.id == activityForm.id }) else { return .none }
      let tasksToDelete = toUpdate.tasks.filter { task in
        !activityForm.tasks.contains(where: { $0.id == task.id })
      }
      toUpdate.update(by: activityForm, startDate: today)
      return .run { [toUpdate, tasksToDelete] send in
        for task in tasksToDelete {
          try await activityRepository.deleteActivityTask(task)
        }
        try await activityRepository.saveActivity(toUpdate)
        await send(.delegate(.activityUpdated(toUpdate)))
        await send(.internal(.loadActivities))
      }
    case .presented(.delegate(.activityDeleted(let activityForm))):
      guard let toDelete = state.activities.first(where: { $0.id == activityForm.id }) else { return .none }
      return .run { [toDelete] send in
        try await activityRepository.deleteActivity(toDelete)
        await send(.delegate(.activityDeleted(toDelete)))
        await send(.internal(.loadActivities))
      }
    default:
      return .none
    }
  }

  // MARK: - Initialization

  public init() { }
}
