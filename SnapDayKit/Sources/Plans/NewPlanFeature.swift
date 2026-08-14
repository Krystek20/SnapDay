import ActivityList
import ComposableArchitecture
import Foundation
import Models
import Utilities

@Reducer
public struct NewPlanFeature {

  @Dependency(\.calendar) private var calendar
  @Dependency(\.date.now) private var now
  @Dependency(\.uuid) private var uuid

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    var step: NewPlanStep
    var name: String
    var selectedDuration: PlanDuration
    var startDate: Date
    var endDate: Date
    var schedule: [ScheduledPlanDay]
    var editingPlan: Plan?
    var isStartDateEditable: Bool
    var isNameValidationErrorPresented: Bool
    var isScheduleValidationErrorPresented: Bool
    var delegatesStepChanges: Bool
    var isSubmitting: Bool

    var activityPickerDay: PlanWeekday?
    @Presents var activityPicker: ActivityListFeature.State?
    var applySourceDay: PlanWeekday?
    var applyTargetDays: Set<PlanWeekday>
    var replacementTargetDays: Set<PlanWeekday>
    var scheduleRemovalWeekdays: [PlanWeekday]

    var canContinue: Bool {
      !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canReview: Bool {
      schedule.contains { !$0.activities.isEmpty }
    }

    var needsReplacementConfirmation: Bool {
      !replacementTargetDays.isEmpty
    }

    var needsScheduleRemovalConfirmation: Bool {
      !scheduleRemovalWeekdays.isEmpty
    }

    init(
      step: NewPlanStep = .details,
      name: String = "",
      selectedDuration: PlanDuration = .oneMonth,
      startDate: Date = .now,
      endDate: Date? = nil,
      schedule: [ScheduledPlanDay] = [],
      editingPlan: Plan? = nil,
      isStartDateEditable: Bool = true,
      isNameValidationErrorPresented: Bool = false,
      isScheduleValidationErrorPresented: Bool = false,
      scheduleRemovalWeekdays: [PlanWeekday] = [],
      delegatesStepChanges: Bool = false,
      isSubmitting: Bool = false
    ) {
      self.step = step
      self.name = name
      self.selectedDuration = selectedDuration
      self.startDate = startDate
      self.endDate = endDate ?? selectedDuration.endDate(from: startDate)
      self.schedule = schedule
      self.editingPlan = editingPlan
      self.isStartDateEditable = isStartDateEditable
      self.isNameValidationErrorPresented = isNameValidationErrorPresented
      self.isScheduleValidationErrorPresented = isScheduleValidationErrorPresented
      self.delegatesStepChanges = delegatesStepChanges
      self.isSubmitting = isSubmitting
      self.activityPickerDay = nil
      self.activityPicker = nil
      self.applySourceDay = nil
      self.applyTargetDays = []
      self.replacementTargetDays = []
      self.scheduleRemovalWeekdays = scheduleRemovalWeekdays
    }

    public init(
      onboardingName name: String,
      startDate: Date,
      suggestedActivity: Activity?,
      scheduledWeekdays: Set<PlanWeekday>,
      calendar: Calendar
    ) {
      let duration = PlanDuration.oneMonth
      let endDate = duration.endDate(from: startDate, calendar: calendar)
      let schedule = NewPlanFeature.makeSchedule(
        from: startDate,
        through: endDate,
        preserving: [],
        calendar: calendar
      ).map { day in
        guard let suggestedActivity, scheduledWeekdays.contains(day.weekday) else {
          return day
        }
        return ScheduledPlanDay(
          weekday: day.weekday,
          activities: [suggestedActivity]
        )
      }
      self.init(
        name: name,
        selectedDuration: duration,
        startDate: startDate,
        endDate: endDate,
        schedule: schedule,
        delegatesStepChanges: true
      )
    }

    init(
      plan: Plan,
      activities: [Activity],
      now: Date,
      calendar: Calendar
    ) {
      let activitiesByID = PlanActivityResolver.activitiesByID(activities)
      let scheduledDays = Dictionary(grouping: plan.schedule, by: \.weekday).mapValues { entries in
        entries.sorted { $0.position < $1.position }.compactMap { activitiesByID[$0.activityID] }
      }
      self.init(
        name: plan.name,
        selectedDuration: plan.duration,
        startDate: plan.startDate,
        endDate: plan.endDate,
        schedule: NewPlanFeature.makeSchedule(
          from: plan.startDate,
          through: plan.endDate,
          preserving: scheduledDays.map { ScheduledPlanDay(weekday: $0.key, activities: $0.value) },
          calendar: calendar
        ),
        editingPlan: plan,
        isStartDateEditable: calendar.startOfDay(for: now) < calendar.startOfDay(for: plan.startDate)
      )
    }

    init(
      copying plan: Plan,
      activities: [Activity],
      startDate: Date,
      calendar: Calendar
    ) {
      let activitiesByID = PlanActivityResolver.activitiesByID(activities)
      let scheduledDays = Dictionary(grouping: plan.schedule, by: \.weekday).mapValues { entries in
        entries.sorted { $0.position < $1.position }.compactMap { activitiesByID[$0.activityID] }
      }
      let normalizedStartDate = calendar.startOfDay(for: startDate)
      let copiedEndDate: Date
      if plan.duration == .custom {
        let dayCount = max(
          0,
          calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: plan.startDate),
            to: calendar.startOfDay(for: plan.endDate)
          ).day ?? 0
        )
        copiedEndDate = calendar.date(
          byAdding: .day,
          value: dayCount,
          to: normalizedStartDate
        ) ?? normalizedStartDate
      } else {
        copiedEndDate = plan.duration.endDate(from: normalizedStartDate, calendar: calendar)
      }

