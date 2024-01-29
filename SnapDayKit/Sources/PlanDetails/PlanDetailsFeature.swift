import Foundation
import ComposableArchitecture
import Models
import Repositories
import Utilities
import Common
import ActivityList
import DayActivityForm

enum PresentationMode: String, Identifiable {
  case list
  case grid

  var id: Self { self }
}

public struct PlanDetailsFeature: Reducer, TodayProvidable {

  // MARK: - Dependecies

  @Dependency(\.dayEditor) private var dayEditor
  @Dependency(\.planRepository) private var planRepository
  @Dependency(\.dayActivityRepository) private var dayActivityRepository

  // MARK: - State & Action

  public struct State: Equatable, TodayProvidable {

    var plan: Plan

    var dayToUpdate: Day?
    @BindingState var presentationMode: PresentationMode = .list
    @PresentationState var activityList: ActivityListFeature.State?
    @PresentationState var editDayActivity: DayActivityFormFeature.State?

    var summaryType: SummaryType {
      guard plan.type == .daily else {
        return .chart(
          points: plan.completedDaysValues(until: today),
          expectedPoints: plan.days.count
        )
      }
      return .circle(progress: plan.completedDaysValues(until: today).first ?? .zero)
    }

    var days: [Day] {
      plan.days
        .map(updateDay)
        .sorted(by: { $0.date < $1.date })
    }

    public init(plan: Plan) {
      self.plan = plan
    }

    private func updateDay(_ day: Day) -> Day {
      var mutableDay = day
      mutableDay.isOlderThenToday = isPastDay(mutableDay)
      return mutableDay
    }

    private func isPastDay(_ day: Day) -> Bool {
      @Dependency(\.calendar) var calendar
      return calendar.compare(day.date, to: today, toGranularity: .day) == .orderedAscending
    }
  }

  public enum Action: BindableAction, FeatureAction, Equatable {
    public enum ViewAction: Equatable {
      case addButtonTapped(Day)
      case dayActivityTapped(DayActivity)
      case removeDayActivityTapped(DayActivity, Day)
      case dayActivityEditTapped(DayActivity, Day)
    }
    public enum InternalAction: Equatable { 
      case loadPlan
      case planLoaded(Plan)
      case removeDayActivity(DayActivity, Day)
    }
    public enum DelegateAction: Equatable {
      case startGameTapped
    }

    case binding(BindingAction<State>)

    case activityList(PresentationAction<ActivityListFeature.Action>)
    case editDayActivity(PresentationAction<DayActivityFormFeature.Action>)

    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
  }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(.addButtonTapped(let day)):
        state.dayToUpdate = day
        state.activityList = ActivityListFeature.State()
        return .none
      case .view(.dayActivityTapped(var dayActivity)):
        dayActivity.isDone.toggle()
        return .run { [dayActivity] send in
          try await dayActivityRepository.saveActivity(dayActivity)
          await send(.internal(.loadPlan))
        }
      case .view(.removeDayActivityTapped(let dayActivity, let day)):
        return .run { send in
          await send(.internal(.removeDayActivity(dayActivity, day)))
        }
      case .view(.dayActivityEditTapped(let dayActivity, let day)):
        state.dayToUpdate = day
        state.editDayActivity = DayActivityFormFeature.State(dayActivity: dayActivity)
        return .none
      case .internal(.loadPlan):
        return .run { [planType = state.plan.type] send in
          let plans = try await planRepository.loadPlans(today, planType)
          guard let plan = plans.first(where: { $0.type == planType && $0.dateRange.contains(today) }) else { return }
          await send(.internal(.planLoaded(plan)))
        }
      case .internal(.planLoaded(let plan)):
        state.plan = plan
        return .none
      case .internal(.removeDayActivity(let dayActivity, let day)):
        return .run { send in
          try await dayEditor.removeDayActivity(dayActivity, day.date)
          await send(.internal(.loadPlan))
        }
      case .activityList(.presented(.delegate(.activitiesSelected(let activities)))):
        guard let dayToUpdate = state.dayToUpdate else { return .none }
        return .run { [activities, dayToUpdate] send in
          for activity in activities {
            try await dayEditor.addActivity(activity, dayToUpdate.date)
          }
          await send(.internal(.loadPlan))
        }
      case .activityList(.dismiss):
        state.dayToUpdate = nil
        return .none
      case .activityList:
        return .none
      case .editDayActivity(.presented(.delegate(.activityUpdated(let dayActivity)))):
        return .run { [day = state.dayToUpdate, dayActivity] send in
          guard let day else { return }
          try await dayEditor.updateDayActivity(dayActivity, day.date)
          await send(.internal(.loadPlan))
        }
      case .editDayActivity(.presented(.delegate(.activityDeleted(let dayActivity)))):
        return .run { [day = state.dayToUpdate, dayActivity] send in
          guard let day else { return }
          await send(.internal(.removeDayActivity(dayActivity, day)))
        }
      case .editDayActivity(.dismiss):
        state.dayToUpdate = nil
        return .none
      case .editDayActivity:
        return .none
      case .binding:
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
  }

  // MARK: - Initialization

  public init() { }
}

extension Plan {
  func completedDaysValues(until date: Date) -> [Double] {
    let total = plannedCount
    return days
      .filter { $0.date <= date }
      .sorted(by: { $0.date < $1.date })
      .reduce(into: [Double](), { result, day in
        let value = (result.last ?? .zero) + Double(day.completedCount) / Double(total)
        result.append(value)
      })
  }
}
