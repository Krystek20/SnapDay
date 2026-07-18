import Foundation
import Models

public struct NewPlanDraft: Equatable {
  let name: String
  let duration: PlanDuration
  let startDate: Date
  let endDate: Date
  let schedule: [ScheduledPlanDay]

  var uniqueActivities: [Activity] {
    var seen = Set<Activity.ID>()
    return schedule.flatMap(\.activities).filter { seen.insert($0.id).inserted }
  }

  func plan(
    id: Plan.ID,
    scheduleEntryID: () -> PlanScheduleEntry.ID
  ) -> Plan {
    Plan(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      duration: duration,
      schedule: schedule.flatMap { day in
        day.activities.enumerated().map { position, activity in
          PlanScheduleEntry(
            id: scheduleEntryID(),
            weekday: day.weekday,
            activityID: activity.id,
            position: position
          )
        }
      }
    )
  }

  func updating(
    _ plan: Plan,
    scheduleEntryID: () -> PlanScheduleEntry.ID
  ) -> Plan {
    var updatedPlan = plan
    updatedPlan.name = name
    updatedPlan.startDate = startDate
    updatedPlan.endDate = endDate
    updatedPlan.duration = duration
    updatedPlan.schedule = schedule.flatMap { day in
      day.activities.enumerated().map { position, activity in
        let existingID = plan.schedule.first {
          $0.weekday == day.weekday && $0.activityID == activity.id
        }?.id
        return PlanScheduleEntry(
          id: existingID ?? scheduleEntryID(),
          weekday: day.weekday,
          activityID: activity.id,
          position: position
        )
      }
    }
    return updatedPlan
  }

  func plannedActivityCount(calendar: Calendar = .autoupdatingCurrent) -> Int {
    let activitiesByWeekday = Dictionary(uniqueKeysWithValues: schedule.map { ($0.weekday, $0.activities.count) })
    let end = calendar.startOfDay(for: endDate)
    var date = calendar.startOfDay(for: startDate)
    var count = 0

    while date <= end {
      if let weekday = PlanWeekday(rawValue: calendar.component(.weekday, from: date)) {
        count += activitiesByWeekday[weekday, default: 0]
      }
      guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
      date = nextDate
    }
    return count
  }
}
