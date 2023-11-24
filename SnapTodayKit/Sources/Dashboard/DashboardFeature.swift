import Foundation
import ComposableArchitecture
import ActivityForm
import Repositories
import Utilities
import Models

public struct DashboardFeature: Reducer {

  // MARK: - Dependencies

  @Dependency(\.activityRepository.loadActivities) var loadActivities
  @Dependency(\.dayRepository) var dayRepository
  @Dependency(\.dayActivityRepository) var dayActivityRepository
  @Dependency(\.planRepository) var planRepository
  @Dependency(\.planEditor) var planEditor
  @Dependency(\.dayEditor) var dayEditor
  @Dependency(\.uuid) var uuid

  private var today: Date {
    @Dependency(\.calendar) var calendar
    @Dependency(\.date.now) var now
    return calendar.dayFormat(now)
  }

  // MARK: - State & Action

  public struct State: Equatable {
    let userName: String
    var activities: [Activity] = []
    var plans: [Plan] = []
    var dayActivities: [DayActivity] {
      guard let day else { return [] }
      return day.activities.sorted(by: {
        if $0.isDone == $1.isDone {
          return $0.activity.name < $1.activity.name
        }
        return !$0.isDone && $1.isDone
      })
    }
    @PresentationState var addActivity: ActivityFormFeature.State?
    var day: Day?

    public init(userName: String = NSUserName()) {
      self.userName = userName
    }
  }

  public enum Action: Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case addButtonTapped
      case dayActivityTapped(DayActivity)
      case dayActivityEditTapped(DayActivity)
      case dayActivityRemoveTapped(DayActivity)
      case activityTapped(Activity)
      case activityEditTapped(Activity)
    }
    public enum InternalAction: Equatable {
      case loadActivities
      case activitiesLoaded(_ activitiexs: [Activity])
      case loadPlans
      case plansLoaded(_ plans: [Plan])
      case loadDay
      case dayLoaded(_ day: Day?)
    }
    public enum DelegateAction: Equatable {
      case startGameTapped
    }

    case addActivity(PresentationAction<ActivityFormFeature.Action>)

    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
  }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .view(.appeared):
        return .run { send in
          try await planEditor.composePlans(today)
          await send(.internal(.loadActivities))
          await send(.internal(.loadPlans))
          await send(.internal(.loadDay))
        }
      case .view(.addButtonTapped):
        state.addActivity = ActivityFormFeature.State(
          activity: Activity(id: uuid())
        )
        return .none
      case .view(.dayActivityTapped(var dayActivity)):
        guard !dayActivity.isDone else { return .none }
        dayActivity.isDone = true
        return .run { [dayActivity] send in
          try await dayActivityRepository.saveActivity(dayActivity)
          await send(.internal(.loadPlans))
          await send(.internal(.loadDay))
        }
      case .view(.dayActivityEditTapped(var dayActivity)):
        print("dayActivityEditTapped: \(dayActivity.activity.name)")
        return .none
      case .view(.dayActivityRemoveTapped(let dayActivity)):
        return .run { [dayActivity] send in
          try await dayEditor.removeDayActivity(dayActivity, today)
          await send(.internal(.loadPlans))
          await send(.internal(.loadDay))
        }
      case .view(.activityTapped(let activity)):
        return .run { send in
          try await dayEditor.addActivity(activity, today)
          await send(.internal(.loadPlans))
          await send(.internal(.loadDay))
        }
      case .view(.activityEditTapped(let activity)):
        state.addActivity = ActivityFormFeature.State(
          activity: activity,
          type: .edit
        )
        return .none
      case .internal(.loadActivities):
        return .run { send in
          let activities = try await loadActivities()
          await send(.internal(.activitiesLoaded(activities)))
        }
      case .internal(.activitiesLoaded(let activities)):
        state.activities = activities
        return .none
      case .internal(.loadPlans):
        return .run { send in
          let plans = try await planRepository.loadPlans(today, nil)
          await send(.internal(.plansLoaded(plans)))
        }
      case .internal(.plansLoaded(let plans)):
        state.plans = plans.sorted(by: { $0.dateRange.upperBound < $1.dateRange.upperBound })
        return .none
      case .internal(.loadDay):
        return .run { send in
          let day = try await dayRepository.loadDay(today)
          await send(.internal(.dayLoaded(day)))
        }
      case .internal(.dayLoaded(let day)):
        state.day = day
        return .none
      case .addActivity(.presented(.delegate(.activityCreated(let activity)))):
        return .run { [activity] send in
          await send(.internal(.loadActivities))
          guard activity.isRepeatable else { return }
          try await dayEditor.updateDays(activity, today)
          await send(.internal(.loadPlans))
          await send(.internal(.loadDay))
        }
      case .addActivity(.presented(.delegate(.activityUpdated(let activity)))):
        return .run { [activity] send in
          await send(.internal(.loadActivities))
          try await dayEditor.updateDayActivities(activity, today)
          await send(.internal(.loadPlans))
          await send(.internal(.loadDay))
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
