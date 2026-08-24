import ComposableArchitecture
import Foundation
import Models
@testable import Plans
@testable import Repositories
import Testing
import Utilities

@MainActor
struct PlanDetailsFeatureTests {

  @Test(arguments: [PlanStatus.finished, .archived])
  func historicalPlanCanBeDeleted(status: PlanStatus) async throws {
    let calendar = testCalendar()
    let now = try testDate(day: 15, calendar: calendar)
    var historicalPlan = try plan(
      startDate: try testDate(day: 1, calendar: calendar),
      endDate: try testDate(day: status == .finished ? 10 : 31, calendar: calendar)
    )
    historicalPlan.isArchived = status == .archived
    let store = withDependencies {
      $0.calendar = calendar
      $0.date.now = now
    } operation: {
      TestStore(
        initialState: PlanDetailsFeature.State(plan: historicalPlan, allowsManagement: true),
        reducer: { PlanDetailsFeature() }
      )
    }

    await store.send(.view(.deleteButtonTapped)) {
      $0.isDeleteConfirmationPresented = true
    }
    await store.send(.view(.deleteConfirmed)) {
      $0.isDeleteConfirmationPresented = false
    }
    await store.receive(.delegate(.deletePlanTapped(historicalPlan.id)))
  }

  @Test
  func activePlanCannotBeDeleted() async throws {
    let calendar = testCalendar()
    let now = try testDate(day: 15, calendar: calendar)
    let activePlan = try plan(
      startDate: try testDate(day: 1, calendar: calendar),
      endDate: try testDate(day: 31, calendar: calendar)
    )
    let store = withDependencies {
      $0.calendar = calendar
      $0.date.now = now
    } operation: {
      TestStore(
        initialState: PlanDetailsFeature.State(plan: activePlan, allowsManagement: true),
        reducer: { PlanDetailsFeature() }
      )
    }

    await store.send(.view(.deleteButtonTapped))
  }

  @Test
  func expiredArchivedPlanGuidesUserToCreateSimilar() async throws {
    let calendar = testCalendar()
    let now = try testDate(day: 15, calendar: calendar)
    var archivedPlan = try plan(
      startDate: try testDate(day: 1, calendar: calendar),
      endDate: try testDate(day: 10, calendar: calendar)
    )
    archivedPlan.isArchived = true
    let store = withDependencies {
      $0.calendar = calendar
      $0.date.now = now
    } operation: {
      TestStore(
        initialState: PlanDetailsFeature.State(plan: archivedPlan, allowsManagement: true),
        reducer: { PlanDetailsFeature() }
      )
    }

    await store.send(.view(.restoreButtonTapped)) {
      $0.isRestoreUnavailableAlertPresented = true
    }
  }

  @Test
  func validArchivedPlanIsRestoredAndRefreshed() async throws {
    let calendar = testCalendar()
    let now = try testDate(day: 15, calendar: calendar)
    let activity = Activity(id: UUID(1), name: "Read")
    var archivedPlan = try plan(
      startDate: try testDate(day: 1, calendar: calendar),
      endDate: try testDate(day: 31, calendar: calendar),
      activity: activity
    )
    archivedPlan.isArchived = true
    var restoredPlan = archivedPlan
    restoredPlan.isArchived = false
    let recorder = PlanRecorder()
    let store = withDependencies {
      $0.activityRepository = activityRepository(activities: [activity])
      $0.calendar = calendar
      $0.date.now = now
      $0.planRepository = planRepository(recorder: recorder)
    } operation: {
      TestStore(
        initialState: PlanDetailsFeature.State(plan: archivedPlan, allowsManagement: true),
        reducer: { PlanDetailsFeature() }
      )
    }

    await store.send(.view(.restoreButtonTapped))
    await store.receive(.internal(.lifecyclePlanSaved(restoredPlan))) {
      $0.plan = restoredPlan
    }
    await store.receive(.view(.task)) {
      $0.isLoading = true
      $0.referenceDate = now
    }
    await store.receive(.delegate(.planUpdated))
    await store.receive(.internal(.detailsLoaded([activity], PlanProgressSnapshot(
      plan: restoredPlan,
      occurrences: [],
      dayActivities: []
    )))) {
      $0.activities = [activity]
      $0.isLoading = false
    }

    #expect(await recorder.savedPlans == [restoredPlan])
    #expect(await recorder.synchronizationDates == [calendar.startOfDay(for: now)])
  }

