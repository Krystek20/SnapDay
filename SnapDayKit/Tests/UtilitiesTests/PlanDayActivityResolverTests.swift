import Foundation
import Models
import Testing
@testable import Utilities

struct PlanDayActivityResolverTests {
  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
    return calendar
  }()

  @Test
  func frequencyOnlyDoesNotAddAnotherActivity() throws {
    let date = try testDate()
    let activity = Activity(id: UUID(), name: "Read")
    let frequencyActivity = DayActivity(
      id: UUID(),
      date: date,
      activity: activity,
      isGeneratedAutomatically: true
    )

    let matches = PlanDayActivityResolver.matches(
      on: date,
      occurrences: [],
      activities: [activity],
      dayActivities: [frequencyActivity],
      calendar: calendar
    )

    #expect(matches.isEmpty)
  }

  @Test
  func planScheduleRequestsMissingDailyActivity() throws {
    let date = try testDate()
    let activity = Activity(id: UUID(), name: "Read")
    let occurrence = PlanOccurrence(planID: UUID(), activityID: activity.id, date: date)

    let match = try #require(
      PlanDayActivityResolver.matches(
        on: date,
        occurrences: [occurrence],
        activities: [activity],
        dayActivities: [],
        calendar: calendar
      ).first
    )

    #expect(match.activity == activity)
    #expect(match.dayActivityID == nil)
    #expect(match.occurrences == [occurrence])
  }

  @Test
  func skippedOccurrenceDoesNotRequestDailyActivity() throws {
    let date = try testDate()
    let activity = Activity(id: UUID(), name: "Read")
    let occurrence = PlanOccurrence(
      planID: UUID(),
      activityID: activity.id,
      date: date,
      isSkipped: true
    )

    let matches = PlanDayActivityResolver.matches(
      on: date,
      occurrences: [occurrence],
      activities: [activity],
      dayActivities: [],
      calendar: calendar
    )

    #expect(matches.isEmpty)
  }

  @Test
  func frequencyAndPlanOverlapReuseDailyActivity() throws {
    let date = try testDate()
    let activity = Activity(id: UUID(), name: "Read")
    let dayActivity = DayActivity(
      id: UUID(),
      date: date,
      activity: activity,
      isGeneratedAutomatically: true
    )
    let occurrence = PlanOccurrence(planID: UUID(), activityID: activity.id, date: date)

    let match = try #require(
      PlanDayActivityResolver.matches(
        on: date,
        occurrences: [occurrence],
        activities: [activity],
        dayActivities: [dayActivity],
        calendar: calendar
      ).first
    )

    #expect(match.dayActivityID == dayActivity.id)
    #expect(match.linkedOccurrences(to: dayActivity.id).first?.dayActivityID == dayActivity.id)
  }

  @Test
  func multiplePlansShareOneDailyActivity() throws {
    let date = try testDate()
    let activity = Activity(id: UUID(), name: "Read")
    let occurrences = [
      PlanOccurrence(planID: UUID(), activityID: activity.id, date: date),
      PlanOccurrence(planID: UUID(), activityID: activity.id, date: date)
    ]

    let matches = PlanDayActivityResolver.matches(
      on: date,
      occurrences: occurrences,
      activities: [activity],
      dayActivities: [],
      calendar: calendar
    )

    #expect(matches.count == 1)
    #expect(matches.first?.occurrences.count == 2)
  }

  @Test
  func duplicateActivityIdentifiersUseLatestValueWithoutCrashing() throws {
    let date = try testDate()
    let activityID = UUID()
    let occurrence = PlanOccurrence(planID: UUID(), activityID: activityID, date: date)

    let match = try #require(
      PlanDayActivityResolver.matches(
        on: date,
        occurrences: [occurrence],
        activities: [
          Activity(id: activityID, name: "Old name"),
          Activity(id: activityID, name: "Current name")
        ],
        dayActivities: [],
        calendar: calendar
      ).first
    )

    #expect(match.activity.name == "Current name")
  }

  private func testDate() throws -> Date {
    try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 13)))
  }
}
