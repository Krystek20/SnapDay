import ActivityList
import ComposableArchitecture
import Foundation
import Models
@testable import Repositories
import Testing
@testable import Plans

@MainActor
struct NewPlanFeatureTests {

  @Test
  func recreatingFiveDayPlanAsSevenDaysIncludesWeekendActivities() async throws {
    let calendar = testCalendar()
    let originalStartDate = try date(year: 2026, month: 7, day: 6, calendar: calendar)
    let originalEndDate = try date(year: 2026, month: 7, day: 10, calendar: calendar)
    let recreatedStartDate = try date(year: 2026, month: 7, day: 13, calendar: calendar)
    let recreatedEndDate = calendar.startOfDay(
      for: try date(year: 2026, month: 7, day: 19, calendar: calendar)
    )
    let activity = try activity(
      id: "00000000-0000-0000-0000-000000000001",
      name: "Read"
    )
    let originalPlan = Plan(
      id: try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000010")),
      name: "Reading week",
      startDate: originalStartDate,
      endDate: originalEndDate,
      duration: .custom,
      schedule: PlanWeekday.allCases
        .filter { $0 != .saturday && $0 != .sunday }
        .map {
          PlanScheduleEntry(
            id: UUID(),
            weekday: $0,
            activityID: activity.id,
            position: 0
          )
        }
    )
    let state = NewPlanFeature.State(
      copying: originalPlan,
      activities: [activity],
      startDate: recreatedStartDate,
      calendar: calendar
    )
    let store = withDependencies {
      $0.calendar = calendar
      $0.date.now = recreatedStartDate
    } operation: {
      TestStore(initialState: state, reducer: { NewPlanFeature() })
    }

    await store.send(.view(.durationTapped(.sevenDays))) {
      $0.selectedDuration = .sevenDays
      $0.endDate = recreatedEndDate
    }
    await store.send(.view(.continueButtonTapped)) {
      $0.step = .weeklySchedule
      $0.schedule.append(ScheduledPlanDay(weekday: .saturday))
      $0.schedule.append(ScheduledPlanDay(weekday: .sunday))
    }
    await store.send(.view(.applyToDaysTapped(.monday))) {
      $0.applySourceDay = .monday
    }
    await store.send(.view(.applyTargetTapped(.saturday))) {
      $0.applyTargetDays = [.saturday]
    }
    await store.send(.view(.applyTargetTapped(.sunday))) {
      $0.applyTargetDays = [.saturday, .sunday]
    }
    await store.send(.view(.applyConfirmed)) {
      $0.schedule[$0.schedule.count - 2].activities = [activity]
      $0.schedule[$0.schedule.count - 1].activities = [activity]
      $0.applySourceDay = nil
      $0.applyTargetDays = []
    }
    await store.send(.view(.continueButtonTapped)) {
      $0.step = .review
    }

    let draft = NewPlanDraft(
      name: store.state.name,
      duration: store.state.selectedDuration,
      startDate: store.state.startDate,
      endDate: store.state.endDate,
      schedule: store.state.schedule
    )
    await store.send(.view(.startPlanButtonTapped))
    await store.receive(.delegate(.planCreated(draft)))

    #expect(draft.plannedActivityCount(calendar: calendar) == 7)
    let recreatedPlan = draft.plan(id: UUID(), scheduleEntryID: UUID.init)
    #expect(recreatedPlan.schedule.count == 7)
    #expect(recreatedPlan.scheduledOccurrences(calendar: calendar).count == 7)
  }

  @Test
  func presetDurationsUseInclusiveEndDates() async throws {
    let startDate = try date(year: 2026, month: 6, day: 8)
    let sevenDayEndDate = try adding(.day, value: 6, to: startDate)
    let twoWeekEndDate = try adding(.day, value: 13, to: startDate)
    let store = TestStore(
      initialState: NewPlanFeature.State(startDate: startDate),
      reducer: { NewPlanFeature() }
    )

    await store.send(.view(.durationTapped(.sevenDays))) {
      $0.selectedDuration = .sevenDays
      $0.endDate = sevenDayEndDate
    }
    await store.send(.view(.durationTapped(.twoWeeks))) {
      $0.selectedDuration = .twoWeeks
      $0.endDate = twoWeekEndDate
    }
  }

