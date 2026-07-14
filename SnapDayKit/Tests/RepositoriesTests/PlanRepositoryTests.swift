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
