import ComposableArchitecture
import Dependencies
import Foundation
import Models
@testable import Plans
@testable import Repositories
import Testing

@MainActor
@Suite(.serialized)
struct PlansPersistenceTests {
  @Test
  func recreatedFiveDayPlanPersistsSevenDayScheduleAndOccurrences() async throws {
    let coreDataStack = CoreDataStack.plansTestValue
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
    let originalStartDate = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 7, day: 6))
    )
    let originalEndDate = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 7, day: 10))
    )
    let recreatedStartDate = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 7, day: 13))
    )
    let recreatedEndDate = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 7, day: 19))
    )
    let activity = Activity(id: UUID(), name: "Read")
    let originalPlan = Plan(
      id: UUID(),
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
    let recreatedPlan = Plan(
      id: UUID(),
      name: originalPlan.name,
      startDate: recreatedStartDate,
      endDate: recreatedEndDate,
      duration: .sevenDays,
      schedule: PlanWeekday.allCases.map {
        PlanScheduleEntry(
          id: UUID(),
          weekday: $0,
          activityID: activity.id,
          position: 0
        )
      }
    )

    try await withDependencies {
      $0.calendar = calendar
      $0.coreDataStack = coreDataStack
    } operation: {
      let repository = PlanRepository.liveValue
      try await repository.savePlan(originalPlan)
      _ = try await repository.synchronizeOccurrences(originalPlan, originalStartDate)
      try await repository.savePlan(recreatedPlan)
      _ = try await repository.synchronizeOccurrences(recreatedPlan, recreatedStartDate)

      let persistedPlan = try #require(await repository.plan(recreatedPlan.id))
      let occurrences = try await repository.loadOccurrences(recreatedPlan.id)

      #expect(persistedPlan.schedule.count == 7)
      #expect(Set(persistedPlan.schedule.map(\.weekday)) == Set(PlanWeekday.allCases))
      #expect(occurrences.count == 7)
      #expect(Set(occurrences.map(\.activityID)) == [activity.id])
    }
  }

  @Test
  func createdPlanAndProgressLoadIntoFreshFeature() async throws {
    let coreDataStack = CoreDataStack.plansTestValue
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
    let startDate = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 7, day: 13))
    )
    let endDate = try #require(calendar.date(byAdding: .day, value: 6, to: startDate))
    let activity = Activity(id: UUID(), name: "Read")
    let draft = NewPlanDraft(
      name: "Reading week",
      duration: .sevenDays,
      startDate: startDate,
      endDate: endDate,
      schedule: [ScheduledPlanDay(weekday: .monday, activities: [activity])]
    )
    let plan = draft.plan(id: UUID(), scheduleEntryID: UUID.init)

    try await withDependencies {
      $0.calendar = calendar
      $0.coreDataStack = coreDataStack
      $0.date.now = startDate
    } operation: {
      let planRepository = PlanRepository.liveValue
      try await ActivityRepository.liveValue.saveActivity(activity)
      try await planRepository.savePlan(plan)
      var occurrences = try await planRepository.synchronizeOccurrences(plan, startDate)
      let occurrence = try #require(occurrences.first)
      let dayActivity = DayActivity(
        id: UUID(),
        date: occurrence.date,
        activity: activity,
        doneDate: occurrence.date,
        isGeneratedAutomatically: true
      )
      try await DayActivityRepository.liveValue.saveDayActivity(dayActivity)
      occurrences[0].dayActivityID = dayActivity.id
      try await planRepository.saveOccurrences(occurrences)

      let persistedPlan = try #require(await planRepository.plan(plan.id))
      let persistedActivity = try #require(await ActivityRepository.liveValue.loadActivities().first)
      let persistedOccurrences = try await planRepository.loadOccurrences(plan.id)
      let persistedDayActivity = try #require(
        await DayActivityRepository.liveValue.dayActivities(
          configuration: ActivitiesFetchConfiguration(
            predicates: [NSPredicate(format: "identifier == %@", dayActivity.id as CVarArg)]
          )
        ).first
      )
      let expectedItem = PlanListItem(
        plan: persistedPlan,
        activities: [persistedActivity],
        occurrences: persistedOccurrences,
        dayActivities: [persistedDayActivity]
      )
      let expectedSnapshot = PlansSnapshot(
        activePlans: [expectedItem],
        finishedPlans: [],
        archivedPlans: []
      )
      let store = TestStore(
        initialState: PlansFeature.State(),
        reducer: { PlansFeature() }
      ) {
        $0.activityRepository = .liveValue
        $0.calendar = calendar
        $0.coreDataStack = coreDataStack
        $0.date.now = startDate
        $0.dayActivityRepository = .liveValue
        $0.planRepository = .liveValue
      }

      await store.send(.view(.appeared))
      await store.receive(.internal(.loadPlans)) {
        $0.loadState = .loading
      }
      await store.receive(.internal(.plansLoaded(expectedSnapshot))) {
        $0.loadState = .loaded
        $0.activePlans = [expectedItem]
      }

      #expect(store.state.activePlans.first?.progress.percentComplete == 100)
    }
  }
}
