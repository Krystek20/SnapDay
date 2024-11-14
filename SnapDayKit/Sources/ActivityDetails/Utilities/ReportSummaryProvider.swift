import Foundation
import Models

struct ReportSummaryProvider {

  // MARK: - Public

  func prepareSummary(
    days: [Day],
    reportType: ReportType,
    today: Date
  ) -> ReportSummary {
    days.reduce(ReportSummary.zero, { result, day in
      updatedReportSummary(
        result,
        reportType: reportType,
        day: day,
        today: today
      )
    })
  }

  // MARK: - Private

  private func updatedReportSummary(
    _ reportSummary: ReportSummary,
    reportType: ReportType,
    day: Day,
    today: Date
  ) -> ReportSummary {
    let activities = switch reportType {
    case .activity(let activity, _, let activityLabel):
      day.activities.filter {
        $0.activity?.id == activity.id && (activityLabel == nil || $0.labels.contains { $0 == activityLabel })
      }
    case .tag(let tag, _, let activity):
      day.activities.filter {
        $0.activity?.tags.contains(where: { $0 == tag }) == true && (activity == nil || $0.activity?.id == activity?.id)
      }
    }

    let activitiesDone = activities.filter(\.isDone)
    let notDoneCount = day.date < today ? activities.count - activitiesDone.count : .zero
    return ReportSummary(
      doneCount: reportSummary.doneCount + activitiesDone.count,
      notDoneCount: reportSummary.notDoneCount + notDoneCount,
      duration: reportSummary.duration + activitiesDone.reduce(Int.zero) { $0 + $1.duration }
    )
  }
}
