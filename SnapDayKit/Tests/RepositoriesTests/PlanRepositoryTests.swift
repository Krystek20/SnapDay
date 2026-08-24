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

      try await repository.archivePlan(activePlan.id, today)
      let archivedActivePlan = try #require(try await repository.plan(activePlan.id))
      #expect(archivedActivePlan.isArchived)
      #expect(try await repository.loadActivePlans(today).isEmpty)
    }
  }

  @Test
  func archivingPlanRemovesUpcomingGeneratedActivitiesAndKeepsHistory() async throws {
    try await withDependencies {
      $0.coreDataStack = .testValue
    } operation: {
      let repository = PlanRepository.liveValue
      let dayActivityRepository = DayActivityRepository.liveValue
      let today = Date(timeIntervalSinceReferenceDate: 800_000_000)
      let yesterday = today.addingTimeInterval(-86_400)
      let plan = makePlan(startDate: yesterday, endDate: today.addingTimeInterval(86_400))
      let upcoming = makeDayActivity(date: today)
      let historical = makeDayActivity(date: yesterday)
      let occurrences = [
        PlanOccurrence(
          planID: plan.id,
          activityID: UUID(),
          date: yesterday,
          dayActivityID: historical.id
        ),
        PlanOccurrence(
          planID: plan.id,
          activityID: UUID(),
          date: today,
          dayActivityID: upcoming.id
        )
      ]

      try await repository.savePlan(plan)
      try await dayActivityRepository.saveDayActivity(upcoming)
      try await dayActivityRepository.saveDayActivity(historical)
      try await repository.saveOccurrences(occurrences)

      try await repository.archivePlan(plan.id, today)

      let archivedPlan = try #require(try await repository.plan(plan.id))
      let persistedDayActivities = try await dayActivityRepository.dayActivities(
        configuration: ActivitiesFetchConfiguration(
          predicates: [
            NSPredicate(format: "identifier IN %@", [upcoming.id, historical.id])
          ]
        )
      )
      let persistedDayActivityIDs = Set(persistedDayActivities.map(\.id))

      #expect(archivedPlan.isArchived)
      #expect(try await repository.loadOccurrences(plan.id) == occurrences)
      #expect(!persistedDayActivityIDs.contains(upcoming.id))
      #expect(persistedDayActivityIDs.contains(historical.id))
    }
  }

  @Test
  func archivingLastPlanSharingActivityWithArchivedPlanRemovesUpcomingActivity() async throws {
    try await withDependencies {
      $0.coreDataStack = .testValue
    } operation: {
      let repository = PlanRepository.liveValue
      let dayActivityRepository = DayActivityRepository.liveValue
      let today = Date(timeIntervalSinceReferenceDate: 800_000_000)
      let firstPlan = makePlan(startDate: today, endDate: today)
      let secondPlan = makePlan(id: UUID(), startDate: today, endDate: today)
      let sharedActivity = makeDayActivity(date: today)
      let activityID = UUID()

      try await repository.savePlan(firstPlan)
      try await repository.savePlan(secondPlan)
      try await dayActivityRepository.saveDayActivity(sharedActivity)
      try await repository.saveOccurrences([
        PlanOccurrence(
          planID: firstPlan.id,
          activityID: activityID,
          date: today,
          dayActivityID: sharedActivity.id
        ),
        PlanOccurrence(
          planID: secondPlan.id,
          activityID: activityID,
          date: today,
          dayActivityID: sharedActivity.id
        )
      ])

      try await repository.archivePlan(firstPlan.id, today)
      #expect(try await containsDayActivity(sharedActivity.id, in: dayActivityRepository))

      try await repository.archivePlan(secondPlan.id, today)
      #expect(try await !containsDayActivity(sharedActivity.id, in: dayActivityRepository))
    }
  }

  @Test
  func deletingPlanAlsoDeletesItsOccurrences() async throws {
    try await withDependencies {
      $0.coreDataStack = .testValue
    } operation: {
      let repository = PlanRepository.liveValue
      let plan = makePlan()

      try await repository.savePlan(plan)
      let occurrences = try await repository.synchronizeOccurrences(plan, plan.startDate)
      #expect(!occurrences.isEmpty)

      try await repository.deletePlan(plan.id, plan.startDate)

      #expect(try await repository.plan(plan.id) == nil)
      #expect(try await repository.loadOccurrences(plan.id).isEmpty)
    }
  }

  @Test
  func deletingPlanRemovesOnlyItsIncompleteGeneratedActivitiesFromToday() async throws {
    try await withDependencies {
      $0.coreDataStack = .testValue
    } operation: {
      let repository = PlanRepository.liveValue
      let dayActivityRepository = DayActivityRepository.liveValue
      let today = Date(timeIntervalSinceReferenceDate: 800_000_000)
      let yesterday = today.addingTimeInterval(-86_400)
      let tomorrow = today.addingTimeInterval(86_400)
      let plan = makePlan(startDate: yesterday, endDate: tomorrow)
      let otherPlan = makePlan(id: UUID(), startDate: yesterday, endDate: tomorrow)
      let sharedActivityID = UUID()
      let removable = makeDayActivity(date: today)
      let historical = makeDayActivity(date: yesterday)
      let completed = makeDayActivity(date: tomorrow, doneDate: tomorrow)
      let manuallyAdded = makeDayActivity(date: tomorrow, isGeneratedAutomatically: false)
      let shared = makeDayActivity(date: tomorrow)

      try await repository.savePlan(plan)
      try await repository.savePlan(otherPlan)
      for dayActivity in [removable, historical, completed, manuallyAdded, shared] {
        try await dayActivityRepository.saveDayActivity(dayActivity)
      }
      try await repository.saveOccurrences([
        PlanOccurrence(
          planID: plan.id,
          activityID: UUID(),
          date: today,
          dayActivityID: removable.id
        ),
        PlanOccurrence(
          planID: plan.id,
          activityID: UUID(),
          date: yesterday,
          dayActivityID: historical.id
        ),
        PlanOccurrence(
          planID: plan.id,
          activityID: UUID(),
          date: tomorrow,
          dayActivityID: completed.id
        ),
        PlanOccurrence(
          planID: plan.id,
          activityID: UUID(),
          date: tomorrow,
          dayActivityID: manuallyAdded.id
        ),
        PlanOccurrence(
          planID: plan.id,
          activityID: sharedActivityID,
          date: tomorrow,
          dayActivityID: shared.id
        ),
        PlanOccurrence(
          planID: otherPlan.id,
          activityID: sharedActivityID,
          date: tomorrow,
          dayActivityID: shared.id
        )
      ])

      try await repository.deletePlan(plan.id, today)

      let persistedDayActivities = try await dayActivityRepository.dayActivities(
        configuration: ActivitiesFetchConfiguration(
          predicates: [
            NSPredicate(
              format: "identifier IN %@",
              [removable.id, historical.id, completed.id, manuallyAdded.id, shared.id]
            )
          ]
        )
      )
      let persistedDayActivityIDs = Set(persistedDayActivities.map(\.id))

      #expect(!persistedDayActivityIDs.contains(removable.id))
      #expect(persistedDayActivityIDs.contains(historical.id))
      #expect(persistedDayActivityIDs.contains(completed.id))
      #expect(persistedDayActivityIDs.contains(manuallyAdded.id))
      #expect(persistedDayActivityIDs.contains(shared.id))
    }
  }

  private func containsDayActivity(
    _ identifier: UUID,
    in repository: DayActivityRepository
  ) async throws -> Bool {
    try await !repository.dayActivities(
      configuration: ActivitiesFetchConfiguration(
        predicates: [NSPredicate(format: "identifier == %@", identifier as CVarArg)]
      )
    ).isEmpty
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
  func skippingGeneratedActivityDeletesItAndPreservesSkippedOccurrence() async throws {
    try await withDependencies {
      $0.coreDataStack = .testValue
    } operation: {
      let repository = PlanRepository.liveValue
      let dayActivityRepository = DayActivityRepository.liveValue
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
      let monday = try #require(
        calendar.date(from: DateComponents(year: 2026, month: 7, day: 13))
      )
      let activityID = UUID()
      let plan = Plan(
        id: UUID(),
        name: "Monday plan",
        startDate: monday,
        endDate: monday,
        duration: .custom,
        schedule: [
          PlanScheduleEntry(
            id: UUID(),
            weekday: .monday,
            activityID: activityID,
            position: 0
          )
        ]
      )
      let dayActivity = makeDayActivity(date: monday)
      let occurrence = PlanOccurrence(
        planID: plan.id,
        activityID: activityID,
        date: monday,
        dayActivityID: dayActivity.id
      )

      try await repository.savePlan(plan)
      try await dayActivityRepository.saveDayActivity(dayActivity)
      try await repository.saveOccurrences([occurrence])

      #expect(try await repository.skipDayActivity(dayActivity))
      #expect(try await !containsDayActivity(dayActivity.id, in: dayActivityRepository))

      let skippedOccurrence = try #require(
        try await repository.loadOccurrences(plan.id).first
      )
      #expect(skippedOccurrence.dayActivityID == nil)
      #expect(skippedOccurrence.isSkipped)

      let synchronized = try await repository.synchronizeOccurrences(plan, plan.startDate)
      #expect(synchronized.first(where: { $0.id == skippedOccurrence.id }) == skippedOccurrence)
      #expect(synchronized.filter { $0.id == skippedOccurrence.id }.count == 1)
    }
  }

  @Test
  func skippedOccurrenceWinsWhenDuplicatesAreMerged() {
    let planID = UUID()
    let activityID = UUID()
    let date = Date(timeIntervalSinceReferenceDate: 800_000_000)
    let skipped = PlanOccurrence(
      planID: planID,
      activityID: activityID,
      date: date,
      isSkipped: true
    )
    let linked = PlanOccurrence(
      planID: planID,
      activityID: activityID,
      date: date,
      dayActivityID: UUID()
    )

    #expect([skipped, linked].deduplicatedByID() == [skipped])
    #expect([linked, skipped].deduplicatedByID() == [skipped])
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

      #expect(synchronized.count == 2)
      #expect(synchronizedAgain == synchronized)
      #expect(synchronized.contains { $0.date == monday && $0.dayActivityID != nil })
      #expect(synchronized.contains { calendar.component(.weekday, from: $0.date) == 6 && $0.dayActivityID == nil })
      #expect(!synchronized.contains { calendar.component(.weekday, from: $0.date) == 4 })
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

  @Test
  func extendingWeekdayPlanThroughWeekendAddsWeekendOccurrences() async throws {
    try await withDependencies {
      $0.coreDataStack = .testValue
    } operation: {
      let repository = PlanRepository.liveValue
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
      let monday = try #require(
        calendar.date(from: DateComponents(year: 2026, month: 7, day: 13))
      )
      let friday = try #require(calendar.date(byAdding: .day, value: 4, to: monday))
      let saturday = try #require(calendar.date(byAdding: .day, value: 5, to: monday))
      let sunday = try #require(calendar.date(byAdding: .day, value: 6, to: monday))
      let activityID = UUID()
      var plan = Plan(
        id: UUID(),
        name: "Daily plan",
        startDate: monday,
        endDate: friday,
        duration: .custom,
        schedule: PlanWeekday.allCases
          .filter { $0 != .saturday && $0 != .sunday }
          .map {
            PlanScheduleEntry(
              id: UUID(),
              weekday: $0,
              activityID: activityID,
              position: 0
            )
          }
      )

      try await repository.savePlan(plan)
      let weekdayOccurrences = try await repository.synchronizeOccurrences(plan, monday)
      #expect(weekdayOccurrences.count == 5)

      plan.endDate = sunday
      plan.duration = .sevenDays
      plan.schedule.append(
        PlanScheduleEntry(
          id: UUID(),
          weekday: .saturday,
          activityID: activityID,
          position: 0
        )
      )
      plan.schedule.append(
        PlanScheduleEntry(
          id: UUID(),
          weekday: .sunday,
          activityID: activityID,
          position: 0
        )
      )

      try await repository.savePlan(plan)
      let extendedOccurrences = try await repository.synchronizeOccurrences(plan, saturday)

      #expect(extendedOccurrences.count == 7)
      #expect(extendedOccurrences.contains { $0.date == saturday })
      #expect(extendedOccurrences.contains { $0.date == sunday })
      #expect(try await repository.loadOccurrences(plan.id) == extendedOccurrences)
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

  private func makeDayActivity(
    date: Date,
    doneDate: Date? = nil,
    isGeneratedAutomatically: Bool = true
  ) -> DayActivity {
    DayActivity(
      id: UUID(),
      date: date,
      name: "Plan activity",
      doneDate: doneDate,
      isGeneratedAutomatically: isGeneratedAutomatically
    )
  }
}
