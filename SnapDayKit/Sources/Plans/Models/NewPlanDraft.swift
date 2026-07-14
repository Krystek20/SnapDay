import Foundation
import Models

public struct NewPlanDraft: Equatable {
  let name: String
  let startDate: Date
  let endDate: Date
  let schedule: [ScheduledPlanDay]

  var uniqueActivities: [Activity] {
    var seen = Set<Activity.ID>()
    return schedule.flatMap(\.activities).filter { seen.insert($0.id).inserted }
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
