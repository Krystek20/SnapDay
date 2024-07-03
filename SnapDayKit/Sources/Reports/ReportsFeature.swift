import Foundation
import ComposableArchitecture
import Repositories
import Utilities
import Models
import Common
import Combine
import SelectableList
import struct UiComponents.PeriodViewModel
import struct UiComponents.PeriodViewModelProvider

@Reducer
public struct ReportsFeature: TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.calendar) private var calendar
  @Dependency(\.tagRepository) private var tagRepository
  private let dayProvider = DayProvider()

  // MARK: - State & Action

  enum ListId: String {
    case tag
    case activity
    case label
  }

  @ObservableState
  public struct State: Equatable, TodayProvidable {

    var dateFilters = FilterPeriod.allCases
    var selectedFilterPeriod: FilterPeriod
    var startDate: Date = Date()
    var endDate: Date = Date()

    @Presents var selectableList: SelectableListViewFeature.State?

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

    var showLabel: Bool {
      selectedActivity?.labels.isEmpty == false
    }
    var selectedLabel: ActivityLabel?
    
    var periods: [PeriodViewModel] {
      guard selectedFilterPeriod == .quarter else { return [] }
      let provider = PeriodViewModelProvider()
      return provider.preparePeriodViewModel(from: days, to: .month)
    }

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

    var linearChartValues: LinearChartValues? {
      let linearChartValuesProvider = LinearChartValuesProvider()
      switch selectedFilterPeriod {
      case .day:
        guard let day = days.first else { return nil }
        return linearChartValuesProvider.prepareValues(for: day)
      case .week, .month, .quarter, .custom:
        return linearChartValuesProvider.prepareValues(for: days, until: today)
      }
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
      case labelTapped
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

    case selectableList(PresentationAction<SelectableListViewFeature.Action>)

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
      case .view(let viewAction):
        return handleViewAction(viewAction, state: &state)
      case .internal(let internalAction):
        return handleInternalAction(internalAction, state: &state)
      case .selectableList(let action):
        return (handleSelectableListAction(action, state: &state))
      case .binding(\.selectedFilterPeriod):
        state.isSwitcherDismissed = state.selectedFilterPeriod == .custom
        let range = prepareDateRange(for: state.selectedFilterPeriod, shiftPeriod: state.periodShift)
        state.filterDate = FilterDate(filter: state.selectedFilterPeriod, lowerBound: range.lowerBound, upperBound: range.upperBound)
        return .run { send in
          await send(.internal(.loadDays))
        }
      case .binding(\.startDate):
        state.filterDate = state.filterDate?.setStartDate(state.startDate)
        return .run { send in
          await send(.internal(.loadDays))
        }
      case .binding(\.endDate):
        state.filterDate = state.filterDate?.setEndDate(state.endDate)
        return .run { send in
          await send(.internal(.loadDays))
        }
      case .binding:
        return .none
      }
    }
    .ifLet(\.$selectableList, action: \.selectableList) {
      SelectableListViewFeature()
    }
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Private

  private func handleViewAction(_ action: Action.ViewAction, state: inout State) -> Effect<Action> {
    switch action {
    case .appeared:
      state.filterDate = FilterDate(filter: state.selectedFilterPeriod, lowerBound: today, upperBound: nil)
      return .run { send in
        let tags = try await tagRepository.loadTags([])
        await send(.internal(.tagsLoaded(tags)))
        await send(.internal(.loadDays))
      }
    case .decreaseButtonTapped:
      state.periodShift -= 1
      let range = prepareDateRange(for: state.selectedFilterPeriod, shiftPeriod: state.periodShift)
      state.filterDate = FilterDate(filter: state.selectedFilterPeriod, lowerBound: range.lowerBound, upperBound: range.upperBound)
      return .run { send in
        await send(.internal(.loadDays))
      }
    case .increaseButtonTapped:
      state.periodShift += 1
      let range = prepareDateRange(for: state.selectedFilterPeriod, shiftPeriod: state.periodShift)
      state.filterDate = FilterDate(filter: state.selectedFilterPeriod, lowerBound: range.lowerBound, upperBound: range.upperBound)
      return .run { send in
        await send(.internal(.loadDays))
      }
    case .tagTapped:
      guard let selectedTag = state.selectedTag else { return .none }
      let availableTags = state.allTags.filter { tag in
        state.days.contains(where: { $0.activities.contains(where: { $0.tags.contains(tag) }) })
      }
      state.selectableList = SelectableListViewFeature.State(
        title: String(localized: "Tags", bundle: .module),
        selectedItem: selectedTag.item,
        items: availableTags.items,
        listId: ListId.tag.rawValue,
        isClearVisible: false
      )
      return .none
    case .labelTapped:
      let availableLabels = state.selectedActivity?.labels ?? []
      state.selectableList = SelectableListViewFeature.State(
        title: String(localized: "Labels", bundle: .module),
        selectedItem: state.selectedLabel?.item,
        items: availableLabels.items,
        listId: ListId.label.rawValue,
        isClearVisible: true
      )
      return .none
    case .selectActivityButtonTapped:
      state.selectableList = SelectableListViewFeature.State(
        title: String(localized: "Activities", bundle: .module),
        selectedItem: state.selectedActivity?.item,
        items: state.activities.items,
        listId: ListId.activity.rawValue,
        isClearVisible: true
      )
      return .none
    }
  }

  private func handleInternalAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .tagsLoaded(let tags):
      state.allTags = tags.sorted(by: { $0.name < $1.name })
      state.selectedTag = state.allTags.first
      return .none
    case .loadDays:
      guard let filterDate = state.filterDate else { return .none }
      return .run { [dateRange = filterDate.range] send in
        let days = try await dayProvider.days(dateRange)
        await send(.internal(.daysLoaded(days)))
      }
    case .daysLoaded(let days):
      state.days = days.sorted(by: { $0.date < $1.date })
      let activities = state.days.map { day in
        day.activities.compactMap { dayActivity -> Activity? in
          guard dayActivity.tags.contains(where: { $0 == state.selectedTag }) else { return nil }
          return dayActivity.activity
        }
      }
      .joined()
      state.activities = Array(Set(activities))
        .sorted(by: { $0.name < $1.name })
      state.selectedActivity = nil

      setupSectionsAndSelectedTag(&state, days: days)

      return .run { send in
        await send(.internal(.loadSummary))
        await send(.internal(.loadReportDays))
      }
    case .loadSummary:
      let reportSummaryProvider = ReportSummaryProvider()
      state.summary = reportSummaryProvider.prepareSummary(
        days: state.days,
        selectedActivity: state.selectedActivity,
        selectedTag: state.selectedTag,
        selectedLabel: state.selectedLabel,
        today: today
      )
      return .none
    case .loadReportDays:
      let reportDaysProvider = ReportDaysProvider()
      state.reportDays = reportDaysProvider.prepareReportDays(
        selectedFilterPeriod: state.selectedFilterPeriod,
        selectedActivity: state.selectedActivity,
        selectedLabel: state.selectedLabel,
        selectedTag: state.selectedTag,
        days: state.days
      )
      return .none
    }
  }

  private func handleSelectableListAction(_ action: PresentationAction<SelectableListViewFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.selected(let item, let listId))):
      guard let listId = ListId(rawValue: listId) else { return .none }
      switch listId {
      case .tag:
        guard let tag = state.allTags.first(where: { $0.id == item?.id }) else { return .none }
        state.selectedTag = tag
        state.selectedActivity = nil
        state.selectedLabel = nil
        let activities = state.days.map { day in
          day.activities.compactMap { dayActivity -> Activity? in
            guard dayActivity.tags.contains(where: { $0 == state.selectedTag }) else { return nil }
            return dayActivity.activity
          }
        }
          .joined()
        state.activities = Array(Set(activities)).sorted(by: { $0.name < $1.name })
      case .activity:
        state.selectedActivity = state.activities.first(where: { $0.id.uuidString == item?.id })
        state.selectedLabel = nil
      case .label:
        state.selectedLabel = state.selectedActivity?.labels.first(where: { $0.id == item?.id })
      }
      return .run { send in
        await send(.internal(.loadSummary))
        await send(.internal(.loadReportDays))
      }
    case .presented, .dismiss:
      return .none
    }
  }

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
}