      self.init(
        name: plan.name,
        selectedDuration: plan.duration,
        startDate: normalizedStartDate,
        endDate: copiedEndDate,
        schedule: NewPlanFeature.makeSchedule(
          from: normalizedStartDate,
          through: copiedEndDate,
          preserving: scheduledDays.map { ScheduledPlanDay(weekday: $0.key, activities: $0.value) },
          calendar: calendar
        )
      )
    }

    var isEditing: Bool {
      editingPlan != nil
    }
  }

  public enum Action: BindableAction, Equatable {

    public enum ViewAction: Equatable {
      case cancelButtonTapped
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
      case scheduleRemovalCancelled
      case scheduleRemovalConfirmed
      case startPlanButtonTapped
    }

    public enum DelegateAction: Equatable {
      case cancelTapped
      case planCreated(NewPlanDraft)
      case planUpdated(Plan)
      case stepChanged(NewPlanStep)
    }

    case binding(BindingAction<State>)
    case activityPicker(PresentationAction<ActivityListFeature.Action>)
    case delegate(DelegateAction)
    case submissionFailed
    case view(ViewAction)
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(\.name):
        if state.canContinue {
          state.isNameValidationErrorPresented = false
        }
        return .none

      case .binding(\.startDate):
        guard state.isStartDateEditable else {
          state.startDate = state.editingPlan?.startDate ?? state.startDate
          return .none
        }
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
        if state.canReview {
          state.isScheduleValidationErrorPresented = false
        }
        state.activityPickerDay = nil
        state.activityPicker = nil
        return .none

      case .activityPicker:
        return .none

      case .view(.cancelButtonTapped):
        return .send(.delegate(.cancelTapped))

      case .view(.continueButtonTapped):
        switch state.step {
        case .details:
          guard state.canContinue else {
            state.isNameValidationErrorPresented = true
            return .none
          }
          let updatedSchedule = Self.makeSchedule(
            from: state.startDate,
            through: state.endDate,
            preserving: state.schedule,
            calendar: calendar
          )
          state.scheduleRemovalWeekdays = Self.assignedWeekdaysRemoved(
            from: state.schedule,
            by: updatedSchedule
          )
          guard state.scheduleRemovalWeekdays.isEmpty else { return .none }
          Self.applySchedule(updatedSchedule, to: &state)
        case .weeklySchedule:
          guard state.canReview else {
            state.isScheduleValidationErrorPresented = true
            return .none
          }
          state.step = .review
        case .review:
          break
        }
        return stepChangeEffect(for: state)

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
        guard state.schedule.contains(where: { $0.weekday == weekday }) else {
          return .none
        }
        state.activityPickerDay = weekday
        let selectedActivityIDs = Set(
          state.schedule
            .first(where: { $0.weekday == weekday })?
            .activities
            .map(\.id) ?? []
        )
        state.activityPicker = ActivityListFeature.State(
          selectedActivityIDs: selectedActivityIDs,
          title: Self.activityPickerTitle(for: weekday)
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
        guard weekday != state.applySourceDay,
              state.schedule.contains(where: { $0.weekday == weekday })
        else { return .none }
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

      case .view(.scheduleRemovalCancelled):
        state.scheduleRemovalWeekdays = []
        return .none

      case .view(.scheduleRemovalConfirmed):
        let updatedSchedule = Self.makeSchedule(
          from: state.startDate,
          through: state.endDate,
          preserving: state.schedule,
          calendar: calendar
        )
        Self.applySchedule(updatedSchedule, to: &state)
        return stepChangeEffect(for: state)

      case .view(.startPlanButtonTapped):
        guard !state.isSubmitting else { return .none }
        guard state.step == .review else { return .none }
        guard state.canContinue else {
          state.isNameValidationErrorPresented = true
          state.step = .details
          return stepChangeEffect(for: state)
        }
        guard state.canReview else {
          state.isScheduleValidationErrorPresented = true
          state.step = .weeklySchedule
          return stepChangeEffect(for: state)
        }
        let draft = NewPlanDraft(
          name: state.name.trimmingCharacters(in: .whitespacesAndNewlines),
          duration: state.selectedDuration,
          startDate: state.startDate,
          endDate: state.endDate,
          schedule: state.schedule
        )
        if let editingPlan = state.editingPlan {
          return .send(.delegate(.planUpdated(draft.updating(editingPlan, scheduleEntryID: { uuid() }))))
        }
        if state.delegatesStepChanges {
          state.isSubmitting = true
        }
        return .send(.delegate(.planCreated(draft)))

      case .submissionFailed:
        state.isSubmitting = false
        return .none

      }
    }
    .ifLet(\.$activityPicker, action: \.activityPicker) {
      ActivityListFeature()
    }
  }

  // MARK: - Private

  private func stepChangeEffect(for state: State) -> Effect<Action> {
    guard state.delegatesStepChanges else { return .none }
    return .send(.delegate(.stepChanged(state.step)))
  }

  private static func makeSchedule(
    from startDate: Date,
    through endDate: Date,
    preserving schedule: [ScheduledPlanDay],
    calendar: Calendar
  ) -> [ScheduledPlanDay] {
    let start = calendar.startOfDay(for: startDate)
    let end = calendar.startOfDay(for: max(startDate, endDate))
    var includedWeekdays = Set<PlanWeekday>()
    var orderedWeekdays: [PlanWeekday] = []
    var date = start

    while date <= end, includedWeekdays.count < PlanWeekday.allCases.count {
      if let weekday = PlanWeekday(rawValue: calendar.component(.weekday, from: date)),
         includedWeekdays.insert(weekday).inserted {
        orderedWeekdays.append(weekday)
      }
      guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
      date = nextDate
    }

    return orderedWeekdays.map { weekday in
      schedule.first(where: { $0.weekday == weekday })
        ?? ScheduledPlanDay(weekday: weekday)
    }
  }

  private static func assignedWeekdaysRemoved(
    from currentSchedule: [ScheduledPlanDay],
    by updatedSchedule: [ScheduledPlanDay]
  ) -> [PlanWeekday] {
    let availableWeekdays = Set(updatedSchedule.map(\.weekday))
    return currentSchedule.compactMap { day in
      guard !day.activities.isEmpty, !availableWeekdays.contains(day.weekday) else {
        return nil
      }
      return day.weekday
    }
  }

  static func activityPickerTitle(for weekday: PlanWeekday) -> String {
    String(localized: "Add to \(weekday.title)", bundle: .module)
  }

  private static func applySchedule(
    _ schedule: [ScheduledPlanDay],
    to state: inout State
  ) {
    state.schedule = schedule
    state.scheduleRemovalWeekdays = []
    clearApplyState(&state)
    state.step = .weeklySchedule
  }

  private static func applyActivities(_ state: inout State) {
    guard
      let sourceDay = state.applySourceDay,
      let sourceActivities = state.schedule.first(where: { $0.weekday == sourceDay })?.activities
    else { return }

    for index in state.schedule.indices where state.applyTargetDays.contains(state.schedule[index].weekday) {
      state.schedule[index].activities = sourceActivities
    }
    if state.canReview {
      state.isScheduleValidationErrorPresented = false
    }
    clearApplyState(&state)
  }

  private static func clearApplyState(_ state: inout State) {
    state.applySourceDay = nil
    state.applyTargetDays = []
    state.replacementTargetDays = []
  }
}
