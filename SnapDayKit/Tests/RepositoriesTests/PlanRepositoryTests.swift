import CoreData
import Dependencies
import Foundation
import Models
@testable import Repositories
import Testing

@Suite(.serialized)
struct PlanRepositoryTests {

  @Test
  func savesAndUpdatesPlanSchedule() async throws {
    try await withDependencies {
      $0.coreDataStack = .testValue
    } operation: {
      let repository = PlanRepository.liveValue
      var plan = makePlan()

      try await repository.savePlan(plan)
      let savedPlan = try #require(try await repository.plan(plan.id))
      #expect(savedPlan == plan)

      plan.name = "Updated plan"
      let remainingEntry = try #require(plan.schedule.last)
      plan.schedule = [remainingEntry]
      try await repository.savePlan(plan)

      let updatedPlan = try #require(try await repository.plan(plan.id))
      #expect(updatedPlan == plan)
      #expect(updatedPlan.schedule.count == 1)
    }
  }

  @Test
  func separatesActiveAndHistoricalPlans() async throws {
    try await withDependencies {
      $0.coreDataStack = .testValue
    } operation: {
      let repository = PlanRepository.liveValue
      let today = Date(timeIntervalSinceReferenceDate: 800_000_000)
      let activePlan = makePlan(startDate: today, endDate: today.addingTimeInterval(86_400))
      var archivedPlan = makePlan(
        id: UUID(),
        startDate: today.addingTimeInterval(-172_800),
        endDate: today.addingTimeInterval(-86_400)
      )
      archivedPlan.isArchived = true

      try await repository.savePlan(activePlan)
      try await repository.savePlan(archivedPlan)

      #expect(try await repository.loadActivePlans(today).map(\.id) == [activePlan.id])
      #expect(try await repository.loadHistoricalPlans(today).map(\.id) == [archivedPlan.id])

      try await repository.archivePlan(activePlan.id)
      let archivedActivePlan = try #require(try await repository.plan(activePlan.id))
      #expect(archivedActivePlan.isArchived)
      #expect(try await repository.loadActivePlans(today).isEmpty)
    }
  }

  @Test
  func updatesOccurrenceWithoutCreatingDuplicate() async throws {
    try await withDependencies {
      $0.coreDataStack = .testValue
    } operation: {
      let repository = PlanRepository.liveValue
      let plan = makePlan()
      let occurrenceDate = plan.startDate
      let scheduledActivity = try #require(plan.schedule.first)
      var occurrence = PlanOccurrence(
        planID: plan.id,
        activityID: scheduledActivity.activityID,
        date: occurrenceDate
      )

      try await repository.savePlan(plan)
      try await repository.saveOccurrences([occurrence])

      occurrence.dayActivityID = UUID()
      try await repository.saveOccurrences([occurrence])

      let occurrences = try await repository.loadOccurrences(plan.id)
      #expect(occurrences == [occurrence])
    }
  }

  @Test
  func synchronizesFutureOccurrencesWithoutChangingLinkedHistory() async throws {
    try await withDependencies {
      $0.coreDataStack = .testValue
    } operation: {
      let repository = PlanRepository.liveValue
      var calendar = Calendar.autoupdatingCurrent
      calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
      let monday = try #require(
        calendar.date(from: DateComponents(year: 2026, month: 7, day: 13))
      )
      let sunday = try #require(calendar.date(byAdding: .day, value: 6, to: monday))
      let tuesday = try #require(calendar.date(byAdding: .day, value: 1, to: monday))
      let activityID = UUID()
      var plan = Plan(
        id: UUID(),
        name: "Weekly plan",
        startDate: monday,
        endDate: sunday,
        duration: .sevenDays,
        schedule: [
          PlanScheduleEntry(id: UUID(), weekday: .monday, activityID: activityID, position: 0),
          PlanScheduleEntry(id: UUID(), weekday: .wednesday, activityID: activityID, position: 0),
          PlanScheduleEntry(id: UUID(), weekday: .thursday, activityID: activityID, position: 0)
        ]
      )

      try await repository.savePlan(plan)
      var initialOccurrences = try await repository.synchronizeOccurrences(plan, monday)
      #expect(initialOccurrences.count == 3)

      for index in initialOccurrences.indices where initialOccurrences[index].date != calendar.date(
        byAdding: .day,
        value: 3,
        to: monday
      ) {
        initialOccurrences[index].dayActivityID = UUID()
      }
      try await repository.saveOccurrences(initialOccurrences)

      plan.schedule = [
        PlanScheduleEntry(id: UUID(), weekday: .friday, activityID: activityID, position: 0)
      ]
      try await repository.savePlan(plan)
      let synchronized = try await repository.synchronizeOccurrences(plan, tuesday)
      let synchronizedAgain = try await repository.synchronizeOccurrences(plan, tuesday)

      #expect(synchronized.count == 3)
      #expect(synchronizedAgain == synchronized)
      #expect(synchronized.contains { $0.date == monday && $0.dayActivityID != nil })
      #expect(synchronized.contains { calendar.component(.weekday, from: $0.date) == 4 && $0.dayActivityID != nil })
      #expect(synchronized.contains { calendar.component(.weekday, from: $0.date) == 6 && $0.dayActivityID == nil })
      #expect(!synchronized.contains { calendar.component(.weekday, from: $0.date) == 5 })
      #expect(try await repository.loadOccurrences(plan.id) == synchronized)
    }
  }

  @Test
  func synchronizesSameActivityOnSaturdayAndSunday() async throws {
    try await withDependencies {
      $0.coreDataStack = .testValue
    } operation: {
      let repository = PlanRepository.liveValue
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
      let saturday = try #require(
        calendar.date(from: DateComponents(year: 2026, month: 7, day: 18))
      )
      let nextSunday = try #require(calendar.date(byAdding: .day, value: 8, to: saturday))
      let activityID = UUID()
      let plan = Plan(
        id: UUID(),
        name: "Weekend plan",
        startDate: saturday,
        endDate: nextSunday,
        duration: .custom,
        schedule: [
          PlanScheduleEntry(id: UUID(), weekday: .saturday, activityID: activityID, position: 0),
          PlanScheduleEntry(id: UUID(), weekday: .sunday, activityID: activityID, position: 0)
        ]
      )

      try await repository.savePlan(plan)
      let occurrences = try await repository.synchronizeOccurrences(plan, saturday)

      #expect(occurrences.count == 4)
      #expect(
        occurrences.map { calendar.component(.weekday, from: $0.date) }
          == [7, 1, 7, 1]
      )
    }
  }

  private func makePlan(
    id: UUID = UUID(),
    startDate: Date = Date(timeIntervalSinceReferenceDate: 800_000_000),
    endDate: Date = Date(timeIntervalSinceReferenceDate: 800_518_400)
  ) -> Plan {
    Plan(
      id: id,
      name: "Learn Spanish",
      startDate: startDate,
      endDate: endDate,
      duration: .sevenDays,
      schedule: [
        PlanScheduleEntry(
          id: UUID(),
          weekday: .monday,
          activityID: UUID(),
          position: 0
        ),
        PlanScheduleEntry(
          id: UUID(),
          weekday: .wednesday,
          activityID: UUID(),
          position: 0
        )
      ]
    )
  }
}
