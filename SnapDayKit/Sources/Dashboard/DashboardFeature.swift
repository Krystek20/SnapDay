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
import enum UiComponents.DayViewShowButtonState

public struct DashboardFeature: Reducer, TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.timePeriodsProvider) private var timePeriodsProvider
  @Dependency(\.dayActivityRepository) private var dayActivityRepository
  @Dependency(\.dayEditor) private var dayEditor
  @Dependency(\.uuid) private var uuid
  private let periodTitleProvider = PeriodTitleProvider()

  // MARK: - State & Action

  public struct State: Equatable, TodayProvidable {
    
    var timePeriods: [TimePeriod] = []
    var activitiesPresentationType: ActivitiesPresentationType?
    var activityListOption: ActivityListOption = .collapsed
    var periods = Period.allCases
    var timePeriod: TimePeriod?
    var shift: Int = .zero
    var activitiesPresentationTitle = ""

    var daySummary: DaySummary? {
      guard let selectedDay else { return nil }
      return DaySummary(day: selectedDay)
    }

    var linearChartValues: (points: [Double], expectedPoints: Int)? {
      guard let timePeriod else { return nil }
      return (
        points: timePeriod.completedDaysValues(until: today),
        expectedPoints: timePeriod.days.count
      )
    }

    var activities: [DayActivity] {
      switch activityListOption {
      case .collapsed:
        selectedDay?.sortedDayActivities.filter { !$0.isDone } ?? []
      case .extended:
        selectedDay?.sortedDayActivities ?? []
      }
    }

    var dayViewShowButtonState: DayViewShowButtonState {
      guard let selectedDay,
            !selectedDay.activities.filter(\.isDone).isEmpty else { return .none }
      switch activityListOption {
      case .collapsed:
        return .show
      case .extended:
        return .hide
      }
    }

    @BindingState var selectedPeriod: Period = .day
    @BindingState var selectedDay: Day?

    @PresentationState var activityList: ActivityListFeature.State?
    @PresentationState var editDayActivity: DayActivityFormFeature.State?
    @PresentationState var addActivity: ActivityFormFeature.State?

    public init() { }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case activityListButtonTapped
      case oneTimeActivityButtonTapped
      case dayActivityTapped(DayActivity)
      case dayActivityEditTapped(DayActivity)
      case dayActivityRemoveTapped(DayActivity)
      case showCompletedActivitiesTapped
      case hideCompletedActivitiesTapped
      case reportButtonTapped
      case selectedPeriod(Period)
      case increaseButtonTapped
      case decreaseButtonTapped
    }
    public enum InternalAction: Equatable {
      case loadTimePeriods
      case timePeriodLoaded(_ timePeriod: TimePeriod)
      case removeDayActivity(_ dayActivity: DayActivity)
      case calendarDayChanged
    }
    public enum DelegateAction: Equatable {
      case reportsTapped
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
      case .view(.appeared):
        return .concatenate(
          .run { send in
            await send(.internal(.loadTimePeriods))
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
          await send(.internal(.loadTimePeriods))
        }
      case .view(.dayActivityEditTapped(let dayActivity)):
        state.editDayActivity = DayActivityFormFeature.State(dayActivity: dayActivity)
        return .none
      case .view(.dayActivityRemoveTapped(let dayActivity)):
        return .run { send in
          await send(.internal(.removeDayActivity(dayActivity)))
        }
      case .view(.showCompletedActivitiesTapped):
        state.activityListOption = .extended
        return .none
      case .view(.hideCompletedActivitiesTapped):
        state.activityListOption = .collapsed
        return .none
      case .view(.reportButtonTapped):
        return .run { send in
          await send(.delegate(.reportsTapped))
        }
      case .view(.selectedPeriod(let period)):
        state.selectedPeriod = period
        return .none
      case .view(.increaseButtonTapped):
        state.shift += 1
        return .run { send in
          await send(.internal(.loadTimePeriods))
        }
      case .view(.decreaseButtonTapped):
        state.shift -= 1
        return .run { send in
          await send(.internal(.loadTimePeriods))
        }
      case .internal(.calendarDayChanged):
        return .run { send in
          await send(.internal(.loadTimePeriods))
        }
      case .internal(.loadTimePeriods):
        return .run { [period = state.selectedPeriod, shift = state.shift] send in
          let timePerdiod = try await timePeriodsProvider.timePeriod(period, today, shift)
          await send(.internal(.timePeriodLoaded(timePerdiod)))
        }
      case .internal(.timePeriodLoaded(let timePeriod)):
        state.timePeriod = timePeriod
        setupTimePeriodConfiguration(&state, timePeriod: timePeriod)
        return .none
      case .internal(.removeDayActivity(let dayActivity)):
        return .run { [dayActivity, dayToUpdate = state.selectedDay] send in
          try await dayEditor.removeDayActivity(dayActivity, dayToUpdate?.date ?? today)
          await send(.internal(.loadTimePeriods))
        }
      case .editDayActivity(.presented(.delegate(.activityUpdated(let dayActivity)))):
        return .run { [dayActivity, dayToUpdate = state.selectedDay] send in
          try await dayEditor.updateDayActivity(dayActivity, dayToUpdate?.date ?? today)
          await send(.internal(.loadTimePeriods))
        }
      case .editDayActivity(.presented(.delegate(.activityDeleted(let dayActivity)))):
        return .run { send in
          await send(.internal(.removeDayActivity(dayActivity)))
        }
      case .activityList(.presented(.delegate(.activityAdded(let activity)))):
        return .run { [activity, dayToUpdate = state.selectedDay] send in
          try await dayEditor.updateDayActivities(activity, dayToUpdate?.date ?? today)
          await send(.internal(.loadTimePeriods))
        }
      case .activityList(.presented(.delegate(.activityUpdated(let activity)))):
        return .run { [activity, dayToUpdate = state.selectedDay] send in
          try await dayEditor.updateDayActivities(activity, dayToUpdate?.date ?? today)
          await send(.internal(.loadTimePeriods))
        }
      case .activityList(.presented(.delegate(.activitiesSelected(let activities)))):
        return .run { [activities, dayToUpdate = state.selectedDay] send in
          for activity in activities {
            try await dayEditor.addActivity(activity, dayToUpdate?.date ?? today)
          }
          await send(.internal(.loadTimePeriods))
        }
      case .addActivity(.presented(.delegate(.activityCreated(let activity)))):
        return .run { [activity, dayToUpdate = state.selectedDay] send in
          try await dayEditor.addActivity(activity, dayToUpdate?.date ?? today)
          await send(.internal(.loadTimePeriods))
        }
      case .activityList:
        return .none
      case .editDayActivity:
        return .none
      case .addActivity:
        return .none
      case .delegate:
        return .none
      case .binding(\.$selectedPeriod):
        state.shift = .zero
        return .run { send in
          await send(.internal(.loadTimePeriods))
        }
      case .binding:
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

  // MARK: - Private

  private func setupTimePeriodConfiguration(_ state: inout State, timePeriod: TimePeriod) {
    do {
      let presentationTypeProvider = ActivitiesPresentationTypeProvider()
      let presentationType = try presentationTypeProvider.presentationType(for: timePeriod)
      state.activitiesPresentationType = presentationType
      state.selectedDay = findSelectedDay(for: presentationType, currentSelectedDay: state.selectedDay)
      let filterDate = FilterDate(type: presentationType, dateRange: timePeriod.dateRange)
      state.activitiesPresentationTitle = try periodTitleProvider.title(for: filterDate)
    } catch {
      print(error)
    }
  }

  private func findSelectedDay(for presentationType: ActivitiesPresentationType, currentSelectedDay: Day?) -> Day? {
    switch presentationType {
    case .monthsList:
      return nil
    case .calendar(let calendarItems):
      let calendarDays = calendarItems.map(\.day)
      let todayDay = calendarItems.first(where: {
        guard case .day(let day) = $0 else { return false }
        return day.date == today
      })?.day
      guard let currentSelectedDate = currentSelectedDay?.date else { return todayDay }
      return calendarDays.contains(where: { $0?.date == currentSelectedDate })
      ? calendarItems.first(where: {
        guard case .day(let day) = $0 else { return false }
        return day.date == currentSelectedDay?.date
      })?.day
      : todayDay
    case .daysList(let style):
      switch style {
      case .single(let day):
        return day
      case .multi(let days):
        return days.contains(where: { $0.date == currentSelectedDay?.date })
        ? days.first(where: { $0.date == currentSelectedDay?.date })
        : days.first(where: { $0.date == today })
      }
    }
  }
}
