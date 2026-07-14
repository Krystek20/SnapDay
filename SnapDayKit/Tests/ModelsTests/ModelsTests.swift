import Foundation
import Testing
@testable import Models

struct PlanModelTests {

  @Test
  func presetDurationsHaveInclusiveEndDates() throws {
    let calendar = testCalendar()
    let startDate = try date(year: 2026, month: 6, day: 8, calendar: calendar)
    let sevenDayEndDate = try date(year: 2026, month: 6, day: 14, calendar: calendar)
    let twoWeekEndDate = try date(year: 2026, month: 6, day: 21, calendar: calendar)
    let oneMonthEndDate = try date(year: 2026, month: 7, day: 7, calendar: calendar)

    #expect(
      PlanDuration.sevenDays.endDate(from: startDate, calendar: calendar)
        == sevenDayEndDate
    )
    #expect(
      PlanDuration.twoWeeks.endDate(from: startDate, calendar: calendar)
        == twoWeekEndDate
    )
    #expect(
      PlanDuration.oneMonth.endDate(from: startDate, calendar: calendar)
        == oneMonthEndDate
    )
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

    plan.schedule = [scheduleEntry(weekday: .monday, position: 0)]
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
    calendar: Calendar
  ) throws -> Date {
    try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
  }

  func testCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .autoupdatingCurrent
    calendar.firstWeekday = 2
    return calendar
  }
}