  @Test
  func changingStartDatePreservesInclusivePresetDuration() async throws {
    let calendar = testCalendar()
    let initialStartDate = try date(year: 2026, month: 6, day: 8, calendar: calendar)
    let newStartDate = try date(year: 2026, month: 7, day: 1, calendar: calendar)
    let normalizedStartDate = calendar.startOfDay(for: newStartDate)
    let exclusiveEndDate = try adding(.month, value: 1, to: normalizedStartDate, calendar: calendar)
    let expectedEndDate = try adding(.day, value: -1, to: exclusiveEndDate, calendar: calendar)
    let store = withDependencies {
      $0.calendar = calendar
      $0.date.now = initialStartDate
    } operation: {
      TestStore(
        initialState: NewPlanFeature.State(startDate: initialStartDate),
        reducer: { NewPlanFeature() }
      )
    }

    await store.send(.binding(.set(\.startDate, newStartDate))) {
      $0.startDate = normalizedStartDate
      $0.endDate = expectedEndDate
    }
  }

  @Test
  func startDateCannotBeInThePast() async throws {
    let calendar = testCalendar()
    let today = try date(year: 2026, month: 7, day: 15, calendar: calendar)
    let normalizedToday = calendar.startOfDay(for: today)
    let pastDate = try date(year: 2025, month: 1, day: 1, calendar: calendar)
    let store = withDependencies {
      $0.calendar = calendar
      $0.date.now = today
    } operation: {
      TestStore(
        initialState: NewPlanFeature.State(startDate: today),
        reducer: { NewPlanFeature() }
      )
    }

    await store.send(.binding(.set(\.startDate, pastDate))) {
      $0.startDate = normalizedToday
      $0.endDate = PlanDuration.oneMonth.endDate(from: normalizedToday, calendar: calendar)
    }
  }

  @Test
  func changingPresetEndDateSwitchesDurationToCustom() async throws {
    let startDate = try date(year: 2026, month: 7, day: 15)
    let customEndDate = try date(year: 2026, month: 8, day: 1)
    let store = TestStore(
      initialState: NewPlanFeature.State(
        selectedDuration: .sevenDays,
        startDate: startDate
      ),
      reducer: { NewPlanFeature() }
    )

    await store.send(.binding(.set(\.endDate, customEndDate))) {
      $0.endDate = customEndDate
      $0.selectedDuration = .custom
    }
  }

  @Test
  func customEndDateCannotPrecedeStartDate() async throws {
    let startDate = try date(year: 2026, month: 6, day: 8)
    let earlierDate = try date(year: 2026, month: 6, day: 1)
    let store = TestStore(
      initialState: NewPlanFeature.State(
        selectedDuration: .custom,
        startDate: startDate
      ),
      reducer: { NewPlanFeature() }
    )

    await store.send(.binding(.set(\.endDate, earlierDate)))
    #expect(store.state.endDate == startDate)
  }

  @Test
  func weeklyScheduleIncludesEveryWeekdayAndSaturday() async throws {
    let calendar = testCalendar()
    let startDate = try date(year: 2026, month: 6, day: 8, calendar: calendar)
    let endDate = try date(year: 2026, month: 6, day: 14, calendar: calendar)
    let expectedSchedule = PlanWeekday.ordered(using: calendar).map {
      ScheduledPlanDay(weekday: $0)
    }
    let store = withDependencies {
      $0.calendar = calendar
    } operation: {
      TestStore(
        initialState: NewPlanFeature.State(
          name: "Summer routine",
          selectedDuration: .custom,
          startDate: startDate,
          endDate: endDate
        ),
        reducer: { NewPlanFeature() }
      )
    }

    await store.send(.view(.continueButtonTapped)) {
      $0.schedule = expectedSchedule
      $0.step = .weeklySchedule
    }
    #expect(store.state.schedule.contains { $0.weekday == .saturday })
  }

  @Test
  func shortRangeCrossingWeekBoundaryUsesChronologicalWeekdays() async throws {
    let calendar = testCalendar()
    let saturday = try date(year: 2026, month: 6, day: 13, calendar: calendar)
    let monday = try date(year: 2026, month: 6, day: 15, calendar: calendar)
    let expectedSchedule = [
      ScheduledPlanDay(weekday: .saturday),
      ScheduledPlanDay(weekday: .sunday),
      ScheduledPlanDay(weekday: .monday)
    ]
    let store = withDependencies {
      $0.calendar = calendar
    } operation: {
      TestStore(
        initialState: NewPlanFeature.State(
          name: "Weekend plan",
          selectedDuration: .custom,
          startDate: saturday,
          endDate: monday
        ),
        reducer: { NewPlanFeature() }
      )
    }

    await store.send(.view(.continueButtonTapped)) {
      $0.schedule = expectedSchedule
      $0.step = .weeklySchedule
    }
  }

