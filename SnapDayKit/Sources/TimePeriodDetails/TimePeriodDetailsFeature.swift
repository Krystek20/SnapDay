import Foundation
import ComposableArchitecture
import Models
import Repositories
import Utilities
import Common
import ActivityList
import DayActivityForm
import ActivityForm

enum PresentationMode: String, Identifiable {
  case list
  case grid

  var id: Self { self }
}

public enum ActivitiesPresentationType: Equatable {
  case monthlyGrid([TimePeriod])
  case unowned
}

public struct TimePeriodDetailsFeature: Reducer, TodayProvidable {

  // MARK: - Dependecies

  @Dependency(\.dayEditor) private var dayEditor
  @Dependency(\.dayActivityRepository) private var dayActivityRepository
  @Dependency(\.timePeriodsProvider) private var timePeriodsProvider
  @Dependency(\.uuid) private var uuid

  // MARK: - State & Action

  public struct State: Equatable, TodayProvidable {

    var timePeriod: TimePeriod

    var activitiesPresentationType: ActivitiesPresentationType?
    var dayToUpdate: Day?
    @BindingState var presentationMode: PresentationMode = .list
    @PresentationState var activityList: ActivityListFeature.State?
    @PresentationState var editDayActivity: DayActivityFormFeature.State?
    @PresentationState var addActivity: ActivityFormFeature.State?

    var summaryType: SummaryType {
      guard timePeriod.type == .day else {
        return .chart(
          points: timePeriod.completedDaysValues(until: today),
          expectedPoints: timePeriod.days.count
        )
      }
      return .circle(progress: timePeriod.completedDaysValues(until: today).first ?? .zero)
    }

    var days: [Day] {
      timePeriod.days
        .map(updateDay)
        .sorted(by: { $0.date < $1.date })
    }

    public init(timePeriod: TimePeriod) {
      self.timePeriod = timePeriod
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
      case appear
      case activityListButtonTapped(Day)
      case oneTimeActivityButtonTapped(Day)
      case dayActivityTapped(DayActivity)
      case removeDayActivityTapped(DayActivity, Day)
      case dayActivityEditTapped(DayActivity, Day)
    }
    public enum InternalAction: Equatable { 
      case loadTimePeriod
      case timePeriodLoaded(TimePeriod)
      case removeDayActivity(DayActivity, Day)
      case setActivitiesPresentation(ActivitiesPresentationType)
    }
    public enum DelegateAction: Equatable {
      case startGameTapped
    }

    case binding(BindingAction<State>)

    case activityList(PresentationAction<ActivityListFeature.Action>)
    case editDayActivity(PresentationAction<DayActivityFormFeature.Action>)
    case addActivity(PresentationAction<ActivityFormFeature.Action>)

    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
  }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(.appear):
        return .run { [timePeriod = state.timePeriod] send in
          switch timePeriod.type {
          case .day: break
          case .week: break
          case .month: break
          case .quarter: break
//            let plans = try await planRepository.loadPlans(plan.dateRange.lowerBound, .monthly)
//            await send(.internal(.setActivitiesPresentation(.monthlyGrid(plans))))
          }
        }
      case .view(.activityListButtonTapped(let day)):
        state.dayToUpdate = day
        state.activityList = ActivityListFeature.State()
        return .none
      case .view(.oneTimeActivityButtonTapped(let day)):
        state.dayToUpdate = day
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
          await send(.internal(.loadTimePeriod))
        }
      case .view(.removeDayActivityTapped(let dayActivity, let day)):
        return .run { send in
          await send(.internal(.removeDayActivity(dayActivity, day)))
        }
      case .view(.dayActivityEditTapped(let dayActivity, let day)):
        state.dayToUpdate = day
        state.editDayActivity = DayActivityFormFeature.State(dayActivity: dayActivity)
        return .none
      case .internal(.loadTimePeriod):
        return .run { [period = state.timePeriod.type] send in
          let timePeriods = try await timePeriodsProvider.timePerdiods(today)
          guard let timePeriod = timePeriods.first(where: { $0.type == period && $0.dateRange.contains(today) }) else { return }
          await send(.internal(.timePeriodLoaded(timePeriod)))
        }
      case .internal(.setActivitiesPresentation(let activitiesPresentationType)):
        state.activitiesPresentationType = activitiesPresentationType
        return .none
      case .internal(.timePeriodLoaded(let timePeriod)):
        state.timePeriod = timePeriod
        return .none
      case .internal(.removeDayActivity(let dayActivity, let day)):
        return .run { send in
          try await dayEditor.removeDayActivity(dayActivity, day.date)
          await send(.internal(.loadTimePeriod))
        }
      case .activityList(.presented(.delegate(.activitiesSelected(let activities)))):
        guard let dayToUpdate = state.dayToUpdate else { return .none }
        return .run { [activities, dayToUpdate] send in
          for activity in activities {
            try await dayEditor.addActivity(activity, dayToUpdate.date)
          }
          await send(.internal(.loadTimePeriod))
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
          await send(.internal(.loadTimePeriod))
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
      case .addActivity(.presented(.delegate(.activityCreated(let activity)))):
        guard let dayToUpdate = state.dayToUpdate else { return .none }
        return .run { [activity, dayToUpdate] send in
          try await dayEditor.addActivity(activity, dayToUpdate.date)
          await send(.internal(.loadTimePeriod))
        }
      case .addActivity(.dismiss):
        state.dayToUpdate = nil
        return .none
      case .addActivity:
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
    .ifLet(\.$addActivity, action: /Action.addActivity) {
      ActivityFormFeature()
    }
  }

  // MARK: - Initialization

  public init() { }
}

extension TimePeriod {
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
