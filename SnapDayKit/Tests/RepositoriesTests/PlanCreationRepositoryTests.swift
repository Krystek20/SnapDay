import ComposableArchitecture
import Foundation
import Models
import Testing
@testable import Repositories

@MainActor
struct PlanCreationRepositoryTests {

  @Test
  func createsActivityPlanAndOccurrencesTogether() async throws {
    let fixture = try makeFixture()

    try await withDependencies {
      $0.coreDataStack = .testValue
    } operation: {
      try await PlanCreationRepository.liveValue.create(
        fixture.plan,
        [fixture.activity],
        fixture.occurrences
      )

      let savedActivity = try await EntityHandler().fetch(
        Activity.self,
        identifier: fixture.activity.id as CVarArg
      )
      let savedPlan = try await EntityHandler().fetch(
        Plan.self,
        identifier: fixture.plan.id as CVarArg
      )
      let savedOccurrences: [PlanOccurrence] = try await EntityHandler().fetch(
        PlanOccurrence.self,
        predicates: { NSPredicate(format: "planIdentifier == %@", fixture.plan.id as CVarArg) }
      )

      #expect(savedActivity == fixture.activity)
      #expect(savedPlan == fixture.plan)
      #expect(savedOccurrences == fixture.occurrences)
    }
  }

  @Test
  func rollsBackAllObjectsWhenAnOccurrenceCannotBeCreated() async throws {
    let fixture = try makeFixture()
    let invalidOccurrence = PlanOccurrence(
      planID: UUID(),
      activityID: fixture.activity.id,
      date: fixture.plan.startDate
    )

    try await withDependencies {
      $0.coreDataStack = .testValue
    } operation: {
      await #expect(throws: (any Error).self) {
        try await PlanCreationRepository.liveValue.create(
          fixture.plan,
          [fixture.activity],
          [invalidOccurrence]
        )
      }

      let savedActivity = try await EntityHandler().fetch(
        Activity.self,
        identifier: fixture.activity.id as CVarArg
      )
      let savedPlan = try await EntityHandler().fetch(
        Plan.self,
        identifier: fixture.plan.id as CVarArg
      )

      #expect(savedActivity == nil)
      #expect(savedPlan == nil)
    }
  }

  private func makeFixture() throws -> (
    activity: Activity,
    plan: Plan,
    occurrences: [PlanOccurrence]
  ) {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    let startDate = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 8, day: 10))
    )
    let activity = Activity(id: UUID(), name: "Read", dueDaysCount: 0, startDate: startDate)
    let plan = Plan(
      id: UUID(),
      name: "Reading plan",
      startDate: startDate,
      endDate: startDate,
      duration: .custom,
      schedule: [
        PlanScheduleEntry(
          id: UUID(),
          weekday: .monday,
          activityID: activity.id,
          position: 0
        )
      ]
    )
    return (
      activity,
      plan,
      plan.scheduledOccurrences(calendar: calendar)
    )
  }
}
