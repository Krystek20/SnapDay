import Foundation
import ComposableArchitecture
import Utilities
import SelectableList
import Models
import struct UiComponents.ReportDaysSection
import struct UiComponents.ReportDaysProvider

@Reducer
public struct ActivityDetailsFeature: TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.dayUpdater) private var dayUpdater

  // MARK: - State & Action

  enum ListId: String {
    case activities
    case tags
    case labels
    case tagActivities
  }

  @ObservableState
  public struct State: Equatable {

    var title: String { reportType.title }
    var periods = Period.allCases.filter { $0 != .day }
    var selectedPeriod: Period
    var periodShift = Int.zero
    var periodRange: ClosedRange<Date>?
    var switcherTitle: String = ""
    var reportDaysSections: [ReportDaysSection] = []

    var showStatisticsView: Bool {
      summary.doneCount > .zero || summary.notDoneCount > .zero || summary.duration > .zero
    }
    var summary: ReportSummary = .zero

    var showHeaderDivider: Bool {
      (selectedPeriod == .week || selectedPeriod == .month) && reportFilter != .empty
    }
    var reportFilter = ReportFilter.empty

    @Presents var selectableList: SelectableListViewFeature.State?

    var reportType: ReportType
    var days: [Day] = []

    public init(
      reportType: ReportType,
      period: Period
    ) {
      self.reportType = reportType
      self.selectedPeriod = period
    }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case decreaseButtonTapped
      case increaseButtonTapped
      case navigationTitleTapped
      case labelTapped
      case activityTapped
    }
    public enum InternalAction: Equatable {
      case updateFilterDate
      case loadDays
      case setDays([Day])
      case loadSummary
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
      case .view(let action):
        handleViewAction(action, state: &state)
      case .internal(let action):
        handleInternalAction(action, state: &state)
      case .delegate:
        .none
      case .selectableList(let action):
        handleSelectableListAction(action, state: &state)
      case .binding(\.selectedPeriod):
        .merge(
          .send(.internal(.updateFilterDate)),
          .concatenate(
            .send(.internal(.loadDays)),
            .send(.internal(.loadSummary))
          )
        )
      case .binding:
        .none
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
      return .send(.internal(.updateFilterDate))
    case .decreaseButtonTapped:
      state.periodShift -= 1
      return .send(.internal(.updateFilterDate))
    case .increaseButtonTapped:
      state.periodShift += 1
      return .send(.internal(.updateFilterDate))
    case .navigationTitleTapped:
      switch state.reportType {
      case .activity(let activity, let activities, _):
        state.selectableList = SelectableListViewFeature.State(
          title: String(localized: "Activities", bundle: .module),
          selectedItem: activity.item,
          items: activities.items,
          listId: ListId.activities.rawValue,
          isClearVisible: false
        )
      case .tag(let tag, let tags, _):
        state.selectableList = SelectableListViewFeature.State(
          title: String(localized: "Tags", bundle: .module),
          selectedItem: tag.item,
          items: tags.items,
          listId: ListId.tags.rawValue,
          isClearVisible: false
        )
      }
      return .none
    case .labelTapped:
      guard case .activity(let activity, _, let selectedLabel) = state.reportType else { return .none }
      state.selectableList = SelectableListViewFeature.State(
        title: String(localized: "Labels", bundle: .module),
        selectedItem: selectedLabel?.item,
        items: activity.labels.items,
        listId: ListId.labels.rawValue,
        isClearVisible: true
      )
      return .none
    case .activityTapped:
      guard case .tag(let tag, _, let selectedActivity) = state.reportType else { return .none }
      state.selectableList = SelectableListViewFeature.State(
        title: String(localized: "Activities", bundle: .module),
        selectedItem: selectedActivity?.item,
        items: activities(filteredBy: tag, state: state).items,
        listId: ListId.tagActivities.rawValue,
        isClearVisible: true
      )
      return .none
    }
  }

  private func handleInternalAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .updateFilterDate:
      let periodDateRangeCreator = PeriodDateRangeCreator()
      let periodTitleProvider = PeriodTitleProvider()
      state.periodRange = periodDateRangeCreator.prepareClosedRange(
        for: state.selectedPeriod,
        periodShift: state.periodShift
      )
      if let range = state.periodRange {
        state.switcherTitle = periodTitleProvider.title(
          for: state.selectedPeriod,
          range: range
        ) ?? ""
      }
      return .send(.internal(.loadDays))
    case .loadDays:
      guard let periodRange = state.periodRange else { return .none }
      return .run { [periodRange] send in
        let days = try await dayUpdater.days(for: periodRange)
        await send(.internal(.setDays(days)))
      }
    case .setDays(let days):
      state.days = days.sorted(by: { $0.date < $1.date })
      return .send(.internal(.loadSummary))
    case .loadSummary:
      let reportDaysProvider = ReportDaysProvider()
      state.reportDaysSections = reportDaysProvider.prepareReportDays(
        period: state.selectedPeriod,
        reportType: state.reportType,
        days: state.days
      )

      let reportSummaryProvider = ReportSummaryProvider()
      state.summary = reportSummaryProvider.prepareSummary(
        days: state.days,
        reportType: state.reportType,
        today: today
      )

      switch state.reportType {
      case .activity(let activity, _, let activityLabel):
        state.reportFilter = activity.labels.isEmpty ? .empty : .activityLabel(activityLabel)
      case .tag(let tag, _, let activity):
        state.reportFilter = activities(filteredBy: tag, state: state).isEmpty ? .empty : .activity(activity)
      }

      return .none
    }
  }

  private func handleSelectableListAction(_ action: PresentationAction<SelectableListViewFeature.Action>, state: inout State) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.selected(let item, let listId))):
      guard let listId = ListId(rawValue: listId) else { return .none }
      switch listId {
      case .activities:
        guard case .activity(_, let activities, _) = state.reportType,
              let activity = activities.first(where: { $0.id.uuidString == item?.id }) else { return .none }
        state.reportType = .activity(activity, activities, nil)
      case .tags:
        guard case .tag(_, let tags, _) = state.reportType,
              let tag = tags.first(where: { $0.id == item?.id }) else { return .none }
        state.reportType = .tag(tag, tags, nil)
      case .labels:
        guard case .activity(let activity, let activities, _) = state.reportType else { return .none }
        state.reportType = .activity(activity, activities, activity.labels.first(where: { $0.id == item?.id }))
      case .tagActivities:
        guard case .tag(let tag, let tags, _) = state.reportType else { return .none }
        state.reportType = .tag(tag, tags, activities(filteredBy: tag, state: state).first(where: { $0.id.uuidString == item?.id }))
      }
      return .send(.internal(.loadSummary))
    case .presented, .dismiss:
      return .none
    }
  }

  private func activities(filteredBy tag: Tag, state: State) -> [Activity] {
    state.days.map(\.activities).joined().reduce(into: [Activity](), { result, dayActivity in
      guard let activity = dayActivity.activity, !result.contains(where: { $0.id == activity.id }) && activity.tags.contains(tag) else { return }
      result.append(activity)
    })
  }
}
