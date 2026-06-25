#if DEBUG
import SwiftUI

#Preview("Plans summary - active due today") {
  DashboardPlansSectionView(
    configurations: [.activePlanDueTodayPreview],
    planAction: {},
    allPlansAction: {}
  )
  .padding(15.0)
}

#Preview("Plans summary - active carousel") {
  DashboardPlansSectionView(
    configurations: DashboardPlansSummaryView.Configuration.activePlanCarouselPreviews,
    planAction: {},
    allPlansAction: {}
  )
  .padding(15.0)
}

#Preview("Plans summary - no active Plan") {
  DashboardPlansSectionView(
    configurations: [.noActivePlanPreview],
    allPlansAction: {}
  )
  .padding(15.0)
}

private extension DashboardPlansSummaryView.Configuration {
  static let activePlanDueTodayPreview = DashboardPlansSummaryView.Configuration(
    title: "Learn Spanish",
    subtitle: "1 of 10 planned activities complete",
    progress: DashboardPlansSummaryView.Progress(value: 0.1, title: "10%"),
    metadata: DashboardPlansSummaryView.Metadata(
      leadingText: "Next session: Friday"
    )
  )

  static let noActivePlanPreview = DashboardPlansSummaryView.Configuration(
    title: "No active Plan",
    subtitle: "Recurring routines will appear here when scheduled."
  )

  static let activePlanCarouselPreviews = [
    DashboardPlansSummaryView.Configuration(
      title: "Learn Spanish",
      subtitle: "1 of 10 planned activities complete",
      progress: DashboardPlansSummaryView.Progress(value: 0.1, title: "10%"),
      metadata: DashboardPlansSummaryView.Metadata(
        leadingText: "Next session: Friday"
      )
    ),
    DashboardPlansSummaryView.Configuration(
      title: "Strength Training",
      subtitle: "4 of 20 planned activities complete",
      progress: DashboardPlansSummaryView.Progress(value: 0.2, title: "20%"),
      metadata: DashboardPlansSummaryView.Metadata(
        leadingText: "Next session: Tomorrow"
      )
    ),
    DashboardPlansSummaryView.Configuration(
      title: "Guitar Practice",
      subtitle: "6 of 12 planned activities complete",
      progress: DashboardPlansSummaryView.Progress(value: 0.5, title: "50%"),
      metadata: DashboardPlansSummaryView.Metadata(
        leadingText: "Next session: Saturday"
      )
    )
  ]
}
#endif
