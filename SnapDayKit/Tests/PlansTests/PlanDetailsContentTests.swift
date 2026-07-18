import Foundation
import Models
import Testing
@testable import Plans

@Suite
struct PlanDetailsContentTests {

  @Test
  func todayActivityUsesLinkedDayActivityCompletion() throws {
    let calendar = try calendar()
    let today = try date(day: 15, calendar: calendar)
    let activity = Activity(id: UUID(), name: "Read")
    let dayActivityID = UUID()
    let plan = Plan(
      id: UUID(),
      name: "Learn Spanish",
      startDate: try date(day: 1, calendar: calendar),
      endDate: try date(day: 31, calendar: calendar),
      duration: .custom,
      schedule: [
        PlanScheduleEntry(
          id: UUID(),
          weekday: .wednesday,
          activityID: activity.id,
          position: 0
        )
      ]
    )
    let occurrence = PlanOccurrence(
      planID: plan.id,
      activityID: activity.id,
      date: today,
      dayActivityID: dayActivityID
    )
    let dayActivity = DayActivity(
      id: dayActivityID,
      date: today,
      activity: activity,
      name: activity.name,
      doneDate: today,
      duration: 0,
      isGeneratedAutomatically: true
    )

    let content = PlanDetailsContent(
      plan: plan,
      activities: [activity],
      occurrences: [occurrence],
      dayActivities: [dayActivity],
      referenceDate: today,
      calendar: calendar
    )

    #expect(content.completedTodayCount == 1)
    #expect(content.progress.percentComplete == 100)
    #expect(content.scheduledDays.first?.state == .done)
  }

  @Test
  func duplicateLinkedDayActivitiesDoNotCrashDetails() throws {
    let calendar = try calendar()
    let today = try date(day: 18, calendar: calendar)
    let activity = Activity(id: UUID(), name: "Read")
    let dayActivityID = UUID()
    let plan = Plan(
      id: UUID(),
      name: "Weekend plan",
      startDate: today,
      endDate: try date(day: 19, calendar: calendar),
      duration: .custom,
      schedule: [
        PlanScheduleEntry(
          id: UUID(),
          weekday: .saturday,
          activityID: activity.id,
          position: 0
        )
      ]
    )
    let occurrence = PlanOccurrence(
      planID: plan.id,
      activityID: activity.id,
      date: today,
      dayActivityID: dayActivityID
    )
    let completedActivity = DayActivity(
      id: dayActivityID,
      date: today,
      activity: activity,
      name: activity.name,
      doneDate: today,
      duration: 0,
      isGeneratedAutomatically: true
    )
    let pendingActivity = DayActivity(
      id: dayActivityID,
      date: today,
      activity: activity,
      name: activity.name,
      duration: 0,
      isGeneratedAutomatically: true
    )

    let content = PlanDetailsContent(
      plan: plan,
      activities: [activity, activity],
      occurrences: [occurrence],
      dayActivities: [completedActivity, pendingActivity],
      referenceDate: today,
      calendar: calendar
    )

    #expect(content.todayActivities == [
      PlanDetailsContent.ActivityItem(id: activity.id, name: activity.name, isDone: true)
    ])
  }

  @Test
  func restDayFindsNextScheduledDay() throws {
    let calendar = try calendar()
    let wednesday = try date(day: 15, calendar: calendar)
    let activity = Activity(id: UUID(), name: "Walk")
    let plan = Plan(
      id: UUID(),
      name: "Move more",
      startDate: try date(day: 1, calendar: calendar),
      endDate: try date(day: 31, calendar: calendar),
      duration: .custom,
      schedule: [
        PlanScheduleEntry(
          id: UUID(),
          weekday: .friday,
          activityID: activity.id,
          position: 0
        )
      ]
    )

    let content = PlanDetailsContent(
      plan: plan,
      activities: [activity],
      occurrences: [],
      dayActivities: [],
      referenceDate: wednesday,
      calendar: calendar
    )

    #expect(content.todayActivities.isEmpty)
    #expect(content.nextPlannedDay?.id == .friday)
    #expect(content.nextPlannedDay?.activities.map(\.name) == ["Walk"])
  }

  @Test
  func scheduledDayBeforePlanStartHasNoState() throws {
    let calendar = try calendar()
    let monday = try date(day: 13, calendar: calendar)
    let saturday = try date(day: 18, calendar: calendar)
    let activity = Activity(id: UUID(), name: "Walk")
    let plan = Plan(
      id: UUID(),
      name: "Weekend plan",
      startDate: saturday,
      endDate: try date(day: 31, calendar: calendar),
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
    let content = PlanDetailsContent(
      plan: plan,
      activities: [activity],
      occurrences: [],
      dayActivities: [],
      referenceDate: saturday,
      calendar: calendar
    )

    #expect(calendar.component(.weekday, from: monday) == PlanWeekday.monday.rawValue)
    #expect(content.scheduledDays.first?.state == nil)
  }

  private func calendar() throws -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    calendar.locale = Locale(identifier: "en_US")
    calendar.firstWeekday = 2
    return calendar
  }

  private func date(day: Int, calendar: Calendar) throws -> Date {
    try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: day, hour: 12)))
  }
}
