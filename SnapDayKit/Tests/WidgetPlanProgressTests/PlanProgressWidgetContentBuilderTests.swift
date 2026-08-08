import Foundation
import Models
import Testing
import Utilities
@testable import WidgetPlanProgress

struct PlanProgressWidgetContentBuilderTests {

  private let builder = PlanProgressWidgetContentBuilder()

  @Test
  func noActivePlansProducesEmptyState() throws {
    let calendar = testCalendar
    let today = try date(year: 2026, month: 8, day: 6, calendar: calendar)

    let content = builder.content(from: [], referenceDate: today, calendar: calendar)

    #expect(content.state == .noActivePlan)
    #expect(content.planID == nil)
  }

  @Test
  func incompleteActivitiesTodayProduceDueStateAndWholePlanProgress() throws {
    let calendar = testCalendar
    let today = try date(year: 2026, month: 8, day: 6, calendar: calendar)
    let tomorrow = try #require(calendar.date(byAdding: .day, value: 1, to: today))
    let plan = makePlan(name: "Spanish", start: today, end: tomorrow)
    let completedID = UUID()
    let occurrences = [
      PlanOccurrence(
        planID: plan.id,
        activityID: UUID(),
        date: today,
        dayActivityID: completedID
      ),
      PlanOccurrence(planID: plan.id, activityID: UUID(), date: today),
      PlanOccurrence(planID: plan.id, activityID: UUID(), date: tomorrow)
    ]
    let completedActivity = DayActivity(
      id: completedID,
      date: today,
      doneDate: today,
      isGeneratedAutomatically: true
    )

    let content = builder.content(
      from: [PlanProgressSnapshot(
        plan: plan,
        occurrences: occurrences,
        dayActivities: [completedActivity]
      )],
      referenceDate: today,
      calendar: calendar
    )

    #expect(content.state == .partlyDoneToday)
    #expect(content.completedTodayCount == 1)
    #expect(content.totalTodayCount == 2)
    #expect(content.completedActivityCount == 1)
    #expect(content.totalActivityCount == 3)
    #expect(content.percentComplete == 33)
    #expect(content.nextSessionDate == today)
  }

  @Test
  func completedTodayUsesNextIncompleteFutureSession() throws {
    let calendar = testCalendar
    let today = try date(year: 2026, month: 8, day: 6, calendar: calendar)
    let tomorrow = try #require(calendar.date(byAdding: .day, value: 1, to: today))
    let plan = makePlan(name: "Spanish", start: today, end: tomorrow)
    let completedID = UUID()

    let content = builder.content(
      from: [PlanProgressSnapshot(
        plan: plan,
        occurrences: [
          PlanOccurrence(
            planID: plan.id,
            activityID: UUID(),
            date: today,
            dayActivityID: completedID
          ),
          PlanOccurrence(planID: plan.id, activityID: UUID(), date: tomorrow)
        ],
        dayActivities: [
          DayActivity(
            id: completedID,
            date: today,
            doneDate: today,
            isGeneratedAutomatically: true
          )
        ]
      )],
      referenceDate: today,
      calendar: calendar
    )

    #expect(content.state == .todayComplete)
    #expect(content.nextSessionDate == tomorrow)
  }

  @Test
  func planDueTodayWinsOverPlanWithOnlyUpcomingActivities() throws {
    let calendar = testCalendar
    let today = try date(year: 2026, month: 8, day: 6, calendar: calendar)
    let tomorrow = try #require(calendar.date(byAdding: .day, value: 1, to: today))
    let duePlan = makePlan(name: "Due", start: today, end: tomorrow)
    let upcomingPlan = makePlan(name: "Upcoming", start: today, end: tomorrow)

    let content = builder.content(
      from: [
        PlanProgressSnapshot(
          plan: upcomingPlan,
          occurrences: [PlanOccurrence(
            planID: upcomingPlan.id,
            activityID: UUID(),
            date: tomorrow
          )],
          dayActivities: []
        ),
        PlanProgressSnapshot(
          plan: duePlan,
          occurrences: [PlanOccurrence(
            planID: duePlan.id,
            activityID: UUID(),
            date: today
          )],
          dayActivities: []
        )
      ],
      referenceDate: today,
      calendar: calendar
    )

    #expect(content.planID == duePlan.id)
    #expect(content.state == .dueToday)
  }

  @Test
  func activePlanWithoutActivitiesTodayShowsUpcomingState() throws {
    let calendar = testCalendar
    let today = try date(year: 2026, month: 8, day: 6, calendar: calendar)
    let saturday = try #require(calendar.date(byAdding: .day, value: 2, to: today))
    let plan = makePlan(name: "Weekend", start: today, end: saturday)

    let content = builder.content(
      from: [PlanProgressSnapshot(
        plan: plan,
        occurrences: [PlanOccurrence(
          planID: plan.id,
          activityID: UUID(),
          date: saturday
        )],
        dayActivities: []
      )],
      referenceDate: today,
      calendar: calendar
    )

    #expect(content.state == .noActivitiesToday)
    #expect(content.nextSessionDate == saturday)
  }

  private var testCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
  }

  private func date(
    year: Int,
    month: Int,
    day: Int,
    calendar: Calendar
  ) throws -> Date {
    try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
  }

  private func makePlan(name: String, start: Date, end: Date) -> Plan {
    Plan(
      id: UUID(),
      name: name,
      startDate: start,
      endDate: end,
      duration: .custom,
      schedule: []
    )
  }
}
