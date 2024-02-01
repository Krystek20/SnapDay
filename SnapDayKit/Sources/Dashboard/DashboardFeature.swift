import Foundation
import ComposableArchitecture
import ActivityList
import DayActivityForm
import Repositories
import Utilities
import Models
import Common
import ActivityForm
import Combine

public struct DashboardFeature: Reducer, TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.dayRepository) private var dayRepository
  @Dependency(\.dayActivityRepository) private var dayActivityRepository
  @Dependency(\.planRepository) private var planRepository
  @Dependency(\.planEditor) private var planEditor
  @Dependency(\.dayEditor) private var dayEditor
  @Dependency(\.uuid) private var uuid

  // MARK: - State & Action

  public struct State: Equatable {
    var plans: [Plan] = []
    var day: Day?
    var dayActivities: [DayActivity] { day?.sortedDayActivities ?? [] }
    var daySummary: DaySummary? {
      guard let day else { return nil }
      return DaySummary(day: day)
    }
    @PresentationState var activityList: ActivityListFeature.State?
    @PresentationState var editDayActivity: DayActivityFormFeature.State?
    @PresentationState var addActivity: ActivityFormFeature.State?

    public init() { }
  }

  public enum Action: Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case activityListButtonTapped
      case oneTimeActivityButtonTapped
      case dayActivityTapped(DayActivity)
      case dayActivityEditTapped(DayActivity)
      case dayActivityRemoveTapped(DayActivity)
      case planTapped(Plan)
    }
    public enum InternalAction: Equatable {
      case loadOnStart
      case loadPlans
      case plansLoaded(_ plans: [Plan])
      case loadDay
      case dayLoaded(_ day: Day?)
      case removeDayActivity(_ dayActivity: DayActivity)
      case calendarDayChanged
    }
    public enum DelegateAction: Equatable {
      case planTapped(Plan)
    }

    case activityList(PresentationAction<ActivityListFeature.Action>)
    case editDayActivity(PresentationAction<DayActivityFormFeature.Action>)
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
        return .concatenate(
          .run { send in
            await send(.internal(.loadOnStart))
          },
          .run { send in
            for await _ in NotificationCenter.default.publisher(for: .NSCalendarDayChanged).values {
              await send(.internal(.calendarDayChanged))
            }
          }
        )
      case .view(.activityListButtonTapped):
        state.activityList = ActivityListFeature.State()
        return .none
      case .view(.oneTimeActivityButtonTapped):
        state.addActivity = ActivityFormFeature.State(
          activity: Activity(
            id: uuid(),
            isVisible: false
          )
        )
        return .none
      case .view(.dayActivityTapped(var dayActivity)):
        dayActivity.isDone.toggle()
        return .run { [dayActivity] send in
          try await dayActivityRepository.saveActivity(dayActivity)
          await send(.internal(.loadPlans))
          await send(.internal(.loadDay))
        }
      case .view(.dayActivityEditTapped(let dayActivity)):
        state.editDayActivity = DayActivityFormFeature.State(dayActivity: dayActivity)
        return .none
      case .view(.dayActivityRemoveTapped(let dayActivity)):
        return .run { send in
          await send(.internal(.removeDayActivity(dayActivity)))
        }
      case .view(.planTapped(let plan)):
        return .run { send in
          await send(.delegate(.planTapped(plan)))
        }
      case .internal(.calendarDayChanged):
        return .run { send in
          await send(.internal(.loadOnStart))
        }
      case .internal(.loadOnStart):
        return .run { send in
          try await planEditor.composePlans(today)
          await send(.internal(.loadPlans))
          await send(.internal(.loadDay))
        }
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
      case .internal(.removeDayActivity(let dayActivity)):
        return .run { [dayActivity] send in
          try await dayEditor.removeDayActivity(dayActivity, today)
          await send(.internal(.loadPlans))
          await send(.internal(.loadDay))
        }
      case .editDayActivity(.presented(.delegate(.activityUpdated(let dayActivity)))):
        return .run { [dayActivity] send in
          try await dayEditor.updateDayActivity(dayActivity, today)
          await send(.internal(.loadDay))
        }
      case .editDayActivity(.presented(.delegate(.activityDeleted(let dayActivity)))):
        return .run { send in
          await send(.internal(.removeDayActivity(dayActivity)))
        }
      case .activityList(.presented(.delegate(.activityAdded(let activity)))):
        return .run { [activity] send in
          try await dayEditor.updateDayActivities(activity, today)
          await send(.internal(.loadPlans))
          await send(.internal(.loadDay))
        }
      case .activityList(.presented(.delegate(.activityUpdated(let activity)))):
        return .run { [activity] send in
          try await dayEditor.updateDayActivities(activity, today)
          await send(.internal(.loadPlans))
          await send(.internal(.loadDay))
        }
      case .activityList(.presented(.delegate(.activitiesSelected(let activities)))):
        return .run { [activities] send in
          for activity in activities {
            try await dayEditor.addActivity(activity, today)
          }
          await send(.internal(.loadPlans))
          await send(.internal(.loadDay))
        }
      case .addActivity(.presented(.delegate(.activityCreated(let activity)))):
        return .run { [activity] send in
          try await dayEditor.addActivity(activity, today)
          await send(.internal(.loadPlans))
          await send(.internal(.loadDay))
        }
      case .activityList:
        return .none
      case .editDayActivity:
        return .none
      case .addActivity:
        return .none
      case .delegate:
        return .none
      }
    }
    .ifLet(\.$activityList, action: /Action.activityList) {
      ActivityListFeature()
    }
    .ifLet(\.$editDayActivity, action: /Action.editDayActivity) {
      DayActivityFormFeature()
    }
    .ifLet(\.$addActivity, action: /Action.addActivity) {
      ActivityFormFeature()
    }
  }

  // MARK: - Initialization

  public init() { }
}
