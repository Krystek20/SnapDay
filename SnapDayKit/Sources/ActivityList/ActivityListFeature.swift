import Foundation
import ComposableArchitecture
import ActivityForm
import Repositories
import Utilities
import Models
import Common

@Reducer
public struct ActivityListFeature {

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

    public init(type: ActivityListType, isActivityEditable: Bool, fetchingOption: ActivityListFetchingOption) {
      self.type = type
      self.isActivityEditable = isActivityEditable
      self.fetchingOption = fetchingOption
    }
  }

  // MARK: - Dependencies

  @Dependency(\.activityRepository.loadActivities) private var loadActivities
  @Dependency(\.dismiss) private var dismiss
  @Dependency(\.uuid) private var uuid

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    var activities: [Activity] = []
    var selectedActivities: [Activity] = []
    var configuration: ActivityListConfiguration

    var showButton: Bool {
      guard case .multiSelection = configuration.type else { return false }
      return true
    }

    @Presents var addActivity: ActivityFormFeature.State?

    public init(configuration: ActivityListConfiguration) {
      self.configuration = configuration
    }
  }

  public enum Action: Equatable {
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
      case activitiesSelected([Activity])
    }

    case addActivity(PresentationAction<ActivityFormFeature.Action>)

    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
  }

  enum NSCalendarDayChanged { }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
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
        state.addActivity = ActivityFormFeature.State(
          activity: Activity(id: uuid())
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
      case .view(.activityEditTapped(let activity)):
        state.addActivity = ActivityFormFeature.State(
          activity: activity,
          type: .edit
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
          }
        }
      case .internal(.loadActivities):
        return .run { send in
          let activities = try await loadActivities()
          await send(.internal(.activitiesLoaded(activities)))
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
      case .addActivity(.presented(.delegate(.activityCreated(let activity)))):
        return .run { [activity] send in
          await send(.internal(.loadActivities))
          await send(.delegate(.activityAdded(activity)))
        }
      case .addActivity(.presented(.delegate(.activityUpdated(let activity)))):
        return .run { [activity] send in
          await send(.internal(.loadActivities))
          await send(.delegate(.activityUpdated(activity)))
        }
      case .addActivity:
        return .none
      case .delegate:
        return .none
      }
    }
    .ifLet(\.$addActivity, action: \.addActivity) {
      ActivityFormFeature()
    }
  }

  // MARK: - Initialization

  public init() { }
}
