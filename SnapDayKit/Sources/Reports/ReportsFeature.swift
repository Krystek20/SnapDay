import Foundation
import ComposableArchitecture
import Repositories
import Utilities
import Models
import Common
import Combine
import struct UiComponents.PeriodSummaryData
import struct UiComponents.PeriodSummaryProvider

@Reducer
public struct ReportsFeature: TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.tagRepository) private var tagRepository
  @Dependency(\.activityRepository) private var activityRepository
  @Dependency(\.dayUpdater) private var dayUpdater

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable, TodayProvidable {

    var periods = Period.allCases.filter { $0 != .day }
    var selectedPeriod: Period
    var periodShift = Int.zero
    var periodRange: ClosedRange<Date>?
    var switcherTitle: String = ""

    var periodSummaryData: PeriodSummaryData?
    var linearChartValues: LinearChartValues?
    var timePeriodTags: [TimePeriodActivity] = []
    var timePeriodActivities: [TimePeriodActivity] = []

    var days: [Day] = []
    var activities: [Activity] = []
    var tags: [Tag] = []

    public init(selectedFilterDate: Period = .week) {
      self.selectedPeriod = selectedFilterDate
    }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case decreaseButtonTapped
      case increaseButtonTapped
      case tagTapped(TimePeriodActivity)
      case activityTapped(TimePeriodActivity)
    }
    public enum InternalAction: Equatable {
      case loadDays
      case setDays([Day])
      case setActivities([Activity])
      case setTags([Tag])
      case loadSummary
      case updateFilterDate
    }
    public enum DelegateAction: Equatable {
      case activityTapped(Activity, [Activity], Period)
      case tagTapped(Tag, [Tag], Period)
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
      case .view(let viewAction):
        return handleViewAction(viewAction, state: &state)
      case .internal(let internalAction):
        return handleInternalAction(internalAction, state: &state)
      case .binding(\.selectedPeriod):
        return .send(.internal(.updateFilterDate))
      case .binding:
        return .none
      case .delegate:
        return .none
      }
    }
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Private

  private func handleViewAction(_ action: Action.ViewAction, state: inout State) -> Effect<Action> {
    switch action {
    case .appeared:
      return .run { send in
        await send(.internal(.updateFilterDate))

        let tags = try await tagRepository.loadTags([])
        await send(.internal(.setTags(tags)))

        let activities = try await activityRepository.loadActivities()
        await send(.internal(.setActivities(activities)))
      }
    case .decreaseButtonTapped:
      state.periodShift -= 1
      return .send(.internal(.updateFilterDate))
    case .increaseButtonTapped:
      state.periodShift += 1
      return .send(.internal(.updateFilterDate))
    case .tagTapped(let timePeriodActivity):
      guard let tag = state.tags.first(where: { $0.id == timePeriodActivity.id }) else { return .none }
      return .send(.delegate(.tagTapped(tag, state.tags, state.selectedPeriod)))
    case .activityTapped(let timePeriodActivity):
      guard let activity = state.activities.first(where: { $0.id.uuidString == timePeriodActivity.id }) else { return .none }
      return .send(.delegate(.activityTapped(activity, state.activities, state.selectedPeriod)))
    }
  }

  private func handleInternalAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .setActivities(let activities):
      state.activities = activities
      return .none
    case .setTags(let tags):
      state.tags = tags.sorted(by: { $0.name < $1.name })
      return .none
    case .loadDays:
      guard let periodRange = state.periodRange else { return .none }
      return .run { [periodRange] send in
        let days = try await dayUpdater.days(for: periodRange)
        await send(.internal(.setDays(days)))
        await send(.internal(.loadSummary))
      }
    case .setDays(let days):
      state.days = days.sorted(by: { $0.date < $1.date })
      return .none
    case .loadSummary:
      let provider = PeriodSummaryProvider()
      state.periodSummaryData = provider.preparePeriodSummary(from: state.days, to: state.selectedPeriod.unit)

      let linearChartValuesProvider = LinearChartValuesProvider()
      state.linearChartValues = linearChartValuesProvider.prepareValues(for: state.days, until: today)

      let days = state.days

      state.timePeriodTags = state.tags.compactMap { tag in
        let (totalCount, doneCount, duration) = days.reduce(into: (totalCount: 0, doneCount: 0, duration: 0)) { result, day in
          let dayActivities = day.activities.filter { $0.activity?.tags.contains(tag) == true }
          result.totalCount += dayActivities.count
          result.doneCount += dayActivities.filter(\.isDone).count
          result.duration += dayActivities.filter(\.isDone).reduce(0) { $0 + $1.duration }
        }

        guard totalCount > .zero else { return nil }

        return TimePeriodActivity(
          id: tag.id,
          name: tag.name,
          type: .color(tag.rgbColor),
          totalCount: totalCount,
          doneCount: doneCount,
          duration: duration,
          showProgress: false,
          isImportant: false
        )
      }
      .sortedByPriority()

      state.timePeriodActivities = state.activities.compactMap { activity in
        let (totalCount, doneCount, duration) = days.reduce(into: (totalCount: 0, doneCount: 0, duration: 0)) { result, day in
          let dayActivities = day.activities.filter { $0.activity?.id == activity.id }
          result.totalCount += dayActivities.count
          result.doneCount += dayActivities.filter(\.isDone).count
          result.duration += dayActivities.filter(\.isDone).reduce(0) { $0 + $1.duration }
        }

        guard totalCount > .zero else { return nil }

        return TimePeriodActivity(
          id: activity.id.uuidString,
          name: activity.name,
          type: .icon(activity.iconId),
          totalCount: totalCount,
          doneCount: doneCount,
          duration: duration,
          showProgress: activity.isFrequentEnabled,
          isImportant: activity.important
        )
      }
      .sortedByPriority()

      return .none
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
    }
  }
}