  @Test
  func shorteningDateRangeRequiresConfirmationBeforeRemovingAssignments() async throws {
    let calendar = testCalendar()
    let monday = try date(year: 2026, month: 6, day: 8, calendar: calendar)
    let wednesday = try date(year: 2026, month: 6, day: 10, calendar: calendar)
    let sunday = try date(year: 2026, month: 6, day: 14, calendar: calendar)
    let read = try activity(id: "00000000-0000-0000-0000-000000000001", name: "Read")
    let walk = try activity(id: "00000000-0000-0000-0000-000000000002", name: "Walk")
    let originalSchedule = [
      ScheduledPlanDay(weekday: .monday, activities: [read]),
      ScheduledPlanDay(weekday: .saturday, activities: [walk])
    ]
    let store = withDependencies {
      $0.calendar = calendar
    } operation: {
      TestStore(
        initialState: NewPlanFeature.State(
          name: "Reading week",
          selectedDuration: .custom,
          startDate: monday,
          endDate: sunday,
          schedule: originalSchedule
        ),
        reducer: { NewPlanFeature() }
      )
    }

    await store.send(.binding(.set(\.endDate, wednesday))) {
      $0.endDate = wednesday
    }
    await store.send(.view(.continueButtonTapped)) {
      $0.scheduleRemovalWeekdays = [.saturday]
    }
    #expect(store.state.schedule == originalSchedule)
    #expect(store.state.step == .details)

    await store.send(.view(.scheduleRemovalCancelled)) {
      $0.scheduleRemovalWeekdays = []
    }
    #expect(store.state.schedule == originalSchedule)

    await store.send(.view(.continueButtonTapped)) {
      $0.scheduleRemovalWeekdays = [.saturday]
    }
    await store.send(.view(.scheduleRemovalConfirmed)) {
      $0.schedule = [
        ScheduledPlanDay(weekday: .monday, activities: [read]),
        ScheduledPlanDay(weekday: .tuesday),
        ScheduledPlanDay(weekday: .wednesday)
      ]
      $0.scheduleRemovalWeekdays = []
      $0.step = .weeklySchedule
    }
  }

  @Test
  func unavailableWeekdaysCannotReceiveActivities() async {
    let store = TestStore(
      initialState: NewPlanFeature.State(
        step: .weeklySchedule,
        schedule: [ScheduledPlanDay(weekday: .monday)]
      ),
      reducer: { NewPlanFeature() }
    )

    await store.send(.view(.addActivityTapped(.tuesday)))
    await store.send(.view(.applyTargetTapped(.tuesday)))
    #expect(store.state.activityPicker == nil)
    #expect(store.state.applyTargetDays.isEmpty)
  }

  @Test
  func blankNameShowsValidationErrorAndPreservesDraftUntilCorrected() async throws {
    let startDate = try date(year: 2026, month: 7, day: 21)
    let endDate = try date(year: 2026, month: 7, day: 27)
    let schedule = [ScheduledPlanDay(weekday: .tuesday)]
    let store = TestStore(
      initialState: NewPlanFeature.State(
        name: "   ",
        selectedDuration: .custom,
        startDate: startDate,
        endDate: endDate,
        schedule: schedule
      ),
      reducer: { NewPlanFeature() }
    )

    await store.send(.view(.continueButtonTapped)) {
      $0.isNameValidationErrorPresented = true
    }
    #expect(store.state.step == .details)
    #expect(store.state.startDate == startDate)
    #expect(store.state.endDate == endDate)
    #expect(store.state.schedule == schedule)

    await store.send(.binding(.set(\.name, "Morning routine"))) {
      $0.name = "Morning routine"
      $0.isNameValidationErrorPresented = false
    }
  }

  @Test
  func activityPickerUpdatesSelectedDay() async throws {
    let activity = try activity(id: "00000000-0000-0000-0000-000000000001", name: "Read")
    let store = TestStore(
      initialState: NewPlanFeature.State(
        step: .weeklySchedule,
        schedule: [ScheduledPlanDay(weekday: .monday)]
      ),
      reducer: { NewPlanFeature() }
    )

    await store.send(.view(.addActivityTapped(.monday))) {
      $0.activityPickerDay = .monday
      $0.activityPicker = ActivityListFeature.State(
        selectedActivityIDs: [],
        title: NewPlanFeature.activityPickerTitle(for: .monday)
      )
    }
    await store.send(
      .activityPicker(
        .presented(.delegate(.selectionConfirmed([activity])))
      )
    ) {
      $0.schedule = [ScheduledPlanDay(weekday: .monday, activities: [activity])]
      $0.activityPickerDay = nil
      $0.activityPicker = nil
    }
  }

