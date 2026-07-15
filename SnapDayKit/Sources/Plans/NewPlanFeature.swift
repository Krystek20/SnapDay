import ActivityList
import ComposableArchitecture
import Foundation
import Models

@Reducer
public struct NewPlanFeature {

  @Dependency(\.calendar) private var calendar
  @Dependency(\.date.now) private var now

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    var step: NewPlanStep
    var name: String
    var selectedDuration: PlanDuration
    var startDate: Date
    var endDate: Date
    var schedule: [ScheduledPlanDay]

    var activityPickerDay: PlanWeekday?
    @Presents var activityPicker: ActivityListFeature.State?
    var applySourceDay: PlanWeekday?
    var applyTargetDays: Set<PlanWeekday>
    var replacementTargetDays: Set<PlanWeekday>

    var canContinue: Bool {
      !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canReview: Bool {
      schedule.contains { !$0.activities.isEmpty }
    }

    var needsReplacementConfirmation: Bool {
      !replacementTargetDays.isEmpty
    }

    init(
      step: NewPlanStep = .details,
      name: String = "",
      selectedDuration: PlanDuration = .oneMonth,
      startDate: Date = .now,
      endDate: Date? = nil,
      schedule: [ScheduledPlanDay] = []
    ) {
      self.step = step
      self.name = name
      self.selectedDuration = selectedDuration
      self.startDate = startDate
      self.endDate = endDate ?? selectedDuration.endDate(from: startDate)
      self.schedule = schedule
      self.activityPickerDay = nil
      self.activityPicker = nil
      self.applySourceDay = nil
      self.applyTargetDays = []
      self.replacementTargetDays = []
    }
  }

  public enum Action: BindableAction, Equatable {

    public enum ViewAction: Equatable {
      case cancelButtonTapped
      case backButtonTapped
      case continueButtonTapped
      case navigationPathChanged([NewPlanStep])
      case durationTapped(PlanDuration)
      case addActivityTapped(PlanWeekday)
      case applyToDaysTapped(PlanWeekday)
      case applyTargetTapped(PlanWeekday)
      case applyCancelled
      case applyConfirmed
      case replacementCancelled
      case replacementConfirmed
      case startPlanButtonTapped
    }

    public enum DelegateAction: Equatable {
      case cancelTapped
      case planCreated(NewPlanDraft)
    }

    case binding(BindingAction<State>)
    case activityPicker(PresentationAction<ActivityListFeature.Action>)
    case delegate(DelegateAction)
    case view(ViewAction)
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(\.startDate):
        state.startDate = max(
          calendar.startOfDay(for: state.startDate),
          calendar.startOfDay(for: now)
        )
        if state.selectedDuration == .custom {
          state.endDate = max(state.endDate, state.startDate)
        } else {
          state.endDate = state.selectedDuration.endDate(from: state.startDate)
        }
        return .none

      case .binding(\.endDate):
        state.endDate = max(state.endDate, state.startDate)
        state.selectedDuration = .custom
        return .none

      case .binding:
        return .none

      case .delegate:
        return .none

      case .activityPicker(.dismiss):
        state.activityPickerDay = nil
        return .none

      case .activityPicker(.presented(.delegate(.selectionConfirmed(let activities)))):
        guard let weekday = state.activityPickerDay,
              let index = state.schedule.firstIndex(where: { $0.weekday == weekday })
        else { return .none }
        state.schedule[index].activities = activities
        state.activityPickerDay = nil
        state.activityPicker = nil
        return .none

      case .activityPicker:
        return .none

      case .view(.cancelButtonTapped):
        return .send(.delegate(.cancelTapped))

      case .view(.backButtonTapped):
        switch state.step {
        case .details:
          return .send(.delegate(.cancelTapped))
        case .weeklySchedule:
          state.step = .details
        case .review:
          state.step = .weeklySchedule
        }
        return .none

      case .view(.continueButtonTapped):
        switch state.step {
        case .details:
          guard state.canContinue else { return .none }
          state.schedule = Self.makeSchedule(
            from: state.startDate,
            through: state.endDate,
            preserving: state.schedule,
            calendar: calendar
          )
          state.step = .weeklySchedule
        case .weeklySchedule:
          guard state.canReview else { return .none }
          state.step = .review
        case .review:
          break
        }
        return .none