  @Test
  func restoredPlanRefreshKeepsItsAlreadyLoadedActivities() async throws {
    let calendar = testCalendar()
    let now = try testDate(day: 15, calendar: calendar)
    let activity = Activity(id: UUID(1), name: "Read")
    let restoredPlan = try plan(
      startDate: try testDate(day: 1, calendar: calendar),
      endDate: try testDate(day: 31, calendar: calendar),
      activity: activity
    )
    let store = withDependencies {
      $0.activityRepository = activityRepository(activities: [])
      $0.calendar = calendar
      $0.date.now = now
      $0.planRepository = planRepository(recorder: PlanRecorder())
    } operation: {
      TestStore(
        initialState: PlanDetailsFeature.State(
          plan: restoredPlan,
          allowsManagement: true,
          activities: [activity]
        ),
        reducer: { PlanDetailsFeature() }
      )
    }

    await store.send(.view(.task)) {
      $0.isLoading = true
      $0.referenceDate = now
    }
    await store.receive(.internal(.detailsLoaded([activity], PlanProgressSnapshot(
      plan: restoredPlan,
      occurrences: [],
      dayActivities: []
    )))) {
      $0.isLoading = false
    }
  }

  @Test
  func plansReloadKeepsActivitiesInSelectedRestoredPlan() async throws {
    let activity = Activity(id: UUID(1), name: "Read")
    let restoredPlan = try plan(activity: activity)
    let reloadedItem = PlanListItem(
      plan: restoredPlan,
      activities: [],
      occurrences: [],
      dayActivities: []
    )
    let store = TestStore(
      initialState: PlansFeature.State(
        selectedSection: .active,
        planDetails: PlanDetailsFeature.State(
          plan: restoredPlan,
          allowsManagement: true,
          activities: [activity]
        )
      ),
      reducer: { PlansFeature() }
    )

    await store.send(.internal(.plansLoaded(PlansSnapshot(
      activePlans: [reloadedItem],
      finishedPlans: [],
      archivedPlans: []
    )))) {
      $0.activePlans = [reloadedItem]
      $0.planDetails = PlanDetailsFeature.State(
        plan: restoredPlan,
        allowsManagement: true,
        activities: [activity]
      )
    }
  }

  @Test
  func createSimilarPrefillsScheduleWithActivities() async throws {
    let calendar = testCalendar()
    let now = try testDate(day: 15, calendar: calendar)
    let activity = Activity(id: UUID(1), name: "Read")
    let finishedPlan = try plan(
      startDate: try testDate(day: 1, calendar: calendar),
      endDate: try testDate(day: 7, calendar: calendar),
      duration: .sevenDays,
      activity: activity
    )
    let store = withDependencies {
      $0.activityRepository = activityRepository(activities: [activity])
      $0.calendar = calendar
      $0.date.now = now
    } operation: {
      TestStore(
        initialState: PlanDetailsFeature.State(plan: finishedPlan, allowsManagement: true),
        reducer: { PlanDetailsFeature() }
      )
    }

    await store.send(.view(.createSimilarButtonTapped))
    await store.receive(.internal(.similarActivitiesLoaded([activity]))) {
      $0.newPlan = NewPlanFeature.State(
        copying: finishedPlan,
        activities: [activity],
        startDate: now,
        calendar: calendar
      )
    }

    let copiedPlan = try #require(store.state.newPlan)
    #expect(copiedPlan.startDate == calendar.startOfDay(for: now))
    #expect(copiedPlan.schedule.first(where: { $0.weekday == .wednesday })?.activities == [activity])
  }