  @Test
  func activityPickerOpensWithoutDiscardingPlanDraft() async throws {
    let now = try date(year: 2026, month: 7, day: 13)
    let initialState = NewPlanFeature.State(
      step: .weeklySchedule,
      name: "Learn Spanish",
      startDate: now,
      schedule: [ScheduledPlanDay(weekday: .monday)]
    )
    let store = TestStore(
      initialState: initialState,
      reducer: { NewPlanFeature() }
    )

    await store.send(.view(.addActivityTapped(.monday))) {
      $0.activityPickerDay = .monday
      $0.activityPicker = ActivityListFeature.State(
        selectedActivityIDs: [],
        title: NewPlanFeature.activityPickerTitle(for: .monday)
      )
    }
    #expect(store.state.name == initialState.name)
    #expect(store.state.step == initialState.step)
    #expect(store.state.schedule == initialState.schedule)
  }

  @Test
  func applyToEmptyDayCopiesActivitiesImmediately() async throws {
    let activity = try activity(id: "00000000-0000-0000-0000-000000000001", name: "Read")
    let store = TestStore(
      initialState: NewPlanFeature.State(
        step: .weeklySchedule,
        schedule: [
          ScheduledPlanDay(weekday: .monday, activities: [activity]),
          ScheduledPlanDay(weekday: .tuesday)
        ]
      ),
      reducer: { NewPlanFeature() }
    )

    await store.send(.view(.applyToDaysTapped(.monday))) {
      $0.applySourceDay = .monday
    }
    await store.send(.view(.applyTargetTapped(.tuesday))) {
      $0.applyTargetDays = [.tuesday]
    }
    await store.send(.view(.applyConfirmed)) {
      $0.schedule[1].activities = [activity]
      $0.applySourceDay = nil
      $0.applyTargetDays = []
    }
  }

  @Test
  func applyToPopulatedDayRequiresReplacementConfirmation() async throws {
    let sourceActivity = try activity(id: "00000000-0000-0000-0000-000000000001", name: "Read")
    let existingActivity = try activity(id: "00000000-0000-0000-0000-000000000002", name: "Walk")
    let store = TestStore(
      initialState: NewPlanFeature.State(
        step: .weeklySchedule,
        schedule: [
          ScheduledPlanDay(weekday: .monday, activities: [sourceActivity]),
          ScheduledPlanDay(weekday: .tuesday, activities: [existingActivity])
        ]
      ),
      reducer: { NewPlanFeature() }
    )

    await store.send(.view(.applyToDaysTapped(.monday))) {
      $0.applySourceDay = .monday
    }
    await store.send(.view(.applyTargetTapped(.tuesday))) {
      $0.applyTargetDays = [.tuesday]
    }
    await store.send(.view(.applyConfirmed)) {
      $0.replacementTargetDays = [.tuesday]
    }
    #expect(store.state.schedule[1].activities == [existingActivity])

    await store.send(.view(.replacementConfirmed)) {
      $0.schedule[1].activities = [sourceActivity]
      $0.applySourceDay = nil
      $0.applyTargetDays = []
      $0.replacementTargetDays = []
    }
  }

  @Test
  func cancellingReplacementPreservesSelectionAndSchedules() async throws {
    let sourceActivity = try activity(id: "00000000-0000-0000-0000-000000000001", name: "Read")
    let existingActivity = try activity(id: "00000000-0000-0000-0000-000000000002", name: "Walk")
    let store = TestStore(
      initialState: NewPlanFeature.State(
        step: .weeklySchedule,
        schedule: [
          ScheduledPlanDay(weekday: .monday, activities: [sourceActivity]),
          ScheduledPlanDay(weekday: .tuesday, activities: [existingActivity])
        ]
      ),
      reducer: { NewPlanFeature() }
    )

    await store.send(.view(.applyToDaysTapped(.monday))) {
      $0.applySourceDay = .monday
    }
    await store.send(.view(.applyTargetTapped(.tuesday))) {
      $0.applyTargetDays = [.tuesday]
    }
    await store.send(.view(.applyConfirmed)) {
      $0.replacementTargetDays = [.tuesday]
    }
    await store.send(.view(.replacementCancelled)) {
      $0.replacementTargetDays = []
    }

    #expect(store.state.applySourceDay == .monday)
    #expect(store.state.applyTargetDays == [.tuesday])
    #expect(store.state.schedule[0].activities == [sourceActivity])
    #expect(store.state.schedule[1].activities == [existingActivity])
  }

