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

  @Test
  func historySeparatesDonePartialMissedAndRemainingDays() throws {
    let calendar = try calendar()
    let activity = Activity(id: UUID(), name: "Read")
    let secondActivity = Activity(id: UUID(), name: "Walk")
    let plan = Plan(
      id: UUID(),
      name: "History",
      startDate: try date(day: 13, calendar: calendar),
      endDate: try date(day: 16, calendar: calendar),
      duration: .custom,
      schedule: []
    )
    let dates = try (13...16).map { try date(day: $0, calendar: calendar) }
    let doneID = UUID()
    let partialID = UUID()
    let occurrences = [
      PlanOccurrence(planID: plan.id, activityID: activity.id, date: dates[0], dayActivityID: doneID),
      PlanOccurrence(planID: plan.id, activityID: activity.id, date: dates[1], dayActivityID: partialID),
      PlanOccurrence(planID: plan.id, activityID: secondActivity.id, date: dates[1]),
      PlanOccurrence(planID: plan.id, activityID: activity.id, date: dates[2]),
      PlanOccurrence(planID: plan.id, activityID: activity.id, date: dates[3])
    ]
    let dayActivities = [
      DayActivity(
        id: doneID,
        date: dates[0],
        activity: activity,
        name: activity.name,
        doneDate: dates[0],
        duration: 600,
        isGeneratedAutomatically: true
      ),
      DayActivity(
        id: partialID,
        date: dates[1],
        activity: activity,
        name: activity.name,
        doneDate: dates[1],
        duration: 300,
        isGeneratedAutomatically: true
      )
    ]
    let content = PlanDetailsContent(
      plan: plan,
      activities: [activity, secondActivity],
      occurrences: occurrences,
      dayActivities: dayActivities,
      referenceDate: dates[3],
      calendar: calendar
    )

    #expect(content.historySummary.completedDays == 1)
    #expect(content.historySummary.partialDays == 1)
    #expect(content.historySummary.missedDays == 1)
    #expect(content.historySummary.remainingDays == 1)
    #expect(content.historySummary.completedTime == 900)
    #expect(content.historyMonths.count == 1)
    #expect(content.historyMonths[0].days.map(\.state) == [.done, .partial, .missed, .future])
  }

  @Test
  func resultProgressUsesPlannedActivitiesRatherThanCompletedDays() throws {
    let calendar = try calendar()
    let firstDate = try date(day: 13, calendar: calendar)
    let secondDate = try date(day: 14, calendar: calendar)
    let activities = [
      Activity(id: UUID(), name: "Read"),
      Activity(id: UUID(), name: "Walk"),
      Activity(id: UUID(), name: "Journal"),
      Activity(id: UUID(), name: "Stretch")
    ]
    let completedDayActivityIDs = activities.prefix(3).map { _ in UUID() }
    let plan = Plan(
      id: UUID(),
      name: "Consistency",
      startDate: firstDate,
      endDate: secondDate,
      duration: .custom,
      schedule: []
    )
    let occurrences = activities.enumerated().map { index, activity in
      PlanOccurrence(
        planID: plan.id,
        activityID: activity.id,
        date: index < 3 ? firstDate : secondDate,
        dayActivityID: index < 3 ? completedDayActivityIDs[index] : nil
      )
    }
    let dayActivities = zip(activities.prefix(3), completedDayActivityIDs).map { activity, id in
      DayActivity(
        id: id,
        date: firstDate,
        activity: activity,
        name: activity.name,
        doneDate: firstDate,
        duration: 0,
        isGeneratedAutomatically: true
      )
    }
    let content = PlanDetailsContent(
      plan: plan,
      activities: activities,
      occurrences: occurrences,
      dayActivities: dayActivities,
      referenceDate: try date(day: 15, calendar: calendar),
      calendar: calendar
    )

    #expect(content.progress.completedPlannedActivityCount == 3)
    #expect(content.progress.totalPlannedActivityCount == 4)
    #expect(content.progress.percentComplete == 75)
    #expect(content.historySummary.completedDays == 1)
    #expect(content.historySummary.missedDays == 1)
  }

  @Test
  func resultDeduplicatesOccurrencesAndUsesCurrentActivityDetails() throws {
    let calendar = try calendar()
    let plannedDate = try date(day: 13, calendar: calendar)
    let readID = UUID()
    let walkID = UUID()
    let completedDayActivityID = UUID()
    let oldRead = Activity(id: readID, name: "Read")
    let currentRead = Activity(id: readID, name: "Read Spanish")
    let walk = Activity(id: walkID, name: "Walk")
    let plan = Plan(
      id: UUID(),
      name: "Consistency",
      startDate: plannedDate,
      endDate: plannedDate,
      duration: .custom,
      schedule: [
        PlanScheduleEntry(id: UUID(), weekday: .monday, activityID: readID, position: 0),
        PlanScheduleEntry(id: UUID(), weekday: .monday, activityID: walkID, position: 1)
      ]
    )
    let occurrences = [
      PlanOccurrence(planID: plan.id, activityID: readID, date: plannedDate),
      PlanOccurrence(
        planID: plan.id,
        activityID: readID,
        date: plannedDate,
        dayActivityID: completedDayActivityID
      ),
      PlanOccurrence(planID: plan.id, activityID: walkID, date: plannedDate)
    ]
    let completedActivity = DayActivity(
      id: completedDayActivityID,
      date: plannedDate,
      activity: oldRead,
      name: oldRead.name,
      doneDate: plannedDate,
      duration: 600,
      isGeneratedAutomatically: true
    )
    let content = PlanDetailsContent(
      plan: plan,
      activities: [oldRead, currentRead, walk],
      occurrences: occurrences,
      dayActivities: [completedActivity],
      referenceDate: try date(day: 14, calendar: calendar),
      calendar: calendar
    )

    #expect(content.progress.completedPlannedActivityCount == 1)
    #expect(content.progress.totalPlannedActivityCount == 2)
    #expect(content.historySummary.partialDays == 1)
    #expect(content.activityBreakdown.map(\.activity.name) == ["Read Spanish", "Walk"])
    #expect(content.activityBreakdown.map(\.completedCount) == [1, 0])
    #expect(content.activityBreakdown.map(\.plannedCount) == [1, 1])
  }

  @Test
  func completedTimeOnlyIncludesDayActivitiesLinkedToThePlan() throws {
    let calendar = try calendar()
    let plannedDate = try date(day: 13, calendar: calendar)
    let activity = Activity(id: UUID(), name: "Read")
    let linkedID = UUID()
    let plan = Plan(
      id: UUID(),
      name: "Reading",
      startDate: plannedDate,
      endDate: plannedDate,
      duration: .custom,
      schedule: []
    )
    let dayActivities = [
      DayActivity(
        id: linkedID,
        date: plannedDate,
        activity: activity,
        name: activity.name,
        doneDate: plannedDate,
        duration: 600,
        isGeneratedAutomatically: true
      ),
      DayActivity(
        id: UUID(),
        date: plannedDate,
        activity: activity,
        name: activity.name,
        doneDate: plannedDate,
        duration: 1_800,
        isGeneratedAutomatically: false
      )
    ]
    let content = PlanDetailsContent(
      plan: plan,
      activities: [activity],
      occurrences: [
        PlanOccurrence(
          planID: plan.id,
          activityID: activity.id,
          date: plannedDate,
          dayActivityID: linkedID
        )
      ],
      dayActivities: dayActivities,
      referenceDate: try date(day: 14, calendar: calendar),
      calendar: calendar
    )

    #expect(content.historySummary.completedTime == 600)
  }

  @Test
  func finishedResultWithoutCompletionsKeepsPlannedActivityBreakdown() throws {
    let calendar = try calendar()
    let plannedDate = try date(day: 13, calendar: calendar)
    let activity = Activity(id: UUID(), name: "Read")
    let plan = Plan(
      id: UUID(),
      name: "Reading",
      startDate: plannedDate,
      endDate: plannedDate,
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
      occurrences: [
        PlanOccurrence(planID: plan.id, activityID: activity.id, date: plannedDate)
      ],
      dayActivities: [],
      referenceDate: try date(day: 14, calendar: calendar),
      calendar: calendar
    )

    #expect(content.status == .finished)
    #expect(content.progress.completedPlannedActivityCount == 0)
    #expect(content.progress.totalPlannedActivityCount == 1)
    #expect(content.historySummary.missedDays == 1)
    #expect(content.historySummary.remainingDays == 0)
    #expect(content.activityBreakdown.first?.completedCount == 0)
    #expect(content.activityBreakdown.first?.plannedCount == 1)
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
