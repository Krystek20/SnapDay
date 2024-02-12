import Foundation
import Models

struct TimePeriodActivitySectionProvider {

  func timePeriodActivitiesSections(for timePeriod: TimePeriod) -> [TimePeriodActivitySection] {
    timePeriod.days
      .reduce(into: [TimePeriodActivity](), reduceIntoTimePeriodActivity)
      .sorted(by: { $0.activity.name < $1.activity.name })
      .reduce(into: [TimePeriodActivitySection](), reduceIntoTimePeriodActivitySections)
      .sorted(by: { $0.tag.name < $1.tag.name })
  }

  private func reduceIntoTimePeriodActivity(_ result: inout [TimePeriodActivity], day: Day) {
    day.activities.forEach { dayActivity in
      if let index = result.firstIndex(where: { $0.activity.id == dayActivity.activity.id }) {
        let timePeriodActivity = result[index]
        result[index] = timePeriodActivity.increasedCount(
          dayActivity.isDone,
          duration: dayActivity.duration
        )
      } else {
        result.append(
          TimePeriodActivity(
            activity: dayActivity.activity,
            totalCount: 1,
            doneCount: dayActivity.isDone ? 1 : .zero,
            duration: dayActivity.isDone ? dayActivity.duration : .zero
          )
        )
      }
    }
  }

  private func reduceIntoTimePeriodActivitySections(_ result: inout [TimePeriodActivitySection], timePeriodActivity: TimePeriodActivity) {
    timePeriodActivity.activity.tags.forEach { tag in
      if let index = result.firstIndex(where: { $0.tag == tag }) {
        result[index].timePeriodActivities.append(timePeriodActivity)
      } else {
        result.append(
          TimePeriodActivitySection(
            tag: tag,
            timePeriodActivities: [timePeriodActivity]
          )
        )
      }
    }
  }
}