  @Test
  func confirmingMixedTargetsReplacesEverySelectedTargetOnly() async throws {
    let sourceActivity = try activity(id: "00000000-0000-0000-0000-000000000001", name: "Read")
    let tuesdayActivity = try activity(id: "00000000-0000-0000-0000-000000000002", name: "Walk")
    let fridayActivity = try activity(id: "00000000-0000-0000-0000-000000000003", name: "Journal")
    let store = TestStore(
      initialState: NewPlanFeature.State(
        step: .weeklySchedule,
        schedule: [
          ScheduledPlanDay(weekday: .monday, activities: [sourceActivity]),
          ScheduledPlanDay(weekday: .tuesday, activities: [tuesdayActivity]),
          ScheduledPlanDay(weekday: .wednesday),
          ScheduledPlanDay(weekday: .thursday),
          ScheduledPlanDay(weekday: .friday, activities: [fridayActivity])
        ]
      ),
      reducer: { NewPlanFeature() }
    )

    await store.send(.view(.applyToDaysTapped(.monday))) {
      $0.applySourceDay = .monday
    }
    await store.send(.view(.applyTargetTapped(.tuesday))) {
      $0.applyTargetDays = [.tuesday]
    }
    await store.send(.view(.applyTargetTapped(.wednesday))) {
      $0.applyTargetDays = [.tuesday, .wednesday]
    }
    await store.send(.view(.applyTargetTapped(.thursday))) {
      $0.applyTargetDays = [.tuesday, .wednesday, .thursday]
    }
    await store.send(.view(.applyConfirmed)) {
      $0.replacementTargetDays = [.tuesday]
    }
    await store.send(.view(.replacementConfirmed)) {
      $0.schedule[1].activities = [sourceActivity]
      $0.schedule[2].activities = [sourceActivity]
      $0.schedule[3].activities = [sourceActivity]
      $0.applySourceDay = nil
      $0.applyTargetDays = []
      $0.replacementTargetDays = []
    }

    #expect(store.state.schedule[0].activities == [sourceActivity])
    #expect(store.state.schedule[4].activities == [fridayActivity])
  }

  @Test
  func scheduleWithActivitiesCanContinueToReview() async throws {
    let activity = try activity(id: "00000000-0000-0000-0000-000000000001", name: "Read")
    let store = TestStore(
      initialState: NewPlanFeature.State(
        step: .weeklySchedule,
        schedule: [ScheduledPlanDay(weekday: .monday, activities: [activity])]
      ),
      reducer: { NewPlanFeature() }
    )

    await store.send(.view(.continueButtonTapped)) {
      $0.step = .review
    }
  }

  @Test
  func emptyScheduleCannotContinueToReview() async {
    let store = TestStore(
      initialState: NewPlanFeature.State(
        step: .weeklySchedule,
        schedule: [ScheduledPlanDay(weekday: .monday)]
      ),
      reducer: { NewPlanFeature() }
    )

    await store.send(.view(.continueButtonTapped)) {
      $0.isScheduleValidationErrorPresented = true
    }
    #expect(store.state.step == .weeklySchedule)
  }

  @Test
  func blankNameCannotStartFromReview() async throws {
    let activity = try activity(id: "00000000-0000-0000-0000-000000000001", name: "Read")
    let store = TestStore(
      initialState: NewPlanFeature.State(
        step: .review,
        name: "   ",
        schedule: [ScheduledPlanDay(weekday: .monday, activities: [activity])]
      ),
      reducer: { NewPlanFeature() }
    )

    await store.send(.view(.startPlanButtonTapped)) {
      $0.isNameValidationErrorPresented = true
      $0.step = .details
    }
  }

  @Test
  func emptyScheduleCannotStartFromReview() async {
    let store = TestStore(
      initialState: NewPlanFeature.State(
        step: .review,
        name: "Morning routine",
        schedule: [ScheduledPlanDay(weekday: .monday)]
      ),
      reducer: { NewPlanFeature() }
    )

    await store.send(.view(.startPlanButtonTapped)) {
      $0.isScheduleValidationErrorPresented = true
      $0.step = .weeklySchedule
    }
  }

