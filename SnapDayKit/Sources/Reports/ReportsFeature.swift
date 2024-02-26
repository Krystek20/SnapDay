import Foundation
import ComposableArchitecture
import Repositories
import Utilities
import Models
import Common
import Combine

struct ReportDay: Equatable, Identifiable {
  let id: String
  let title: String?
  let dayActivity: ReportDayActivity
}

enum ReportDayActivity: Equatable {
  case tag(Bool)
  case activity(Bool)
  case notPlanned
  case empty
}

struct ReportSummary: Equatable {
  let doneCount: Int
  let notDoneCount: Int
  let duration: Int

  var isZero: Bool {
    doneCount == .zero && notDoneCount == .zero && duration == .zero
  }

  static let zero = ReportSummary(doneCount: .zero, notDoneCount: .zero, duration: .zero)
}

public struct ReportsFeature: Reducer, TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.calendar) private var calendar
  @Dependency(\.dayRepository) private var dayRepository
  @Dependency(\.tagRepository) private var tagRepository

  // MARK: - State & Action

  public struct State: Equatable, TodayProvidable {

    var dateFilters = FilterPeriod.allCases
    @BindingState var selectedFilterPeriod: FilterPeriod?
    @BindingState var startDate: Date = Date()
    @BindingState var endDate: Date = Date()

    var tags: [Tag] = []
    @BindingState var selectedTag: Tag?

    var days: [Day] = []
    var activities: [Activity] = []
    @BindingState var selectedActivity: Activity?
    var reportDays: [ReportDay] = []
    var summary: ReportSummary = .zero
    var periodShift = Int.zero

    var filterDate: FilterDate? {
      didSet {
        startDate = filterDate?.range.lowerBound ?? today
        endDate = filterDate?.range.upperBound ?? today
      }
    }
    var showCustomDate: Bool {
      selectedFilterPeriod == .custom
    }

    public init(selectedFilterDate: FilterPeriod? = .week) {
      self.selectedFilterPeriod = selectedFilterDate
    }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case previousPeriodTapped
      case nextPeriodTapped
    }
    public enum InternalAction: Equatable {
      case loadDays
      case daysLoaded([Day])
      case tagsLoaded([Tag])
      case loadSummary
      case loadReportDays
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
        state.filterDate = FilterDate(filter: state.selectedFilterPeriod, lowerBound: today, upperBound: nil)
        return .run { send in
          let tags = try await tagRepository.loadTags([])
          await send(.internal(.tagsLoaded(tags)))
          await send(.internal(.loadDays))
        }
      case .view(.previousPeriodTapped):
        state.periodShift -= 1
        let range = prepareDateRange(for: state.selectedFilterPeriod, shiftPeriod: state.periodShift)
        state.filterDate = FilterDate(filter: state.selectedFilterPeriod, lowerBound: range.lowerBound, upperBound: range.upperBound)
        return .run { send in
          await send(.internal(.loadDays))
        }
      case .view(.nextPeriodTapped):
        state.periodShift += 1
        let range = prepareDateRange(for: state.selectedFilterPeriod, shiftPeriod: state.periodShift)
        state.filterDate = FilterDate(filter: state.selectedFilterPeriod, lowerBound: range.lowerBound, upperBound: range.upperBound)
        return .run { send in
          await send(.internal(.loadDays))
        }
      case .internal(.tagsLoaded(let tags)):
        state.tags = tags.sorted(by: { $0.name < $1.name })
        state.selectedTag = state.tags.first
        return .none
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

        state.activities = activities.filter { $0.tags.contains(where: { $0 == state.selectedTag }) }
        state.selectedActivity = nil

        return .run { send in
          await send(.internal(.loadSummary))
          await send(.internal(.loadReportDays))
        }
      case .internal(.loadSummary):
        let reportSummaryProvider = ReportSummaryProvider()
        state.summary = reportSummaryProvider.prepareSummary(
          days: state.days,
          selectedActivity: state.selectedActivity,
          selectedTag: state.selectedTag,
          today: today
        )
        return .none
      case .internal(.loadReportDays):
        let reportDaysProvider = ReportDaysProvider()
        state.reportDays = reportDaysProvider.prepareReportDays(
          selectedFilterPeriod: state.selectedFilterPeriod,
          selectedActivity: state.selectedActivity,
          selectedTag: state.selectedTag,
          days: state.days
        )
        return .none
      case .binding(\.$selectedFilterPeriod):
        let range = prepareDateRange(for: state.selectedFilterPeriod, shiftPeriod: state.periodShift)
        state.filterDate = FilterDate(filter: state.selectedFilterPeriod, lowerBound: range.lowerBound, upperBound: range.upperBound)
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
      case .binding(\.$selectedTag):
        state.activities = Array(Set((state.days.map { $0.activities.map(\.activity) }).joined()))
          .filter { $0.tags.contains(where: { $0 == state.selectedTag }) }
          .sorted(by: { $0.name < $1.name })
        state.selectedActivity = nil
        return .run { send in
          await send(.internal(.loadSummary))
          await send(.internal(.loadReportDays))
        }
      case .binding(\.$selectedActivity):
        return .run { send in
          await send(.internal(.loadSummary))
          await send(.internal(.loadReportDays))
        }
      case .binding:
        return .none
      }
    }
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Private

  private func prepareDateRange(for selectedFilter: FilterPeriod?, shiftPeriod: Int) -> ClosedRange<Date> {
    guard let selectedFilter else { return today...today }
    var lowerBound = today
    switch selectedFilter {
    case .day:
      lowerBound = calendar.date(byAdding: .day, value: shiftPeriod, to: lowerBound) ?? lowerBound
      return lowerBound...lowerBound
    case .week:
      let shift = shiftPeriod != .zero ? shiftPeriod * 7 : .zero
      lowerBound = calendar.date(byAdding: .day, value: shift, to: lowerBound) ?? lowerBound
      return lowerBound...lowerBound
    case .month:
      lowerBound = calendar.date(byAdding: .month, value: shiftPeriod, to: lowerBound) ?? lowerBound
      return lowerBound...lowerBound
    case .quarter:
      let shift = shiftPeriod != .zero ? shiftPeriod * 3 : .zero
      lowerBound = calendar.date(byAdding: .month, value: shift, to: lowerBound) ?? lowerBound
      return lowerBound...lowerBound
    case .custom:
      lowerBound = calendar.date(byAdding: .month, value: -1, to: lowerBound) ?? today
      return lowerBound...today
    }
  }
}
