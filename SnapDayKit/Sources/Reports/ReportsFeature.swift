import Foundation
import ComposableArchitecture
import Repositories
import Utilities
import Models
import Common
import Combine

struct ReportDay: Equatable, Identifiable {
  var id: String { date.description }
  let date: Date
  let dayActivity: ReportDayActivity
}

enum ReportDayActivity: Equatable {
  case tags([Tag])
  case activities([Activity])
}

public struct ReportsFeature: Reducer, TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.calendar) private var calendar
  @Dependency(\.dayRepository) private var dayRepository

  // MARK: - State & Action

  public struct State: Equatable, TodayProvidable {

    var dateFilters = FilterPeriod.allCases
    @BindingState var selectedFilterDate: FilterPeriod?
    @BindingState var startDate: Date = Date()
    @BindingState var endDate: Date = Date()

    var tags: [Tag] = []
    @BindingState var selectedTag: [Tag] = []

    var days: [Day] = []
    var allActivities: [Activity] = []
    var activities: [Activity] = []
    @BindingState var selectedActivities: [Activity] = []
    var reportDays: [ReportDay] = []

    var filterDate: FilterDate? {
      didSet {
        startDate = filterDate?.range.lowerBound ?? today
        endDate = filterDate?.range.upperBound ?? today
      }
    }
    var showCustomDate: Bool {
      selectedFilterDate == .custom
    }

    public init(selectedFilterDate: FilterPeriod? = .week) {
      self.selectedFilterDate = selectedFilterDate
    }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
    }
    public enum InternalAction: Equatable {
      case loadDays
      case daysLoaded([Day])
    }
    public enum DelegateAction: Equatable {

    }

    case binding(BindingAction<State>)

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
        state.filterDate = FilterDate(filter: state.selectedFilterDate, lowerBound: today, upperBound: nil)
        return .run { send in
          await send(.internal(.loadDays))
        }
      case .internal(.loadDays):
        guard let filterDate = state.filterDate else { return .none }
        return .run { [dateRange = filterDate.range] send in
          let days = try await dayRepository.loadDays(dateRange)
          await send(.internal(.daysLoaded(days)))
        }
      case .internal(.daysLoaded(let days)):
        state.days = days
        let activities = Array(Set((days.map { $0.activities.map(\.activity) }).joined()))
          .sorted(by: { $0.name < $1.name })
        state.allActivities = activities
        state.activities = activities
        let tags = Array(Set(activities.map(\.tags).joined()))
          .sorted(by: { $0.name < $1.name })
        state.tags = tags
        prepareReportDays(state: &state)
        return .none
      case .binding(\.$selectedFilterDate):
        let range = prepareDateRange(for: state.selectedFilterDate)
        state.filterDate = FilterDate(filter: state.selectedFilterDate, lowerBound: range.lowerBound, upperBound: range.upperBound)
        return .run { send in
          await send(.internal(.loadDays))
        }
      case .binding(\.$startDate):
        state.filterDate = state.filterDate?.setStartDate(state.startDate)
        return .run { send in
          await send(.internal(.loadDays))
        }
      case .binding(\.$endDate):
        state.filterDate = state.filterDate?.setEndDate(state.endDate)
        return .run { send in
          await send(.internal(.loadDays))
        }
      case .binding(\.$selectedTags):
        if state.selectedTags.isEmpty {
          state.activities = state.allActivities
          state.selectedActivities.removeAll()
        } else {
          state.activities = state.allActivities.filter {
            let selectedSet = Set(state.selectedTags)
            let activitiesTagsSet = Set($0.tags)
            return selectedSet.intersection(activitiesTagsSet).count > .zero
          }
          let selectedSet = Set(state.selectedActivities)
          let activitiesSet = Set(state.activities)
          state.selectedActivities = Array(selectedSet.intersection(activitiesSet))
        }
        prepareReportDays(state: &state)
        return .none
      case .binding:
        return .none
      }
    }
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Private

  private func prepareDateRange(for selectedFilter: FilterPeriod?) -> ClosedRange<Date> {
    guard let selectedFilter else { return today...today }
    var lowerBound = today
    if case .custom = selectedFilter {
      lowerBound = calendar.date(byAdding: .month, value: -1, to: lowerBound) ?? today
    }
    return lowerBound...today
  }

  private func prepareReportDays(state: inout State) {
    if state.selectedTags.isEmpty && state.selectedActivities.isEmpty {
      state.reportDays = state.days.map { day in
        let tags = Set(day.activities.map { activity in
          activity.activity.tags
        }.joined())
        return ReportDay(
          date: day.date,
          dayActivity: .tags(Array(tags))
        )
      }
    }
  }
}