  @Test
  func onboardingPlanCanOnlyBeSubmittedOnceUntilSavingFails() async throws {
    let calendar = testCalendar()
    let startDate = try date(year: 2026, month: 7, day: 20, calendar: calendar)
    let activity = try activity(
      id: "00000000-0000-0000-0000-000000000001",
      name: "Read"
    )
    var state = NewPlanFeature.State(
      onboardingName: "Reading plan",
      startDate: startDate,
      suggestedActivity: activity,
      scheduledWeekdays: [.monday],
      calendar: calendar
    )
    state.step = .review
    let draft = NewPlanDraft(
      name: state.name,
      duration: state.selectedDuration,
      startDate: state.startDate,
      endDate: state.endDate,
      schedule: state.schedule
    )
    let store = TestStore(initialState: state) {
      NewPlanFeature()
    }

    await store.send(.view(.startPlanButtonTapped)) {
      $0.isSubmitting = true
    }
    await store.receive(.delegate(.planCreated(draft)))
    await store.send(.view(.startPlanButtonTapped))
    await store.send(.submissionFailed) {
      $0.isSubmitting = false
    }
    await store.send(.view(.startPlanButtonTapped)) {
      $0.isSubmitting = true
    }
    await store.receive(.delegate(.planCreated(draft)))
  }

  @Test
  func addingAnActivityClearsScheduleValidationErrorWithoutLosingDraft() async throws {
    let activity = try activity(id: "00000000-0000-0000-0000-000000000001", name: "Read")
    let startDate = try date(year: 2026, month: 7, day: 21)
    let schedule = [ScheduledPlanDay(weekday: .tuesday)]
    let store = TestStore(
      initialState: NewPlanFeature.State(
        step: .weeklySchedule,
        name: "Morning routine",
        startDate: startDate,
        schedule: schedule
      ),
      reducer: { NewPlanFeature() }
    )

    await store.send(.view(.continueButtonTapped)) {
      $0.isScheduleValidationErrorPresented = true
    }
    await store.send(.view(.addActivityTapped(.tuesday))) {
      $0.activityPickerDay = .tuesday
      $0.activityPicker = ActivityListFeature.State(
        selectedActivityIDs: [],
        title: NewPlanFeature.activityPickerTitle(for: .tuesday)
      )
    }
    await store.send(
      .activityPicker(.presented(.delegate(.selectionConfirmed([activity]))))
    ) {
      $0.schedule = [ScheduledPlanDay(weekday: .tuesday, activities: [activity])]
      $0.isScheduleValidationErrorPresented = false
      $0.activityPickerDay = nil
      $0.activityPicker = nil
    }

    #expect(store.state.name == "Morning routine")
    #expect(store.state.startDate == startDate)
    #expect(store.state.step == .weeklySchedule)
  }

  @Test
  func navigationPathUpdatesCurrentStep() async {
    let store = TestStore(
      initialState: NewPlanFeature.State(step: .review),
      reducer: { NewPlanFeature() }
    )

    await store.send(.view(.navigationPathChanged([.weeklySchedule]))) {
      $0.step = .weeklySchedule
    }
    await store.send(.view(.navigationPathChanged([]))) {
      $0.step = .details
    }
  }

  @Test
  func editingStartedPlanLoadsScheduleAndLocksStartDate() async throws {
    let calendar = testCalendar()
    let now = try date(year: 2026, month: 7, day: 15, calendar: calendar)
    let startDate = try date(year: 2026, month: 7, day: 13, calendar: calendar)
    let endDate = try date(year: 2026, month: 7, day: 19, calendar: calendar)
    let attemptedStartDate = try date(year: 2026, month: 7, day: 16, calendar: calendar)
    let read = try activity(id: "00000000-0000-0000-0000-000000000001", name: "Read")
    let plan = Plan(
      id: try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000010")),
      name: "Reading week",
      startDate: startDate,
      endDate: endDate,
      duration: .sevenDays,
      schedule: [
        PlanScheduleEntry(
          id: try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000011")),
          weekday: .monday,
          activityID: read.id,
          position: 0
        )
      ]
    )
    let state = NewPlanFeature.State(
      plan: plan,
      activities: [read],
      now: now,
      calendar: calendar
    )
    #expect(!state.isStartDateEditable)
    #expect(state.schedule.first(where: { $0.weekday == .monday })?.activities == [read])

    let store = withDependencies {
      $0.calendar = calendar
      $0.date.now = now
    } operation: {
      TestStore(initialState: state, reducer: { NewPlanFeature() })
    }
    await store.send(.binding(.set(\.startDate, attemptedStartDate)))
    #expect(store.state.startDate == startDate)
  }

