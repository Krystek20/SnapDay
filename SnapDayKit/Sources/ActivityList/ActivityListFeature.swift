import Foundation
import ComposableArchitecture
import DayActivityForm
import Repositories
import Utilities
import Models
import Common

@Reducer
public struct ActivityListFeature: TodayProvidable {

  public struct ActivityListConfiguration: Equatable {
    public enum ActivityListFetchingOption: Equatable {
      case prefetched([Activity])
      case fromCoreData
    }

    public enum ActivityListType: Equatable {
      case singleSelection(selectedActivity: Activity?)
      case multiSelection(selectedActivities: [Activity])
    }

    let type: ActivityListType
    let isActivityEditable: Bool
    let fetchingOption: ActivityListFetchingOption
    let day: Day?

    public init(
      type: ActivityListType,
      isActivityEditable: Bool,
      fetchingOption: ActivityListFetchingOption,
      day: Day? = nil
    ) {
      self.type = type
      self.isActivityEditable = isActivityEditable
      self.fetchingOption = fetchingOption
      self.day = day
    }
  }

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

    var activityPlaceholder: ActivityPlaceholder?
    
    var displayedNewDayActivities: [DayActivity] {
      guard !searchText.isEmpty else {
        return newDayActivities.sorted(by: { $0.name < $1.name })
      }
      return newDayActivities
        .filter { $0.name.contains(searchText) }
        .sorted(by: { $0.name < $1.name })
    }
    var newDayActivities: [DayActivity] = []

    var activities: [Activity] = []
    var displayedActivities: [Activity] {
      guard !searchText.isEmpty else { return activities }
      return activities.filter { $0.name.contains(searchText) }
    }
    var selectedActivities: [Activity] = []

    var dayActivities: [DayActivity] = []
    var displayedDayActivities: [DayActivity] {
      guard !searchText.isEmpty else { return dayActivities }
      return dayActivities.filter { $0.name.contains(searchText) }
    }
    var selectedDayActivities: [DayActivity] = []

    var selectedItemCount: Int {
      newDayActivities.count + selectedActivities.count + selectedDayActivities.count
    }

    var configuration: ActivityListConfiguration

    var showButton: Bool {
      guard case .multiSelection = configuration.type else { return false }
      return true
    }

    @Presents var templateForm: DayActivityFormFeature.State?
    @Presents var dayActivityForm: DayActivityFormFeature.State?

