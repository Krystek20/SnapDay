#if DEBUG
import SwiftUI
import WidgetKit

#Preview("No active plans", as: .systemSmall) {
  PreviewPlanProgressWidget()
} timeline: {
  PreviewPlanProgressEntry(content: .noActivePlan(referenceDate: .now))
}

#Preview("Due today", as: .systemSmall) {
  PreviewPlanProgressWidget()
} timeline: {
  PreviewPlanProgressEntry(content: .preview(state: .dueToday, completedToday: 0))
}

#Preview("Partly done", as: .systemSmall) {
  PreviewPlanProgressWidget()
} timeline: {
  PreviewPlanProgressEntry(content: .preview(state: .partlyDoneToday, completedToday: 1))
}

#Preview("Done today", as: .systemSmall) {
  PreviewPlanProgressWidget()
} timeline: {
  PreviewPlanProgressEntry(content: .preview(state: .todayComplete, completedToday: 2))
}

#Preview("Plan complete", as: .systemSmall) {
  PreviewPlanProgressWidget()
} timeline: {
  PreviewPlanProgressEntry(
    content: .preview(
      state: .todayComplete,
      completedToday: 2,
      completedActivityCount: 10
    )
  )
}

#Preview("No activities today", as: .systemSmall) {
  PreviewPlanProgressWidget()
} timeline: {
  PreviewPlanProgressEntry(content: .preview(state: .noActivitiesToday, completedToday: 0))
}

#Preview("Long Plan name", as: .systemSmall) {
  PreviewPlanProgressWidget()
} timeline: {
  PreviewPlanProgressEntry(
    content: .preview(
      state: .todayComplete,
      completedToday: 2,
      planName: "Build a consistent morning routine"
    )
  )
}

private struct PreviewPlanProgressEntry: TimelineEntry {
  let content: PlanProgressWidgetContent
  let date = Date.now
}

private struct PreviewPlanProgressWidget: Widget {
  let kind = "PreviewPlanProgressWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PreviewPlanProgressProvider()) { entry in
      PlanProgressWidgetView(content: entry.content)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .contentMarginsDisabled()
    .supportedFamilies([.systemSmall])
  }
}

private struct PreviewPlanProgressProvider: TimelineProvider {
  func placeholder(in context: Context) -> PreviewPlanProgressEntry {
    PreviewPlanProgressEntry(content: .preview(state: .partlyDoneToday, completedToday: 1))
  }

  func getSnapshot(
    in context: Context,
    completion: @escaping (PreviewPlanProgressEntry) -> Void
  ) {
    completion(placeholder(in: context))
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<PreviewPlanProgressEntry>) -> Void
  ) {
    completion(Timeline(entries: [placeholder(in: context)], policy: .never))
  }
}

private extension PlanProgressWidgetContent {
  static func preview(
    state: State,
    completedToday: Int,
    completedActivityCount: Int? = nil,
    planName: String = "Learn Spanish"
  ) -> Self {
    let referenceDate = Date.now
    return Self(
      state: state,
      planID: UUID(),
      planName: planName,
      completedActivityCount: completedActivityCount ?? (state == .todayComplete ? 4 : 3),
      totalActivityCount: 10,
      completedTodayCount: completedToday,
      totalTodayCount: state == .noActivitiesToday ? 0 : 2,
      nextSessionDate: Calendar.current.date(byAdding: .day, value: 2, to: referenceDate),
      referenceDate: referenceDate
    )
  }
}
#endif