  @Test
  func savingEditedPlanPreservesExistingScheduleEntryIdentity() async throws {
    let calendar = testCalendar()
    let startDate = try date(year: 2026, month: 7, day: 20, calendar: calendar)
    let endDate = try date(year: 2026, month: 7, day: 26, calendar: calendar)
    let read = try activity(id: "00000000-0000-0000-0000-000000000001", name: "Read")
    let walk = try activity(id: "00000000-0000-0000-0000-000000000002", name: "Walk")
    let planID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000010"))
    let entryID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000011"))
    let newEntryID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000012"))
    let plan = Plan(
      id: planID,
      name: "Reading week",
      startDate: startDate,
      endDate: endDate,
      duration: .sevenDays,
      schedule: [
        PlanScheduleEntry(id: entryID, weekday: .monday, activityID: read.id, position: 0)
      ]
    )
    var state = NewPlanFeature.State(
      plan: plan,
      activities: [read, walk],
      now: startDate,
      calendar: calendar
    )
    state.step = .review
    state.name = "Updated week"
    state.schedule = [ScheduledPlanDay(weekday: .monday, activities: [walk, read])]
    let expectedPlan = Plan(
      id: planID,
      name: "Updated week",
      startDate: startDate,
      endDate: endDate,
      duration: .sevenDays,
      schedule: [
        PlanScheduleEntry(id: newEntryID, weekday: .monday, activityID: walk.id, position: 0),
        PlanScheduleEntry(id: entryID, weekday: .monday, activityID: read.id, position: 1)
      ]
    )
    let store = withDependencies {
      $0.uuid = .constant(newEntryID)
    } operation: {
      TestStore(initialState: state, reducer: { NewPlanFeature() })
    }

    await store.send(.view(.startPlanButtonTapped))
    await store.receive(.delegate(.planUpdated(expectedPlan)))
  }

  @Test
  func plansFeatureOwnsNewPlanPresentation() async throws {
    let now = try date(year: 2026, month: 6, day: 8)
    let store = withDependencies {
      $0.date.now = now
    } operation: {
      TestStore(
        initialState: PlansFeature.State(),
        reducer: { PlansFeature() }
      )
    }

    await store.send(.view(.createPlanButtonTapped)) {
      $0.newPlan = NewPlanFeature.State(startDate: now)
    }
    await store.send(.newPlan(.presented(.delegate(.cancelTapped)))) {
      $0.newPlan = nil
    }
  }

  @Test
  func plansFeatureKeepsEditorOpenWhenSavingFails() async throws {
    struct SaveError: Error { }

    let calendar = testCalendar()
    let now = try date(year: 2026, month: 6, day: 8, calendar: calendar)
    let plan = Plan(
      id: try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000010")),
      name: "Reading week",
      startDate: now,
      endDate: now,
      duration: .custom,
      schedule: []
    )
    var state = PlansFeature.State()
    state.newPlan = NewPlanFeature.State(
      plan: plan,
      activities: [],
      now: now,
      calendar: calendar
    )
    let store = withDependencies {
      $0.calendar = calendar
      $0.date.now = now
      $0.planRepository = PlanRepository(
        loadPlans: { [] },
        loadActivePlans: { _ in [] },
        loadHistoricalPlans: { _ in [] },
        plan: { _ in nil },
        savePlan: { _ in throw SaveError() },
        archivePlan: { _, _ in },
        deletePlan: { _, _ in },
        loadOccurrences: { _ in [] },
        saveOccurrences: { _ in },
        synchronizeOccurrences: { _, _ in [] }
      )
    } operation: {
      TestStore(initialState: state, reducer: { PlansFeature() })
    }

    await store.send(.newPlan(.presented(.delegate(.planUpdated(plan)))))
    await store.receive(.internal(.planSaveFailed)) {
      $0.isSaveErrorPresented = true
    }
    #expect(store.state.newPlan != nil)
  }

