import Foundation
import Models

struct PlanDayActivityMatch: Equatable {
  let activity: Activity
  let occurrences: [PlanOccurrence]
  let dayActivityID: DayActivity.ID?

  func linkedOccurrences(to dayActivityID: DayActivity.ID) -> [PlanOccurrence] {
    occurrences.map { occurrence in
      var occurrence = occurrence
      occurrence.dayActivityID = dayActivityID
      return occurrence
    }
  }
}

enum PlanDayActivityResolver {
  static func matches(
    on date: Date,
    occurrences: [PlanOccurrence],
    activities: [Activity],
    dayActivities: [DayActivity],
    calendar: Calendar
  ) -> [PlanDayActivityMatch] {
    let date = calendar.startOfDay(for: date)
    let activitiesByID = PlanActivityResolver.activitiesByID(activities)
    let occurrencesByActivityID = Dictionary(
      grouping: occurrences.filter {
        !$0.isSkipped && calendar.isDate($0.date, inSameDayAs: date)
      },
      by: \.activityID
    )

    return occurrencesByActivityID.compactMap { activityID, occurrences in
      guard let activity = activitiesByID[activityID] else { return nil }
      let dayActivityID = dayActivities.first { $0.activity?.id == activityID }?.id
      return PlanDayActivityMatch(
        activity: activity,
        occurrences: occurrences,
        dayActivityID: dayActivityID
      )
    }
    .sorted { $0.activity.name < $1.activity.name }
  }
}
