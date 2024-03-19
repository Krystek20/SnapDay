import Foundation
import ComposableArchitecture
import Repositories
import Utilities
import Models
import Common
import Combine
import TagList
import ActivityList

public struct ReportsFeature: Reducer, TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.calendar) private var calendar
  @Dependency(\.dayRepository) private var dayRepository
  @Dependency(\.tagRepository) private var tagRepository

  // MARK: - State & Action

  public struct State: Equatable, TodayProvidable {

    var dateFilters = FilterPeriod.allCases
    @BindingState var selectedFilterPeriod: FilterPeriod
    @BindingState var startDate: Date = Date()
    @BindingState var endDate: Date = Date()

    @PresentationState var tagList: TagListFeature.State?
    @PresentationState var activityList: ActivityListFeature.State?

    var tagActivitySections: [TagActivitySection] = []
    var currectTagActivitySection: TagActivitySection? {
      tagActivitySections.first(where: { $0.tag == selectedTag })
    }

    var availableTags: [Tag] {
      allTags.filter { tag in
        days.contains(where: { $0.activities.contains(where: { $0.tags.contains(tag) }) })
      }
    }
    var allTags: [Tag] = []
    var selectedTag: Tag?

    var days: [Day] = []
    var activities: [Activity] = []
    var selectedActivity: Activity?
    var reportDays: [ReportDay] = []
    var summary: ReportSummary = .zero
    var periodShift = Int.zero
    var isSwitcherDismissed = false
    var switcherTitle: String = ""

    var filterDate: FilterDate? {
      didSet {
        startDate = filterDate?.range.lowerBound ?? today
        endDate = filterDate?.range.upperBound ?? today
        guard let filterDate, let title = try? PeriodTitleProvider().title(for: filterDate) else { return }
        switcherTitle = title
      }
    }
    
    var showCustomDate: Bool {
      selectedFilterPeriod == .custom
    }

    public init(selectedFilterDate: FilterPeriod = .month) {
      self.selectedFilterPeriod = selectedFilterDate
    }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case decreaseButtonTapped
      case increaseButtonTapped
      case tagTapped
      case selectActivityButtonTapped
    }
    public enum InternalAction: Equatable {
      case loadDays
      case daysLoaded([Day])
      case tagsLoaded([Tag])
      case loadSummary
      case loadReportDays
    }
    public enum DelegateAction: Equatable { }

    case tagList(PresentationAction<TagListFeature.Action>)
    case activityList(PresentationAction<ActivityListFeature.Action>)

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
      case .view(.decreaseButtonTapped):
        state.periodShift -= 1
        let range = prepareDateRange(for: state.selectedFilterPeriod, shiftPeriod: state.periodShift)
        state.filterDate = FilterDate(filter: state.selectedFilterPeriod, lowerBound: range.lowerBound, upperBound: range.upperBound)
        return .run { send in
          await send(.internal(.loadDays))
        }
      case .view(.increaseButtonTapped):
        state.periodShift += 1
        let range = prepareDateRange(for: state.selectedFilterPeriod, shiftPeriod: state.periodShift)
        state.filterDate = FilterDate(filter: state.selectedFilterPeriod, lowerBound: range.lowerBound, upperBound: range.upperBound)
        return .run { send in
          await send(.internal(.loadDays))
        }
      case .view(.tagTapped):
        guard let selectedTag = state.selectedTag else { return .none }
        state.tagList = TagListFeature.State(
          tag: selectedTag,
          tags: state.allTags,
          days: state.days
        )
        return .none
      case .view(.selectActivityButtonTapped):
        state.activityList = ActivityListFeature.State(
          configuration: ActivityListFeature.ActivityListConfiguration(
            type: .singleSelection(selectedActivity: state.selectedActivity),
            isActivityEditable: false,
            fetchingOption: .prefetched(state.activities)
          )
        )
        return .none
      case .internal(.tagsLoaded(let tags)):
        state.allTags = tags.sorted(by: { $0.name < $1.name })
        state.selectedTag = state.allTags.first
        return .none
      case .internal(.loadDays):
        guard let filterDate = state.filterDate else { return .none }
        return .run { [dateRange = filterDate.range] send in
          let days = try await dayRepository.loadDays(dateRange)
          await send(.internal(.daysLoaded(days)))
        }
      case .internal(.daysLoaded(let days)):
        state.days = days
        state.activities = days.map { day in
          day.activities.compactMap { dayActivity -> Activity? in
            guard dayActivity.tags.contains(where: { $0 == state.selectedTag }) else { return nil }
            return dayActivity.activity
          }
        }
        .joined()
        .sorted(by: { $0.name < $1.name })
        state.selectedActivity = nil

        setupSectionsAndSelectedTag(&state, days: days)

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
        state.isSwitcherDismissed = state.selectedFilterPeriod == .custom
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
      case .tagList(.presented(.delegate(.tagSelected(let tag)))):
        state.selectedTag = tag
        state.selectedActivity = nil
        state.activities = state.days.map { day in
          day.activities.compactMap { dayActivity -> Activity? in
            guard dayActivity.tags.contains(where: { $0 == state.selectedTag }) else { return nil }
            return dayActivity.activity
          }
        }
        .joined()
        .sorted(by: { $0.name < $1.name })
        return .run { send in
          await send(.internal(.loadSummary))
          await send(.internal(.loadReportDays))
        }
      case .tagList:
        return .none
      case .activityList(.presented(.delegate(.activitiesSelected(let activities)))):
        state.selectedActivity = activities.first
        return .run { send in
          await send(.internal(.loadSummary))
          await send(.internal(.loadReportDays))
        }
      case .activityList:
        return .none
      case .binding:
        return .none
      }
    }
    .ifLet(\.$tagList, action: /Action.tagList) {
      TagListFeature()
    }
    .ifLet(\.$activityList, action: /Action.activityList) {
      ActivityListFeature()
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

  private func setupSectionsAndSelectedTag(_ state: inout State, days: [Day]) {
    let tagSectionsProvider = TagSectionsProvider()
    state.tagActivitySections = tagSectionsProvider.sections(for: days)
  }

  private func abc(days: [Day], selectedTag: Tag) {

  }
}
