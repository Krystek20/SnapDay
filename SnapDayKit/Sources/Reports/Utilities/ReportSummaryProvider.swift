import Foundation
import Models

struct ReportSummaryProvider {

  // MARK: - Public

  func prepareSummary(
    days: [Day],
    selectedActivity: Activity?,
    selectedTag: Tag?,
    today: Date
  ) -> ReportSummary {
    days.reduce(ReportSummary.zero, { result, day in
      if let selectedActivity {
        updatedReportSummary(
          result,
          for: selectedActivity,
          day: day,
          today: today
        )
      } else {
        updatedReportSummary(
          result,
          for: selectedTag,
          day: day,
          today: today
        )
      }
    })
  }

  // MARK: - Private

  private func updatedReportSummary(
    _ reportSummary: ReportSummary,
    for selectedActivity: Activity,
    day: Day,
    today: Date
  ) -> ReportSummary {
    let activities = day.activities.filter { $0.activity == selectedActivity }
    let activitiesDone = activities.filter { $0.isDone }
    let notDoneCount = day.date < today
    ? activities.count - activitiesDone.count
    : .zero
    return ReportSummary(
      doneCount: reportSummary.doneCount + activitiesDone.count,
      notDoneCount: reportSummary.notDoneCount + notDoneCount,
      duration: reportSummary.duration + activitiesDone.reduce(Int.zero) { $0 + $1.duration }
    )
  }

  private func updatedReportSummary(
    _ reportSummary: ReportSummary,
    for selectedTag: Tag?,
    day: Day,
    today: Date
  ) -> ReportSummary {
    let activities = day.activities.filter { $0.activity.tags.contains { $0 == selectedTag } }
    let activitiesDone = activities.filter { $0.isDone }
    let notDoneCount = day.date < today
    ? activities.count - activitiesDone.count
    : .zero
    return ReportSummary(
      doneCount: reportSummary.doneCount + activitiesDone.count,
      notDoneCount: reportSummary.notDoneCount + notDoneCount,
      duration: reportSummary.duration + activitiesDone.reduce(Int.zero) { $0 + $1.duration }
    )
  }
}