  @Test
  func plansHistoryIsEmptyOnlyWithoutFinishedOrArchivedPlans() throws {
    let plan = Plan(
      id: try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000010")),
      name: "Reading week",
      startDate: .now,
      endDate: .now,
      duration: .custom,
      schedule: []
    )
    let item = PlanListItem(
      plan: plan,
      activities: [],
      occurrences: [],
      dayActivities: []
    )

    #expect(PlansFeature.State(selectedSection: .history).isHistoryEmpty)
    #expect(
      !PlansFeature.State(selectedSection: .history, finishedPlans: [item]).isHistoryEmpty
    )
    #expect(
      !PlansFeature.State(selectedSection: .history, archivedPlans: [item]).isHistoryEmpty
    )
  }

  @Test
  func activePlanOpensDetails() async throws {
    let calendar = testCalendar()
    let now = try date(year: 2026, month: 7, day: 15, calendar: calendar)
    let endDate = try date(year: 2026, month: 7, day: 21, calendar: calendar)
    let read = try activity(id: "00000000-0000-0000-0000-000000000001", name: "Read")
    let plan = Plan(
      id: try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000010")),
      name: "Reading week",
      startDate: now,
      endDate: endDate,
      duration: .sevenDays,
      schedule: [
        PlanScheduleEntry(
          id: try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000011")),
          weekday: .wednesday,
          activityID: read.id,
          position: 0
        )
      ]
    )
    let item = PlanListItem(
      plan: plan,
      activities: [read],
      occurrences: [],
      dayActivities: []
    )
    let store = withDependencies {
      $0.calendar = calendar
      $0.date.now = now
    } operation: {
      TestStore(
        initialState: PlansFeature.State(selectedSection: .active, activePlans: [item]),
        reducer: { PlansFeature() }
      )
    }

    await store.send(.view(.planTapped(plan.id))) {
      $0.planDetails = PlanDetailsFeature.State(
        plan: plan,
        allowsManagement: true,
        activities: [read]
      )
    }
  }

  @Test
  func planDetailsOffersEditAndConfirmedArchive() async throws {
    let calendar = testCalendar()
    let now = try date(year: 2026, month: 7, day: 15, calendar: calendar)
    let planID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000010"))
    let plan = Plan(
      id: planID,
      name: "Reading week",
      startDate: now,
      endDate: now,
      duration: .custom,
      schedule: []
    )
    let store = withDependencies {
      $0.activityRepository = ActivityRepository(
        activity: { _ in nil },
        loadActivities: { [] },
        saveActivity: { _ in },
        deleteActivity: { _ in },
        activityTask: { _ in nil },
        deleteActivityTask: { _ in }
      )
      $0.calendar = calendar
      $0.date.now = now
    } operation: {
      TestStore(
        initialState: PlanDetailsFeature.State(plan: plan, allowsManagement: true),
        reducer: { PlanDetailsFeature() }
      )
    }

    await store.send(.view(.editButtonTapped))
    await store.receive(.internal(.editActivitiesLoaded([]))) {
      $0.newPlan = NewPlanFeature.State(
        plan: plan,
        activities: [],
        now: now,
        calendar: calendar
      )
    }
    await store.send(.view(.archiveButtonTapped)) {
      $0.isArchiveConfirmationPresented = true
    }
    await store.send(.view(.archiveConfirmed)) {
      $0.isArchiveConfirmationPresented = false
    }
    await store.receive(.delegate(.archivePlanTapped(planID)))
  }

  @Test
  func archiveFromPlanListRequiresConfirmation() async throws {
    let planID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000010"))
    let plan = Plan(
      id: planID,
      name: "Reading week",
      startDate: .now,
      endDate: .now,
      duration: .custom,
      schedule: []
    )
    let item = PlanListItem(
      plan: plan,
      activities: [],
      occurrences: [],
      dayActivities: []
    )
    let store = TestStore(
      initialState: PlansFeature.State(selectedSection: .active, activePlans: [item]),
      reducer: { PlansFeature() }
    )

    await store.send(.view(.archivePlanTapped(planID))) {
      $0.archiveConfirmationPlanID = planID
    }
    await store.send(.view(.archivePlanCancelled)) {
      $0.archiveConfirmationPlanID = nil
    }
  }

  private func testCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
    calendar.firstWeekday = 2
    return calendar
  }

  private func date(
    year: Int,
    month: Int,
    day: Int,
    calendar: Calendar = .autoupdatingCurrent
  ) throws -> Date {
    try #require(
      calendar.date(
        from: DateComponents(year: year, month: month, day: day, hour: 12)
      )
    )
  }

  private func adding(
    _ component: Calendar.Component,
    value: Int,
    to date: Date,
    calendar: Calendar = .autoupdatingCurrent
  ) throws -> Date {
    try #require(calendar.date(byAdding: component, value: value, to: date))
  }

  private func activity(id: String, name: String) throws -> Activity {
    Activity(id: try #require(UUID(uuidString: id)), name: name)
  }
}
