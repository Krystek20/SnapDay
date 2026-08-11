import Foundation
import Testing
@testable import Models

struct PlanModelTests {

  @Test
  func presetDurationsHaveInclusiveEndDates() throws {
    let calendar = testCalendar()
    let startDate = try date(year: 2026, month: 6, day: 8, calendar: calendar)
    let expectations: [(PlanDuration, Date)] = [
      (.sevenDays, try date(year: 2026, month: 6, day: 14, calendar: calendar)),
      (.twoWeeks, try date(year: 2026, month: 6, day: 21, calendar: calendar)),
      (.oneMonth, try date(year: 2026, month: 7, day: 7, calendar: calendar)),
      (.threeMonths, try date(year: 2026, month: 9, day: 7, calendar: calendar)),
      (.sixMonths, try date(year: 2026, month: 12, day: 7, calendar: calendar)),
      (.oneYear, try date(year: 2027, month: 6, day: 7, calendar: calendar))
    ]

    for (duration, expectedEndDate) in expectations {
      #expect(duration.endDate(from: startDate, calendar: calendar) == expectedEndDate)
    }
  }

  @Test
  func occurrencesIncludeDifferentActivitiesForEachWeekday() throws {
    let calendar = testCalendar()
    let startDate = try date(year: 2026, month: 6, day: 8, calendar: calendar)
    let endDate = try date(year: 2026, month: 6, day: 14, calendar: calendar)
    let mondayFirstActivity = scheduleEntry(weekday: .monday, position: 0)
    let mondaySecondActivity = scheduleEntry(weekday: .monday, position: 1)
    let fridayActivity = scheduleEntry(weekday: .friday, position: 0)
    let plan = plan(
      startDate: startDate,
      endDate: endDate,
      schedule: [
        mondayFirstActivity,
        mondaySecondActivity,
        fridayActivity
      ]
    )

    let occurrences = plan.scheduledOccurrences(calendar: calendar)

    #expect(occurrences.count == 3)
    #expect(
      occurrences.map(\.activityID)
        == [mondayFirstActivity.activityID, mondaySecondActivity.activityID, fridayActivity.activityID]
    )
    #expect(occurrences.allSatisfy { $0.planID == plan.id })
  }

  @Test
  func occurrencesUseInclusiveBoundsAndCanGenerateOnlyFutureRange() throws {
    let calendar = testCalendar()
    let monday = try date(year: 2026, month: 6, day: 8, calendar: calendar)
    let nextMonday = try date(year: 2026, month: 6, day: 15, calendar: calendar)
    let plan = plan(
      startDate: monday,
      endDate: nextMonday,
      schedule: [scheduleEntry(weekday: .monday, position: 0)]
    )

    let allOccurrences = plan.scheduledOccurrences(calendar: calendar)
    let futureOccurrences = plan.scheduledOccurrences(
      from: nextMonday,
      through: nextMonday,
      calendar: calendar
    )

    #expect(allOccurrences.map(\.date) == [monday, nextMonday])
    #expect(futureOccurrences.map(\.date) == [nextMonday])
  }

  @Test
  func occurrenceIdentityIsStableAndUsesNormalizedCalendarDate() throws {
    let calendar = testCalendar()
    let startDate = try date(
      year: 2026,
      month: 6,
      day: 8,
      hour: 15,
      calendar: calendar
    )
    let normalizedDate = calendar.startOfDay(for: startDate)
    let entry = scheduleEntry(weekday: .monday, position: 0)
    let plan = plan(startDate: startDate, endDate: startDate, schedule: [entry])

    let firstOccurrence = try #require(plan.scheduledOccurrences(calendar: calendar).first)
    let regeneratedOccurrence = try #require(plan.scheduledOccurrences(calendar: calendar).first)

    #expect(firstOccurrence.date == normalizedDate)
    #expect(firstOccurrence.id == regeneratedOccurrence.id)
    #expect(firstOccurrence.id.planID == plan.id)
    #expect(firstOccurrence.id.activityID == entry.activityID)
  }

  @Test
  func duplicateActivityOnSameDayCreatesOneOccurrence() throws {
    let calendar = testCalendar()
    let monday = try date(year: 2026, month: 6, day: 8, calendar: calendar)
    let activityID = UUID()
    let plan = plan(
      startDate: monday,
      endDate: monday,
      schedule: [
        scheduleEntry(weekday: .monday, activityID: activityID, position: 0),
        scheduleEntry(weekday: .monday, activityID: activityID, position: 1)
      ]
    )

    #expect(plan.scheduledOccurrences(calendar: calendar).count == 1)
  }

  @Test
  func progressCountsCompletedActivityOccurrencesAcrossWholePlan() throws {
    let calendar = testCalendar()
    let monday = try date(year: 2026, month: 6, day: 8, calendar: calendar)
    let plan = plan(
      startDate: monday,
      endDate: monday,
      schedule: (1...10).map {
        scheduleEntry(weekday: .monday, position: $0)
      }
    )
    let generatedOccurrences = plan.scheduledOccurrences(calendar: calendar)
    let firstOccurrence = try #require(generatedOccurrences.first)
    let completedDayActivityID = UUID()
    let occurrences = generatedOccurrences.map { occurrence in
      var occurrence = occurrence
      if occurrence.id == firstOccurrence.id {
        occurrence.dayActivityID = completedDayActivityID
      }
      return occurrence
    }
    let completedDayActivity = dayActivity(
      id: completedDayActivityID,
      date: monday,
      doneDate: monday
    )

    let progress = plan.progress(
      from: occurrences,
      dayActivities: [completedDayActivity]
    )

    #expect(progress.completedPlannedActivityCount == 1)
    #expect(progress.totalPlannedActivityCount == 10)
    #expect(progress.fractionComplete == 0.1)
    #expect(progress.percentComplete == 10)
  }

  @Test
  func progressDeduplicatesOccurrencesRegeneratedFromWednesday() throws {
    let calendar = testCalendar()
    let monday = try date(year: 2026, month: 7, day: 20, calendar: calendar)
    let activityID = UUID()
    let plan = plan(
      startDate: monday,
      endDate: try #require(calendar.date(byAdding: .day, value: 6, to: monday)),
      schedule: PlanWeekday.ordered(using: calendar).map {
        scheduleEntry(weekday: $0, activityID: activityID, position: 0)
      }
    )
    var originalOccurrences = plan.scheduledOccurrences(calendar: calendar)
    let completedDayActivityIDs = [UUID(), UUID(), UUID()]
    for index in completedDayActivityIDs.indices {
      originalOccurrences[index].dayActivityID = completedDayActivityIDs[index]
    }
    let wednesday = originalOccurrences[2].date
    let regeneratedOccurrences = originalOccurrences
      .filter { $0.date >= wednesday }
    let dayActivities = zip(completedDayActivityIDs, originalOccurrences.prefix(3)).map {
      dayActivity(id: $0.0, date: $0.1.date, doneDate: $0.1.date)
    }

    let duplicatedProgress = PlanProgress(
      occurrences: originalOccurrences + regeneratedOccurrences,
      dayActivities: dayActivities
    )
    #expect(duplicatedProgress.completedPlannedActivityCount == 4)
    #expect(duplicatedProgress.totalPlannedActivityCount == 12)

    let progress = plan.progress(
      from: originalOccurrences + regeneratedOccurrences,
      dayActivities: dayActivities
    )

    #expect(progress.completedPlannedActivityCount == 3)
    #expect(progress.totalPlannedActivityCount == 7)
  }

  @Test
  func progressIgnoresOccurrencesFromOtherPlans() throws {
    let calendar = testCalendar()
    let monday = try date(year: 2026, month: 6, day: 8, calendar: calendar)
    let plan = plan(
      startDate: monday,
      endDate: monday,
      schedule: [scheduleEntry(weekday: .monday, position: 0)]
    )
    let otherPlan = Plan(
      id: UUID(),
      name: "Other",
      startDate: monday,
      endDate: monday,
      duration: .custom,
      schedule: [scheduleEntry(weekday: .monday, position: 0)]
    )
    let occurrences = plan.scheduledOccurrences(calendar: calendar)
      + otherPlan.scheduledOccurrences(calendar: calendar)

    #expect(
      plan.progress(from: occurrences, dayActivities: []).totalPlannedActivityCount == 1
    )
  }

  @Test
  func progressRoundsPercentageToWholeNumber() throws {
    let calendar = testCalendar()
    let monday = try date(year: 2026, month: 6, day: 8, calendar: calendar)
    let plan = plan(
      startDate: monday,
      endDate: monday,
      schedule: (0..<6).map {
        scheduleEntry(weekday: .monday, position: $0)
      }
    )
    var occurrences = plan.scheduledOccurrences(calendar: calendar)
    let completedDayActivityID = UUID()
    occurrences[0].dayActivityID = completedDayActivityID

    let progress = plan.progress(
      from: occurrences,
      dayActivities: [dayActivity(id: completedDayActivityID, date: monday, doneDate: monday)]
    )

    #expect(progress.percentComplete == 17)
  }

  @Test
  func progressKeepsHistoricalOccurrencesAfterScheduleChanges() throws {
    let calendar = testCalendar()
    let monday = try date(year: 2026, month: 6, day: 8, calendar: calendar)
    var plan = plan(
      startDate: monday,
      endDate: monday,
      schedule: [scheduleEntry(weekday: .monday, position: 0)]
    )
    let generatedOccurrences = plan.scheduledOccurrences(calendar: calendar)
    let firstOccurrence = try #require(generatedOccurrences.first)
    let completedDayActivityID = UUID()
    let historicalOccurrences = generatedOccurrences.map { occurrence in
      var occurrence = occurrence
      if occurrence.id == firstOccurrence.id {
        occurrence.dayActivityID = completedDayActivityID
      }
      return occurrence
    }
    let completedDayActivity = dayActivity(
      id: completedDayActivityID,
      date: monday,
      doneDate: monday
    )

    plan.schedule = []
    #expect(plan.scheduledOccurrences(calendar: calendar).isEmpty)
    let progress = plan.progress(
      from: historicalOccurrences,
      dayActivities: [completedDayActivity]
    )

    #expect(progress.completedPlannedActivityCount == 1)
    #expect(progress.totalPlannedActivityCount == 1)
  }

  @Test
  func activePlanFinishesAfterInclusiveEndDate() throws {
    let calendar = testCalendar()
    let endDate = try date(year: 2026, month: 6, day: 8, calendar: calendar)
    let nextDate = try date(year: 2026, month: 6, day: 9, calendar: calendar)
    var plan = plan(startDate: endDate, endDate: endDate, schedule: [])

    #expect(plan.status(on: endDate, calendar: calendar) == .active)
    #expect(plan.status(on: nextDate, calendar: calendar) == .finished)

    plan.isArchived = true
    #expect(plan.status(on: nextDate, calendar: calendar) == .archived)
  }
}

private extension PlanModelTests {
  func plan(
    startDate: Date,
    endDate: Date,
    schedule: [PlanScheduleEntry]
  ) -> Plan {
    Plan(
      id: UUID(),
      name: "Learn Spanish",
      startDate: startDate,
      endDate: endDate,
      duration: .custom,
      schedule: schedule
    )
  }

  func scheduleEntry(
    weekday: PlanWeekday,
    activityID: Activity.ID = UUID(),
    position: Int
  ) -> PlanScheduleEntry {
    PlanScheduleEntry(
      id: UUID(),
      weekday: weekday,
      activityID: activityID,
      position: position
    )
  }

  func dayActivity(
    id: DayActivity.ID,
    date: Date,
    doneDate: Date?
  ) -> DayActivity {
    DayActivity(
      id: id,
      date: date,
      doneDate: doneDate,
      isGeneratedAutomatically: true
    )
  }

  func date(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    calendar: Calendar
  ) throws -> Date {
    try #require(
      calendar.date(
        from: DateComponents(year: year, month: month, day: day, hour: hour)
      )
    )
  }

  func testCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .autoupdatingCurrent
    calendar.firstWeekday = 2
    return calendar
  }
}