      case .view(.navigationPathChanged(let path)):
        switch path {
        case []:
          state.step = .details
        case [.weeklySchedule]:
          state.step = .weeklySchedule
        case [.weeklySchedule, .review]:
          state.step = .review
        default:
          break
        }
        return .none

      case .view(.durationTapped(let duration)):
        state.selectedDuration = duration
        if duration != .custom {
          state.endDate = duration.endDate(from: state.startDate)
        }
        return .none

      case .view(.addActivityTapped(let weekday)):
        state.activityPickerDay = weekday
        let selectedActivityIDs = Set(
          state.schedule
            .first(where: { $0.weekday == weekday })?
            .activities
            .map(\.id) ?? []
        )
        state.activityPicker = ActivityListFeature.State(
          selectedActivityIDs: selectedActivityIDs,
          title: String(
            localized: "Add to \(weekday.title)",
            bundle: .module
          )
        )
        return .none

      case .view(.applyToDaysTapped(let weekday)):
        guard state.schedule.first(where: { $0.weekday == weekday })?.activities.isEmpty == false else {
          return .none
        }
        state.applySourceDay = weekday
        state.applyTargetDays = []
        state.replacementTargetDays = []
        return .none

      case .view(.applyTargetTapped(let weekday)):
        if state.applyTargetDays.contains(weekday) {
          state.applyTargetDays.remove(weekday)
        } else {
          state.applyTargetDays.insert(weekday)
        }
        return .none

      case .view(.applyCancelled):
        Self.clearApplyState(&state)
        return .none

      case .view(.applyConfirmed):
        guard !state.applyTargetDays.isEmpty else { return .none }
        state.replacementTargetDays = Set(
          state.schedule
            .filter {
              state.applyTargetDays.contains($0.weekday) && !$0.activities.isEmpty
            }
            .map(\.weekday)
        )
        guard state.replacementTargetDays.isEmpty else { return .none }
        Self.applyActivities(&state)
        return .none

      case .view(.replacementCancelled):
        state.replacementTargetDays = []
        return .none

      case .view(.replacementConfirmed):
        Self.applyActivities(&state)
        return .none

      case .view(.startPlanButtonTapped):
        guard state.step == .review, state.canReview else { return .none }
        return .send(
          .delegate(
            .planCreated(
              NewPlanDraft(
                name: state.name.trimmingCharacters(in: .whitespacesAndNewlines),
                duration: state.selectedDuration,
                startDate: state.startDate,
                endDate: state.endDate,
                schedule: state.schedule
              )
            )
          )
        )
      }
    }
    .ifLet(\.$activityPicker, action: \.activityPicker) {
      ActivityListFeature()
    }
  }

  // MARK: - Private

  private static func makeSchedule(
    from startDate: Date,
    through endDate: Date,
    preserving schedule: [ScheduledPlanDay],
    calendar: Calendar
  ) -> [ScheduledPlanDay] {
    let start = calendar.startOfDay(for: startDate)
    let end = calendar.startOfDay(for: max(startDate, endDate))
    var includedWeekdays = Set<PlanWeekday>()
    var date = start

    while date <= end, includedWeekdays.count < PlanWeekday.allCases.count {
      if let weekday = PlanWeekday(rawValue: calendar.component(.weekday, from: date)) {
        includedWeekdays.insert(weekday)
      }
      guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
      date = nextDate
    }

    return PlanWeekday.ordered(using: calendar)
      .filter(includedWeekdays.contains)
      .map { weekday in
        schedule.first(where: { $0.weekday == weekday })
          ?? ScheduledPlanDay(weekday: weekday)
      }
  }

  private static func applyActivities(_ state: inout State) {
    guard
      let sourceDay = state.applySourceDay,
      let sourceActivities = state.schedule.first(where: { $0.weekday == sourceDay })?.activities
    else { return }

    for index in state.schedule.indices where state.applyTargetDays.contains(state.schedule[index].weekday) {
      state.schedule[index].activities = sourceActivities
    }
    clearApplyState(&state)
  }

  private static func clearApplyState(_ state: inout State) {
    state.applySourceDay = nil
    state.applyTargetDays = []
    state.replacementTargetDays = []
  }
}
