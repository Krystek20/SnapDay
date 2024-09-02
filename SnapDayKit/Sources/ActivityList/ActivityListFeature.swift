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
  @Dependency(\.dayEditor) private var dayEditor
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

    var information: InformationViewConfiguration? {
      let showInformation = activities.isEmpty &&
      !newActivity.isFormVisible &&
      !loading
      return showInformation ? .addActivity : nil
    }

    @Presents var templateForm: DayActivityFormFeature.State?
    @Presents var dayActivityForm: DayActivityFormFeature.State?

    var newActivity = DayNewActivity.empty
    var focus: DayNewField?
    var loading = false

    let day: Day

    public init(day: Day) {
      self.day = day
    }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case newButtonTapped
      case addToDayButtonTapped(Activity)
      case enableButtonTapped(Activity)
      case removeButtonTapped(Activity)
      case activityEditTapped(Activity)
      case newActivityActionPerformed(DayNewActivityAction)
    }
    public enum InternalAction: Equatable {
      case loadActivities
      case removeDayActivities(Activity)
      case activitiesLoaded(_ activities: [Activity])
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
      case .view(.addToDayButtonTapped(let activity)):
        let dayActivity = DayActivity.create(
          from: activity,
          uuid: { uuid() },
          calendar: { calendar },
          dayId: state.day.id,
          dayDate: state.day.date,
          createdByUser: true
        )
        return .run { [day = state.day] send in
          try await dayEditor.addDayActivity(dayActivity, day.date)
          await send(.delegate(.daysUpdated))
        }
      case .view(.enableButtonTapped(var activity)):
        activity.isFrequentEnabled.toggle()
        return .run { [activity] send in
          try await activityRepository.saveActivity(activity)
          try await dayEditor.updateDayActivities(activity, today)
          await send(.internal(.loadActivities))
          await send(.delegate(.daysUpdated))
        }
      case .view(.removeButtonTapped(let activity)):
        return .send(.internal(.removeDayActivities(activity)))
      case .view(.newButtonTapped):
        state.newActivity.isFormVisible = true
        state.focus = .activityName
        return .none
      case .view(.newActivityActionPerformed(let action)):
        return handleNewActivityAction(action, state: &state)
      case .view(.activityEditTapped(let activity)):
        state.templateForm = DayActivityFormFeature.State(
          form: DayActivityForm(
            activity: activity
          ),
          type: .edit,
          editDate: state.day.date
        )
        return .none
      case .internal(.loadActivities):
        return .run { send in
          let activities = try await activityRepository.loadActivities()
          await send(.internal(.activitiesLoaded(activities)))
        }
      case .internal(.removeDayActivities(let activity)):
        return .run { [day = state.day] send in
          try await dayEditor.removeDayActivities(activity, day.date)
          try await activityRepository.deleteActivity(activity)
          await send(.delegate(.daysUpdated))
          await send(.internal(.loadActivities))
        }
      case .internal(.activitiesLoaded(let activities)):
        state.activities = activities
        state.loading = false
        return .none
      case .templateForm(let action):
        return handleTemplateForm(action, state: &state)
      case .delegate:
        return .none
      case .binding(\.focus):
        if state.focus == nil {
          state.newActivity = .empty
        }
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
        try await dayEditor.updateDayActivities(toUpdate, day.date)
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

  private func handleNewActivityAction(_ action: DayNewActivityAction, state: inout State) -> Effect<Action> {
    switch action {
    case .dayActivity(.cancelled):
      state.newActivity = .empty
      state.focus = nil
      return .none
    case .dayActivity(.submitted):
      state.loading = true
      let name = state.newActivity.name
      state.newActivity = .empty
      state.focus = nil

      guard !name.isEmpty else {
        state.loading = false
        return .none
      }

      let activity = Activity(
        id: uuid(),
        name: name,
        startDate: today
      )

      return .run { [day = state.day, activity] send in
        try await activityRepository.saveActivity(activity)
        try await dayEditor.updateDayActivities(activity, day.date)
        await send(.delegate(.daysUpdated))
        await send(.internal(.loadActivities))
      }
    case .dayActivityTask:
      return .none
    }
  }

  // MARK: - Initialization

  public init() { }
}