  @Test
  func createSimilarUsesActivitiesAlreadyLoadedWithDetails() async throws {
    let calendar = testCalendar()
    let now = try testDate(day: 15, calendar: calendar)
    let activity = Activity(id: UUID(1), name: "Read")
    let finishedPlan = try plan(
      startDate: try testDate(day: 1, calendar: calendar),
      endDate: try testDate(day: 7, calendar: calendar),
      duration: .sevenDays,
      activity: activity
    )
    let store = withDependencies {
      $0.activityRepository.loadActivities = { throw TestError() }
      $0.calendar = calendar
      $0.date.now = now
    } operation: {
      TestStore(
        initialState: PlanDetailsFeature.State(
          plan: finishedPlan,
          allowsManagement: true,
          activities: [activity]
        ),
        reducer: { PlanDetailsFeature() }
      )
    }

    await store.send(.view(.createSimilarButtonTapped))
    await store.receive(.internal(.similarActivitiesLoaded([activity]))) {
      $0.newPlan = NewPlanFeature.State(
        copying: finishedPlan,
        activities: [activity],
        startDate: now,
        calendar: calendar
      )
    }

    let copiedPlan = try #require(store.state.newPlan)
    #expect(copiedPlan.schedule.first(where: { $0.weekday == .wednesday })?.activities == [activity])
  }

  @Test
  func failedEditKeepsEditorOpenAndShowsError() async throws {
    let calendar = testCalendar()
    let now = try testDate(day: 15, calendar: calendar)
    let originalPlan = try plan()
    var updatedPlan = originalPlan
    updatedPlan.name = "Updated plan"
    var state = PlanDetailsFeature.State(plan: originalPlan, allowsManagement: true)
    state.newPlan = NewPlanFeature.State(
      plan: originalPlan,
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
        savePlan: { _ in throw TestError() },
        archivePlan: { _, _ in },
        deletePlan: { _, _ in },
        loadOccurrences: { _ in [] },
        saveOccurrences: { _ in },
        synchronizeOccurrences: { _, _ in [] },
        skipDayActivity: { _ in false }
      )
    } operation: {
      TestStore(initialState: state, reducer: { PlanDetailsFeature() })
    }

    await store.send(.newPlan(.presented(.delegate(.planUpdated(updatedPlan)))))
    await store.receive(.internal(.planSaveFailed)) {
      $0.isSaveErrorPresented = true
    }
    #expect(store.state.newPlan != nil)
  }

  private func plan(
    startDate: Date? = nil,
    endDate: Date? = nil,
    duration: PlanDuration = .custom,
    activity: Activity? = nil
  ) throws -> Plan {
    let calendar = testCalendar()
    let startDate = try startDate ?? testDate(day: 1, calendar: calendar)
    let endDate = try endDate ?? testDate(day: 31, calendar: calendar)
    return Plan(
      id: UUID(10),
      name: "Reading plan",
      startDate: startDate,
      endDate: endDate,
      duration: duration,
      schedule: activity.map {
        [PlanScheduleEntry(id: UUID(11), weekday: .wednesday, activityID: $0.id, position: 0)]
      } ?? []
    )
  }

  private struct TestError: Error { }

  private func activityRepository(activities: [Activity]) -> ActivityRepository {
    ActivityRepository(
      activity: { _ in nil },
      loadActivities: { activities },
      saveActivity: { _ in },
      deleteActivity: { _ in },
      activityTask: { _ in nil },
      deleteActivityTask: { _ in }
    )
  }

  private func planRepository(recorder: PlanRecorder) -> PlanRepository {
    PlanRepository(
      loadPlans: { [] },
      loadActivePlans: { _ in [] },
      loadHistoricalPlans: { _ in [] },
      plan: { _ in nil },
      savePlan: { plan in await recorder.save(plan) },
      archivePlan: { _, _ in },
      deletePlan: { _, _ in },
      loadOccurrences: { _ in [] },
      saveOccurrences: { _ in },
      synchronizeOccurrences: { plan, date in
        await recorder.synchronize(plan, from: date)
        return []
      },
      skipDayActivity: { _ in false }
    )
  }

  private func testCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
    calendar.firstWeekday = 2
    return calendar
  }

  private func testDate(day: Int, calendar: Calendar? = nil) throws -> Date {
    let calendar = calendar ?? testCalendar()
    return try #require(
      calendar.date(from: DateComponents(year: 2026, month: 7, day: day, hour: 12))
    )
  }
}

private actor PlanRecorder {
  private(set) var savedPlans: [Plan] = []
  private(set) var synchronizationDates: [Date] = []

  func save(_ plan: Plan) {
    savedPlans.append(plan)
  }

  func synchronize(_ plan: Plan, from date: Date) {
    synchronizationDates.append(date)
  }
}

private extension UUID {
  init(_ suffix: UInt8) {
    self.init(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, suffix))
  }
}
