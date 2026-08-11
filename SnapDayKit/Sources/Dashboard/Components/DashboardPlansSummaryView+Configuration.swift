import Foundation

extension DashboardPlansSummaryView.Configuration {
  init(
    summary: DashboardPlanSummary,
    calendar: Calendar,
    locale: Locale
  ) {
    self.init(
      title: summary.title,
      subtitle: String(
        localized: "\(summary.progress.completedPlannedActivityCount) of \(summary.progress.totalPlannedActivityCount) planned activities complete",
        bundle: .module,
        locale: locale
      ),
      progress: DashboardPlansSummaryView.Progress(
        value: summary.progress.fractionComplete,
        title: "\(summary.progress.percentComplete)%"
      ),
      metadata: summary.nextSessionDate.map {
        DashboardPlansSummaryView.Metadata(
          leadingText: Self.nextSessionText(
            for: $0,
            relativeTo: summary.referenceDate,
            calendar: calendar,
            locale: locale
          )
        )
      }
    )
  }

  private static func nextSessionText(
    for date: Date,
    relativeTo referenceDate: Date,
    calendar: Calendar,
    locale: Locale
  ) -> String {
    let session: String
    if calendar.isDate(date, inSameDayAs: referenceDate) {
      session = String(localized: "Today", bundle: .module, locale: locale)
    } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate),
              calendar.isDate(date, inSameDayAs: tomorrow) {
      session = String(localized: "Tomorrow", bundle: .module, locale: locale)
    } else {
      let formatter = DateFormatter()
      formatter.calendar = calendar
      formatter.locale = locale
      formatter.setLocalizedDateFormatFromTemplate("EEEE")
      session = formatter.string(from: date)
    }
    return String(localized: "Next session: \(session)", bundle: .module, locale: locale)
  }
}
