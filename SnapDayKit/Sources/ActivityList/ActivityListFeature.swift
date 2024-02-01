import Foundation
import ComposableArchitecture
import ActivityForm
import Repositories
import Utilities
import Models
import Common

public struct ActivityListFeature: Reducer {

  // MARK: - Dependencies

  @Dependency(\.activityRepository.loadActivities) private var loadActivities
  @Dependency(\.dismiss) private var dismiss
  @Dependency(\.uuid) private var uuid

  // MARK: - State & Action

  public struct State: Equatable {
    var activities: [Activity] = []
    var selectedActivities: [Activity] = []

    @PresentationState var addActivity: ActivityFormFeature.State?

    public init() { }
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
        if state.selectedActivities.contains(activity) {
          state.selectedActivities.removeAll(where: { $0.id == activity.id })
        } else {
          state.selectedActivities.append(activity)
        }
        return .none
      case .view(.activityEditTapped(let activity)):
        state.addActivity = ActivityFormFeature.State(
          activity: activity,
          type: .edit
        )
        return .none
      case .internal(.loadOnStart):
        return .run { send in
          await send(.internal(.loadActivities))
        }
      case .internal(.loadActivities):
        return .run { send in
          let activities = try await loadActivities()
          await send(.internal(.activitiesLoaded(activities)))
        }
      case .internal(.activitiesLoaded(let activities)):
        state.activities = activities
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
    .ifLet(\.$addActivity, action: /Action.addActivity) {
      ActivityFormFeature()
    }
  }

  // MARK: - Initialization

  public init() { }
}