    public init(configuration: ActivityListConfiguration) {
      self.configuration = configuration
    }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case newButtonTapped
      case addButtonTapped
      case activityTapped(Activity)
      case dayActivityTapped(DayActivity)
      case newDayActivityTapped(DayActivity)
      case activityPlaceholderTapped
      case activityEditTapped(Activity)
      case dayActivityEditTapped(DayActivity)
    }
    public enum InternalAction: Equatable {
      case loadOnStart
      case loadActivities
      case loadDayActivities
      case activitiesLoaded(_ activities: [Activity])
      case dayActivitiesLoaded(_ dayActivities: [DayActivity])
    }
    public enum DelegateAction: Equatable {
      case activityAdded(Activity)
      case activityUpdated(Activity)
      case activityDeleted(Activity)
      case activitiesSelected([Activity])
    }

    case binding(BindingAction<State>)

    case templateForm(PresentationAction<DayActivityFormFeature.Action>)
    case dayActivityForm(PresentationAction<DayActivityFormFeature.Action>)

    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
  }

  enum NSCalendarDayChanged { }

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
        guard let date = state.configuration.day?.date else { return .none }
        state.templateForm = DayActivityFormFeature.State(
          form: DayActivityForm(
            activity: Activity(
              id: uuid()
            )
          ),
          type: .new,
          editDate: date
        )
        return .none
      case .view(.activityTapped(let activity)):
        switch state.configuration.type {
        case .singleSelection:
          return .run { send in
            await send(.delegate(.activitiesSelected([activity])))
            await dismiss()
          }
        case .multiSelection:
          if state.selectedActivities.contains(activity) {
            state.selectedActivities.removeAll(where: { $0.id == activity.id })
          } else {
            state.selectedActivities.append(activity)
          }
          return .none
        }
      case .view(.dayActivityTapped(let dayActivity)):
        if state.selectedDayActivities.contains(dayActivity) {
          state.selectedDayActivities.removeAll(where: { $0.id == dayActivity.id })
        } else {
          state.selectedDayActivities.append(dayActivity)
        }
        return .none
      case .view(.newDayActivityTapped(let newDayActivity)):
        state.newDayActivities.removeAll(where: { $0.id == newDayActivity.id })
        return .none
      case .view(.activityPlaceholderTapped):
        guard let dayId = state.configuration.day?.id,
              let name = state.activityPlaceholder?.name else { return .none }
        state.newDayActivities.append(
          DayActivity(
            id: uuid(),
            dayId: dayId,
            name: name,
            isGeneratedAutomatically: false
          )
        )
        state.activityPlaceholder = nil
        state.searchText = ""
        return .none
      case .view(.activityEditTapped(let activity)):
        guard let date = state.configuration.day?.date else { return .none }
        state.templateForm = DayActivityFormFeature.State(
          form: DayActivityForm(
            activity: activity
          ),
          type: .edit,
          editDate: date
        )
        return .none
      case .view(.dayActivityEditTapped(let dayActivity)):
        guard let date = state.configuration.day?.date else { return .none }
        state.dayActivityForm = DayActivityFormFeature.State(
          form: DayActivityForm(dayActivity: dayActivity),
          type: .edit,
          editDate: date
        )
        return .none
      case .internal(.loadOnStart):
        switch state.configuration.fetchingOption {
        case .prefetched(let activities):
          return .run { send in
            await send(.internal(.activitiesLoaded(activities)))
          }
        case .fromCoreData:
          return .run { send in
            await send(.internal(.loadActivities))
            await send(.internal(.loadDayActivities))
          }
        }
      case .internal(.loadActivities):
        return .run { send in
          let activities = try await activityRepository.loadActivities()
          await send(.internal(.activitiesLoaded(activities)))
        }
      case .internal(.loadDayActivities):
        return .run { send in
          let dayActivities = try await dayActivityRepository.activities(
            ActivitiesFetchConfiguration(onlyGeneratedAutomatically: false, hasTemplateId: false)
          )
          await send(.internal(.dayActivitiesLoaded(dayActivities)))
        }
      case .internal(.activitiesLoaded(let activities)):
        state.activities = activities
        switch state.configuration.type {
        case .singleSelection(let selectedActivity):
          guard let selectedActivity else { return .none }
          state.selectedActivities = [selectedActivity]
        case .multiSelection(let selectedActivities):
          state.selectedActivities = selectedActivities
        }
        return .none
      case .internal(.dayActivitiesLoaded(let dayActivities)):
        state.dayActivities = dayActivities
//        switch state.configuration.type {
//        case .singleSelection(let selectedActivity):
//          guard let selectedActivity else { return .none }
//          state.selectedActivities = [selectedActivity]
//        case .multiSelection(let selectedActivities):
//          state.selectedActivities = selectedActivities
//        }
        return .none
      case .templateForm(let action):
        return handleTemplateForm(action, state: &state)
      case .dayActivityForm(.presented(.delegate(.activityUpdated(let dayActivity)))):
        if let index = state.newDayActivities.firstIndex(where: { $0.id == dayActivity.id }) {
//          state.newDayActivities[index] = dayActivity
        } else if let index = state.dayActivities.firstIndex(where: { $0.id == dayActivity.id }) {
//          if state.dayActivities[index] != dayActivity {
//            state.newDayActivities.append(dayActivity)
//            if state.selectedDayActivities.contains(where: { $0.id == dayActivity.id }) {
//              state.selectedDayActivities.removeAll(where: { $0.id == dayActivity.id })
//            }
//          }
        }
        return .none
      case .dayActivityForm(.presented(.delegate(.activityDeleted(let dayActivity)))):
//        return .run { [activity] send in
//          await send(.internal(.loadActivities))
//          await send(.delegate(.activityUpdated(activity)))
//        }
        return .none
      case .dayActivityForm:
        return .none
      case .delegate:
        return .none
      case .binding(\.searchText):
        if state.searchText.isEmpty {
          state.activityPlaceholder = nil
        } else {
          state.activityPlaceholder = ActivityPlaceholder(
            id: uuid(),
            name: state.searchText
          )
        }
        return .none
      case .binding:
        return .none
      }
    }
    .ifLet(\.$templateForm, action: \.templateForm) {
      DayActivityFormFeature()
    }
    .ifLet(\.$dayActivityForm, action: \.dayActivityForm) {
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
