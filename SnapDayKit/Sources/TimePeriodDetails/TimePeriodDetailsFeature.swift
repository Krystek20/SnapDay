import Foundation
import ComposableArchitecture
import Models
import Repositories
import Utilities
import Common
import ActivityList
import DayActivityForm
import ActivityForm

public struct TimePeriodDetailsFeature: Reducer, TodayProvidable {

  // MARK: - Dependecies

  @Dependency(\.dayEditor) private var dayEditor
  @Dependency(\.dayActivityRepository) private var dayActivityRepository
  @Dependency(\.timePeriodsProvider) private var timePeriodsProvider
  @Dependency(\.uuid) private var uuid
  @Dependency(\.calendar) private var calendar

  // MARK: - State & Action

  public struct State: Equatable, TodayProvidable {

    var timePeriod: TimePeriod
    var timePeriodActivitySections: [TimePeriodActivitySection] = []
    var activitiesPresentationType: ActivitiesPresentationType?
    var dayToUpdate: Day?
    @BindingState var selectedDay: Day?
    @BindingState var selectedTag: Tag?
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
        setupTimePeriodConfiguration(&state)
        return .none
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
      case .internal(.timePeriodLoaded(let timePeriod)):
        state.timePeriod = timePeriod
        setupTimePeriodConfiguration(&state)
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

  // MARK: - Private

  private func setupTimePeriodConfiguration(_ state: inout State) {
    setupSectionsAndSelectedTag(&state)
    setupPresentationTypeAndSelectedDay(&state)
  }

  private func setupSectionsAndSelectedTag(_ state: inout State) {
    let timePeriodActivitySectionProvider = TimePeriodActivitySectionProvider()
    let sections = timePeriodActivitySectionProvider.timePeriodActivitiesSections(for: state.timePeriod)
    state.timePeriodActivitySections = sections
    state.selectedTag = sections.first?.tag
  }

  private func setupPresentationTypeAndSelectedDay(_ state: inout State) {
    let presentationTypeProvider = ActivitiesPresentationTypeProvider()
    let presentationType = presentationTypeProvider.presentationType(for: state.timePeriod)
    state.activitiesPresentationType = presentationType
    state.selectedDay = findSelectedDay(for: presentationType, currentSelectedDay: state.selectedDay)
  }

  private func findSelectedDay(for presentationType: ActivitiesPresentationType?, currentSelectedDay: Day?) -> Day? {
    guard let presentationType else { return nil }
    if case .days(let days) = presentationType {
      return currentSelectedDay != nil
      ? days.first(where: { $0.date == currentSelectedDay?.date })
      : days.first(where: { $0.date == today })
    } else if case .month(_, let calendarItems) = presentationType {
      return currentSelectedDay != nil
      ? calendarItems.first(where: {
        guard case .day(let day) = $0 else { return false }
        return day.date == currentSelectedDay?.date
      })?.day
      : calendarItems.first(where: {
        guard case .day(let day) = $0 else { return false }
        return day.date == today
      })?.day
    }
    return nil
  }
}
