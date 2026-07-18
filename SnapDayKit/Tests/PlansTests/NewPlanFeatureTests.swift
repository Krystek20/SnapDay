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
  func shortRangeOnlyIncludesWeekdaysThatOccur() async throws {
    let calendar = testCalendar()
    let friday = try date(year: 2026, month: 6, day: 12, calendar: calendar)
    let saturday = try date(year: 2026, month: 6, day: 13, calendar: calendar)
    let expectedSchedule = [
      ScheduledPlanDay(weekday: .friday),
      ScheduledPlanDay(weekday: .saturday)
    ]
    let store = withDependencies {
      $0.calendar = calendar
    } operation: {
      TestStore(
        initialState: NewPlanFeature.State(
          name: "Weekend plan",
          selectedDuration: .custom,
          startDate: friday,
          endDate: saturday
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
        title: "Add to \(PlanWeekday.monday.title)"
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
        title: "Add to \(PlanWeekday.monday.title)"
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

    await store.send(.view(.continueButtonTapped))
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
      $0.planDetails = PlanDetailsFeature.State(plan: plan, allowsManagement: true)
    }
  }

  @Test
  func activePlanContextMenuOpensInEditMode() async throws {
    let calendar = testCalendar()
    let now = try date(year: 2026, month: 7, day: 15, calendar: calendar)
    let read = try activity(id: "00000000-0000-0000-0000-000000000001", name: "Read")
    let plan = Plan(
      id: try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000010")),
      name: "Reading week",
      startDate: now,
      endDate: now,
      duration: .custom,
      schedule: []
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

    await store.send(.view(.editPlanTapped(plan.id))) {
      $0.newPlan = NewPlanFeature.State(
        plan: plan,
        activities: [read],
        now: now,
        calendar: calendar
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
